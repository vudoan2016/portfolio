import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'push_notification.dart';
import 'process.dart';

const pageTitles = ['Summary', 'Investment', 'Retirement'];

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

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
    PushNotificationsManager().init();
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
          appBar: AppBar(
            centerTitle: true,
            title: new Text(
              pageTitles[_index],
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                ),
                onPressed: () {},
              )
            ],
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
                  );
                }
                // By default, show a loading spinner.
                return CircularProgressIndicator();
              })),
    );
  }
}

class SummaryPage extends StatefulWidget {
  final List<Asset> data;

  SummaryPage({Key key, @required this.data}) : super(key: key);

  @override
  SummaryPageState createState() => SummaryPageState();
}

class SummaryPageState extends State<SummaryPage> {
  bool _showTotal = false;
  Profile allAssets;

  Column header(total) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          IconButton(
            icon: _showTotal
                ? Icon(Icons.visibility)
                : Icon(Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showTotal = !_showTotal;
              });
            },
          ),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(total),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    allAssets = Profile(<String>{'taxed', 'deferred'}, widget.data);
    return Center(
        child: Container(
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          header(allAssets.total),
          Center(
              child: Text('Top Gainers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: createDataTable(allAssets.winners)),
          Padding(padding: EdgeInsets.all(20.00)),
          Center(
              child: Text('Top Losers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: createDataTable(allAssets.losers)),
        ],
      ),
      alignment: Alignment(-1.0, -1.0),
    ));
  }
}

class InvestmentPage extends StatefulWidget {
  final List<Asset> data;

  InvestmentPage({Key key, @required this.data}) : super(key: key);

  @override
  InvestmentPageState createState() => InvestmentPageState();
}

class InvestmentPageState extends State<InvestmentPage> {
  bool _showTotal = false;
  Profile investment;

  Column header(total, gain, percent, ltGain, stGain) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          IconButton(
            icon: _showTotal
                ? Icon(Icons.visibility)
                : Icon(Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showTotal = !_showTotal;
              });
            },
          ),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(total),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Visibility(
              visible: _showTotal,
              child: Text('+' + f.format(gain) + '(' + f.format(percent) + '%)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(ltGain) + '(L), ' + f.format(stGain) + '(S)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    investment = Profile(<String>{'taxed'}, widget.data);
    return Center(
      child: Container(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            header(investment.total, investment.gain, investment.gainPercent,
                investment.ltGain, investment.stGain),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: createDataTable(investment.rows)),
          ],
        ),
      ),
    );
  }
}

class RetirementPage extends StatefulWidget {
  final List<Asset> data;

  RetirementPage({Key key, @required this.data}) : super(key: key);

  RetirementPageState createState() => RetirementPageState();
}

class RetirementPageState extends State<RetirementPage> {
  bool _showTotal = false;
  Profile retirement;

  Column header(total, gain, percent, ltGain, stGain) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          IconButton(
            icon: _showTotal
                ? Icon(Icons.visibility)
                : Icon(Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showTotal = !_showTotal;
              });
            },
          ),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(total),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Visibility(
              visible: _showTotal,
              child: Text('+' + f.format(gain) + '(' + f.format(percent) + '%)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(ltGain) + '(L), ' + f.format(stGain) + '(S)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    retirement = Profile(<String>{'deferred'}, widget.data);
    return Center(
        child: Container(
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          header(retirement.total, retirement.gain, retirement.gainPercent,
              retirement.ltGain, retirement.stGain),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: createDataTable(retirement.rows)),
        ],
      ),
    ));
  }
}

DataTable createDataTable(rows) {
  return DataTable(
    columns: const <DataColumn>[
      DataColumn(
        label: Text(
          'Symbol',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          'Price',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
        label: Text(
          '\u0394(%)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      DataColumn(
          label: Text(
        'Gain',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      )),
    ],
    rows: rows,
  );
}
