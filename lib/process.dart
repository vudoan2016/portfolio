import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

const SELECTION_MAX = 5;

var f = new NumberFormat("#,###.0#", "en_US");

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
    return "Asset name: $symbol, price: $price, today gain: $todayGain, "
        "type: $type, value: $value, gain: $gain, cost: $cost";
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

Future<List<Asset>> fetchAsset() async {
  final response =
  await http.get('http://192.168.0.15:8080/', headers: {"Accept": "application/json"});

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    var list = json.decode(response.body) as List;
    List<Asset> assets = list.map((e) => Asset.fromJson(e)).toList();
    return assets;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to fetch asset');
  }
}

class Profile {
  double total = 0;
  double gain = 0;
  double gainPercent = 0;
  List<DataRow> rows;
  List<DataRow> winners;
  List<DataRow> losers;

  Profile(Set<String> types, List<Asset> assets) {
    int count = 0;
    double cost = 0;
    rows = List<DataRow>();
    winners = List<DataRow>();
    losers = List<DataRow>();

    Comparator<Asset> todayGainCmp = (a, b) => b.todayGain.compareTo(a.todayGain);
    assets.sort(todayGainCmp);

    assets.forEach((e) {
      if (types.contains(e.type)) {
        this.total += e.value;
        this.gain += e.gain;
        cost += e.cost;
        rows.add(createDataRow(e));

        // select top winners as well
        if (e.todayGain > 0 && count < SELECTION_MAX) {
          winners.add(createDataRow(e));
          count++;
        }
      }
      this.gainPercent = this.gain / cost * 100;
    });

    // Select today top losers
    count = 0;
    todayGainCmp = (a, b) => a.todayGain.compareTo(b.todayGain);
    assets.sort(todayGainCmp);
    assets.forEach ((e) {
      if (types.contains(e.type) && e.todayGain < 0 && count < SELECTION_MAX) {
        losers.add(createDataRow(e));
        count++;
      }
    });
  }

  DataRow createDataRow(asset) {
    var color = asset.todayGain >= 0 ? Colors.green : Colors.red;
    return DataRow(
      cells: <DataCell>[DataCell(Text(asset.symbol, style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(asset.price.toStringAsFixed(2), style: TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(asset.todayGain.toStringAsFixed(2), style: TextStyle(color: color, fontWeight: FontWeight.bold)),),
        DataCell(Text(f.format(asset.gain), style: TextStyle(fontWeight: FontWeight.bold),)),
      ],
    );
  }
}
