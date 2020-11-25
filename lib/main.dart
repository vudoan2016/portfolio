import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'push_notification.dart';
import 'process.dart';

const pageTitles = ['Summary', 'Investment', 'Retirement'];
enum Performer { winner, loser }

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
  bool _sorted = true;
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
              child: createDataTable(Performer.winner)),
          Padding(padding: EdgeInsets.all(20.00)),
          Center(
              child: Text('Top Losers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: createDataTable(Performer.loser)),
        ],
      ),
      alignment: Alignment(-1.0, -1.0),
    ));
  }

  DataTable createDataTable([Performer p]) {
    return DataTable(
      sortAscending: _sorted,
      sortColumnIndex: 2,
      columns: <DataColumn>[
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
          ),
        ),
      ],
      rows: (p == Performer.winner ? allAssets.winners : allAssets.losers)
          .map((a) => DataRow(
                cells: <DataCell>[
                  DataCell(Text(a.symbol,
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(a.price.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Text(a.todayGain.toStringAsFixed(2),
                        style: TextStyle(
                            color: a.todayGain >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                  DataCell(Text(
                    f.format(a.gain),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              ))
          .toList(),
    );
  }
}

class InvestmentPage extends StatefulWidget {
  final List<Asset> data;

  InvestmentPage({Key key, @required this.data}) : super(key: key);

  @override
  InvestmentPageState createState() => InvestmentPageState();
}

class InvestmentPageState extends State<InvestmentPage> {
  bool _showTotal;
  bool _sorted;
  Profile investment;

  @override
  void initState() {
    _showTotal = false;
    _sorted = true;
    investment = Profile(<String>{'taxed'}, widget.data);
    super.initState();
  }

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
              child: Text(f.format(gain) + '(' + f.format(percent) + '%)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(ltGain) + '(L), ' + f.format(stGain) + '(S)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            header(investment.total, investment.gain, investment.gainPercent,
                investment.ltGain, investment.stGain),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: createDataTable()),
          ],
        ),
      ),
    );
  }

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 2) {
      if (ascending) {
        investment.assets.sort((a, b) => a.todayGain.compareTo(b.todayGain));
      } else {
        investment.assets.sort((a, b) => b.todayGain.compareTo(a.todayGain));
      }
    } else if (columnIndex == 3) {
      if (ascending) {
        investment.assets.sort((a, b) => a.gain.compareTo(b.gain));
      } else {
        investment.assets.sort((a, b) => b.gain.compareTo(a.gain));
      }
    }
  }

  DataTable createDataTable() {
    return DataTable(
      sortAscending: _sorted,
      sortColumnIndex: 2,
      columns: <DataColumn>[
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
          numeric: false,
          onSort: (columnIndex, ascending) {
            setState(() {
              _sorted = !_sorted;
            });
            onSortColum(columnIndex, ascending);
          },
          label: Text(
            '\u0394(%)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          numeric: false,
          onSort: (columnIndex, ascending) {
            setState(() {
              _sorted = !_sorted;
            });
            onSortColum(columnIndex, ascending);
          },
          label: Text(
            'Gain',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: investment.assets
          .map((a) => DataRow(
                cells: <DataCell>[
                  DataCell(Text(a.symbol,
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(a.price.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Text(a.todayGain.toStringAsFixed(2),
                        style: TextStyle(
                            color: a.todayGain >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                  DataCell(Text(
                    f.format(a.gain),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              ))
          .toList(),
    );
  }
}

class RetirementPage extends StatefulWidget {
  final List<Asset> data;

  RetirementPage({Key key, @required this.data}) : super(key: key);

  RetirementPageState createState() => RetirementPageState();
}

class RetirementPageState extends State<RetirementPage> {
  bool _showTotal;
  bool _sorted;
  Profile retirement;

  @override
  void initState() {
    _showTotal = false;
    _sorted = true;
    retirement = Profile(<String>{'deferred'}, widget.data);
    super.initState();
  }

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
              child: Text(f.format(gain) + '(' + f.format(percent) + '%)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Visibility(
              visible: _showTotal,
              child: Text(f.format(ltGain) + '(L), ' + f.format(stGain) + '(S)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          header(retirement.total, retirement.gain, retirement.gainPercent,
              retirement.ltGain, retirement.stGain),
          SingleChildScrollView(
              scrollDirection: Axis.vertical, child: createDataTable()),
        ],
      ),
    ));
  }

  onSortColum(int columnIndex, bool ascending) {
    if (columnIndex == 2) {
      if (ascending) {
        retirement.assets.sort((a, b) => a.todayGain.compareTo(b.todayGain));
      } else {
        retirement.assets.sort((a, b) => b.todayGain.compareTo(a.todayGain));
      }
    } else if (columnIndex == 3) {
      if (ascending) {
        retirement.assets.sort((a, b) => a.gain.compareTo(b.gain));
      } else {
        retirement.assets.sort((a, b) => b.gain.compareTo(a.gain));
      }
    }
  }

  DataTable createDataTable() {
    return DataTable(
      sortAscending: _sorted,
      sortColumnIndex: 2,
      columns: <DataColumn>[
        DataColumn(
          onSort: (columnIndex, ascending) {
            setState(() {
              _sorted = !_sorted;
            });
            onSortColum(columnIndex, ascending);
          },
          label: Text(
            'Symbol',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          onSort: (columnIndex, ascending) {
            onSortColum(columnIndex, ascending);
          },
          label: Text(
            'Price',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          numeric: false,
          onSort: (columnIndex, ascending) {
            setState(() {
              _sorted = !_sorted;
            });
            onSortColum(columnIndex, ascending);
          },
          label: Text(
            '\u0394(%)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        DataColumn(
          numeric: false,
          onSort: (columnIndex, ascending) {
            setState(() {
              _sorted = !_sorted;
            });
            onSortColum(columnIndex, ascending);
          },
          label: Text(
            'Gain',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
      rows: retirement.assets
          .map((a) => DataRow(
                cells: <DataCell>[
                  DataCell(Text(a.symbol,
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(a.price.toStringAsFixed(2),
                      style: TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Text(a.todayGain.toStringAsFixed(2),
                        style: TextStyle(
                            color: a.todayGain >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                  DataCell(Text(
                    f.format(a.gain),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
                ],
              ))
          .toList(),
    );
  }
}
