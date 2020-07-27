import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import "package:intl/intl.dart";

Future<List<Asset>> fetchAsset() async {
  final response =
  await http.get('http://192.168.0.15:8080/', headers: {"Accept": "application/json"});

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    // return Asset.fromJson(json.decode(response.body));
    var list = json.decode(response.body) as List;
    List<Asset> assets = list.map((e) => Asset.fromJson(e)).toList();
    return assets;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to fetch asset');
  }
}

class Asset {
  final String symbol;
  final String type;
  final double price;
  final double todayGain;
  final double value;
  final double gain;
  final double cost;
  Asset({this.symbol, this.price, this.todayGain, this.type, this.value, this.gain, this.cost});

  String toString() {
    return "Asset name: ${symbol}, price: ${price}, today gain: ${todayGain}, "
        "type: ${type}, value: ${value}, gain: ${gain}, cost: ${cost}";
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      symbol: json['Symbol'].toUpperCase(),
      price: json['RegularMarketPrice'].toDouble(),
      todayGain: json['RegularMarketChangePercent'].toDouble(),
      type: json['type'],
      value: json['Value'].toDouble(),
      gain: json['Gain'].toDouble(),
      cost: json['Cost'].toDouble(),
    );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

const pageTitles = ['Summary', 'Investment', 'Retirement'];
const WINNER = 1;
const LOSER = 2;
const ALL = 3;
const SELECTION_MAX = 5;

class _MyAppState extends State<MyApp> {
  Future<List<Asset>> futureAsset;
  int _index = 0;

  PageController _controller = PageController(
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    futureAsset = fetchAsset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePageChange(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Allocation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(centerTitle: true, title: new Text(pageTitles[_index],),
          actions: <Widget>[
          IconButton(icon: Icon(Icons.settings, color: Colors.white,),
            onPressed: () {},
          )],
        ),
        body: FutureBuilder<List<Asset>>(
          future: futureAsset,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return PageView(
                controller: _controller,
                children: [
                  SummaryPage(data: snapshot.data),
                  InvestmentPage(data: snapshot.data),
                  RetirementPage(data: snapshot.data),
                ],
                onPageChanged: _handlePageChange,
              );}
            // By default, show a loading spinner.
            return CircularProgressIndicator();
          })
      ),
    );
  }
}

class SummaryPage extends StatelessWidget {
  final List<Asset> data;

  SummaryPage({Key key, @required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Summary winnerSummary = select(data, WINNER, "", SELECTION_MAX);
    Summary loserSummary = select(data, LOSER, "", SELECTION_MAX);
    var f = new NumberFormat("#,###.0#", "en_US");
    return Center(
      child: Container(
        child: ListView(scrollDirection: Axis.vertical, children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[Text(f.format(winnerSummary.total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),],),
          Padding(padding: EdgeInsets.all(20.00)),
          Center(child: Text('Top Gainers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: createDataTable(winnerSummary.rows)),
          Padding(padding: EdgeInsets.all(20.00)),
          Center(child: Text('Top Losers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: createDataTable(loserSummary.rows)),
        ],),
      alignment: Alignment(-1.0, -1.0),
      )
    );
  }
}

class InvestmentPage extends StatelessWidget {
  final List<Asset> data;

  InvestmentPage({Key key, @required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Summary investment = select(data, ALL, "taxed", 0);
    var f = new NumberFormat("#,###.0#", "en_US");
    return Center(
      child: Container(
        child: ListView(scrollDirection: Axis.vertical, children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[Text(f.format(investment.total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),],),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Gain'), Text(f.format(investment.gain)+'('+f.format(investment.gainPercent)+'%)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),],),
          Padding(padding: EdgeInsets.all(20.00)),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: createDataTable(investment.rows)),
        ],),
        alignment: Alignment(-1.0, -1.0),
      ),
    );
  }
}

class RetirementPage extends StatelessWidget {
  final List<Asset> data;

  RetirementPage({Key key, @required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Summary retirement = select(data, ALL, "deferred", 0);
    var f = new NumberFormat("#,###.0#", "en_US");
    return Center(
      child: Container(
        child: ListView(scrollDirection: Axis.vertical, children: <Widget>[
          Row(mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[Text(f.format(retirement.total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),],),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Gain'), Text(f.format(retirement.gain)+'('+f.format(retirement.gainPercent)+'%)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),],),
          Padding(padding: EdgeInsets.all(20.00)),
          SingleChildScrollView(scrollDirection: Axis.vertical, child: createDataTable(retirement.rows)),
        ],),
        alignment: Alignment(-1.0, -1.0),
      )
    );
  }
}

DataRow createDataRow(asset) {
  var color = asset.todayGain >= 0 ? Colors.green : Colors.red;
  return DataRow(
    cells: <DataCell>[DataCell(Text(asset.symbol, style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(asset.price.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(asset.todayGain.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.bold)),),],
  );
}

class Summary {
  double total;
  double gain;
  double gainPercent;
  List<DataRow> rows;
  Summary({this.total, this.gain, this.gainPercent, this.rows});
}
Summary select(assets, performer, type, max) {
  // assets can have the same symbol so assetMap is used to eliminate duplicates
  var assetMap = new Map();
  var l = List<DataRow>();
  var count = 0;
  double total = 0;
  double gain = 0;
  double cost = 0;
  Iterable it = performer == WINNER || performer == ALL ? assets : assets.reversed;
  for (var e in it) {
    if (performer != ALL) {
      if (performer == WINNER && e.todayGain >= 0 ||
          performer == LOSER && e.todayGain <= 0 || count < max &&
          !assetMap.containsKey(e.symbol) &&
          (e.type == "taxed" || e.type == "deferred")) {
        l.add(createDataRow(e));
        assetMap[e.symbol] = true;
        count++;
      }
      total += e.value;
    } else {
      if (e.type == type) {
        total += e.value;
        gain += e.gain;
        cost += e.cost;
        if (e.symbol != 'ETRADE' && e.symbol != 'FIDELITY' &&
            e.symbol != 'PAYFLEX' && e.symbol != 'MERRILL' &&
            e.symbol != 'VANGUARD') {
          l.add(createDataRow(e));
        }
      }
    }
  }
  // To generate a list of all DataRow:
  // List.generate(snapshot.data.length, (index) => _createDataRow(snapshot.data[index])),
  return Summary(total: total, gain: gain, gainPercent: gain/cost*100, rows: l);
}

DataTable createDataTable(rows) {
  return DataTable(
    columns: const <DataColumn>[
      DataColumn(label: Text('Symbol', style: TextStyle(fontSize: 15,
          fontWeight: FontWeight.bold),),),
      DataColumn(label: Text('Price', style: TextStyle(fontSize: 15,
          fontWeight: FontWeight.bold),),),
      DataColumn(label: Text('\u0394(%)', style: TextStyle(fontSize: 15,
          fontWeight: FontWeight.bold),),),
    ],
    rows: rows,
  );
}
