import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
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
    assets.forEach((element) => print(element));
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

  Asset({this.symbol, this.price, this.gain});

  String toString() {
    return "Asset name: ${symbol}, price: ${price}, gain: ${gain}";
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      symbol: json['symbol'],
      price: json['RegularMarketPrice'].toDouble(),
      gain: json['RegularMarketChangePercent'].toDouble(),
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
          title: Text('Highlight'),
        ),
        body: Center(
          child: FutureBuilder<List<Asset>>(
            future: futureAsset,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                DataRow _getDataRow(asset) {
                  return DataRow(
                    cells: <DataCell>[DataCell(Text(asset.symbol)), DataCell(Text(asset.price.toStringAsFixed(2))), DataCell(Text(asset.gain.toStringAsFixed(2))),],
                  );
                }
                return DataTable(
                    columns: const <DataColumn>[
                      DataColumn(label: Text('Symbol', style: TextStyle(fontWeight: FontWeight.bold),),),
                      DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold),),),
                      DataColumn(label: Text('Gain', style: TextStyle(fontWeight: FontWeight.bold),),),
                    ],
                    rows:  List.generate(snapshot.data.length, (index) => _getDataRow(snapshot.data[index])),
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