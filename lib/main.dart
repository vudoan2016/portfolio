import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;

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
  final double price;
  final double gain;
  final String type;

  Asset({this.symbol, this.price, this.gain, this.type});

  String toString() {
    return "Asset name: ${symbol}, price: ${price}, gain: ${gain}, type: ${type}";
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      symbol: json['symbol'].toUpperCase(),
      price: json['RegularMarketPrice'].toDouble(),
      gain: json['RegularMarketChangePercent'].toDouble(),
      type: json['type'],
    );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<List<Asset>> futureAsset;
  final selectionMax = 5;
  final winner = 1;
  final loser = 2;

  @override
  void initState() {
    super.initState();
    futureAsset = fetchAsset();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asset Allocation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Highlight'),
        ),
        body: Center(
          child: FutureBuilder<List<Asset>>(
            future: futureAsset,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                DataRow _createDataRow(asset, performer) {
                  var color = performer == winner ? Colors.green : Colors.red;
                  return DataRow(
                    cells: <DataCell>[DataCell(Text(asset.symbol)),
                      DataCell(Text(asset.price.toStringAsFixed(2))),
                      DataCell(Text(asset.gain.toStringAsFixed(2), style: TextStyle(color: color),),),],
                  );
                }
                List<DataRow> _select(data, performer) {
                  // assets can have the same symbol so assetMap is used to eliminate duplicates
                  var assetMap = new Map();
                  var l = List<DataRow>();
                  var count = 0;
                  Iterable it = performer == winner ? data : data.reversed;
                  for (var e in it) {
                    if (performer == winner && e.gain <= 0 || performer == loser && e.gain >= 0 || count == selectionMax) {
                      break;
                    } else if (!assetMap.containsKey(e.symbol) && (e.type == "taxed" || e.type == "deferred")) {
                      l.add(_createDataRow(e, performer));
                      assetMap[e.symbol] = true;
                      count++;
                    }
                  }
                  // List.generate(snapshot.data.length, (index) => _createDataRow(snapshot.data[index])),
                  return l;
                }
                DataTable _createDataTable(data, performer) {
                  return DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Symbol', style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold),),),
                      DataColumn(label: Text('Price', style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold),),),
                      DataColumn(label: Text('\u0394(%)', style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold),),),
                    ],
                    rows: _select(data, performer),
                  );
                }
                return Container(
                  child: ListView(scrollDirection: Axis.vertical, children: <Widget>[
                    Center(child: Text('Top Gainers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    SingleChildScrollView(scrollDirection: Axis.vertical, child: _createDataTable(snapshot.data, winner)),
                    Padding(padding: EdgeInsets.all(20.00)),
                    Center(child: Text('Top Losers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    SingleChildScrollView(scrollDirection: Axis.vertical, child: _createDataTable(snapshot.data, loser)),
                  ],),
                  alignment: Alignment(-1.0, -1.0),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }

              // By default, show a loading spinner.
              return CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}