import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

const SELECTION_MAX = 5;
const DAYS_PER_YEAR = 365;

var f = new NumberFormat("#,###.0#", "en_US");

class Asset {
  final String symbol;
  final String type;
  final double price;
  final double todayGain;
  final double value;
  final double gain;
  final double cost;
  final DateTime buyDate;

  Asset(
      {this.symbol,
      this.price,
      this.todayGain,
      this.type,
      this.value,
      this.gain,
      this.cost,
      this.buyDate});

  String toString() {
    return "Asset name: $symbol, price: $price, today gain: $todayGain, "
        "type: $type, value: $value, gain: $gain, cost: $cost, buy date: $buyDate";
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
      buyDate: DateTime.parse(
        json['buydate'],
      ),
    );
  }
}

Future<List<Asset>> fetchAsset() async {
  final response = await http.get('http://192.168.0.17:8080/',
      headers: {"Accept": "application/json"});

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
  double ltGain = 0;
  double stGain = 0;
  List<Asset> assets;
  List<Asset> winners;
  List<Asset> losers;

  Profile(Set<String> types, List<Asset> data) {
    int count = 0;
    double cost = 0;
    assets = List<Asset>();
    winners = List<Asset>();
    losers = List<Asset>();
    var today = new DateTime.now();

    Comparator<Asset> todayGainCmp =
        (a, b) => b.todayGain.compareTo(a.todayGain);
    data.sort(todayGainCmp);

    data.forEach((e) {
      if (types.contains(e.type)) {
        this.total += e.value;
        this.gain += e.gain;
        cost += e.cost;
        if (e.symbol != "ETRADE" &&
            e.symbol != "MERRILL" &&
            e.symbol != "VANGUARD" &&
            e.symbol != "PAYFLEX" &&
            e.symbol != "FIDELITY") {
          assets.add(e);
        }
        if (today.difference(e.buyDate).inDays > DAYS_PER_YEAR) {
          this.ltGain += e.gain;
        } else {
          this.stGain += e.gain;
        }
        // select top winners as well
        if (e.todayGain > 0 && count < SELECTION_MAX) {
          winners.add(e);
          count++;
        }
      }
      this.gainPercent = this.gain / cost * 100;
    });

    // Select today top losers
    count = 0;
    todayGainCmp = (a, b) => a.todayGain.compareTo(b.todayGain);
    data.sort(todayGainCmp);
    data.forEach((e) {
      if (types.contains(e.type) && e.todayGain < 0 && count < SELECTION_MAX) {
        losers.add(e);
        count++;
      }
    });
  }
}
