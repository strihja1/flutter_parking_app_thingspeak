import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'model/sensorData.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Stav parkovacího místa'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}



class _MyHomePageState extends State<MyHomePage> {
  StreamController _postsController;
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  double sensorValue;
  bool isFree;
  int count = 1;
  DateTime date = DateTime.now();
  SensorData sensorData;
  Timer timer;

  Future fetchPost() async {
    final response = await http.get(
        'https://api.thingspeak.com/channels/1275616/fields/1.json?results=1');

    if (response.statusCode == 200) {
      sensorData = SensorData.fromJson(json.decode(response.body));
      return (sensorData.feeds.last.date);
    } else {
      throw Exception('Failed to load post');
    }
  }



  loadPosts() async {
    fetchPost().then((res) async {
      _postsController.add(res);
      return res;
    });
  }

  Future<Null> _handleRefresh() async {
    count++;
    fetchPost().then((res) async {
      _postsController.add(res);
      return null;
    });
  }

  @override
  void initState() {
    _postsController = new StreamController();
    loadPosts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(timer != null){
      timer.cancel();
    }
    timer = Timer.periodic(const Duration(seconds:10), (Timer t) => _handleRefresh());
    DateTime dateSince = DateTime.now();
    String lastUpdate;
    return Scaffold(
      key: scaffoldKey,
      body: StreamBuilder(
              stream: _postsController.stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(snapshot.error);
                }
                if(snapshot.hasData && !snapshot.hasError) {
                  sensorValue = num.tryParse(sensorData.feeds.last.sensorValue)?.toDouble();
                  isFree = sensorValue == 1 ? true : false;
                  dateSince = (DateTime.parse(sensorData.feeds.last.date));
                    lastUpdate = dateTimeFormatToString(DateTime.now());
                  return Container(
                    color: isFree == null ? Colors.yellow : isFree
                        ? Colors.green
                        : Colors.red,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text(
                            'Stav parkovacího místa',
                            style: TextStyle(fontSize: 20),
                          ), Text(
                            isFree == null ? "Neznámý" : isFree
                                ? "Volno"
                                : "Obsazeno",
                            style: TextStyle(fontSize: 40),
                            textAlign: TextAlign.center,

                          ), Text(
                            dateSince == null ? "" : 'Od: ${dateTimeFormatToString(
                                dateSince)}',
                            style: TextStyle(fontSize: 40,),
                            textAlign: TextAlign.center,
                          ), Text(
                              'Poslední aktualizace: $lastUpdate',
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center
                          ),
                          RaisedButton(color: Colors.black,
                              padding: EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 30),

                              child: Text("Aktualizovat",
                                  style: TextStyle(fontSize: 18, color: Colors
                                      .white)),
                              onPressed: () {
                            setState(() {
                              _handleRefresh();
                            });
                              })
                        ],
                      ),
                    ),
                  );
                }

                else{
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("Načítám data ze serveru", style: TextStyle(fontSize: 20),),
                      CircularProgressIndicator(),
                      Center(child: RaisedButton(color: Colors.black,
                          padding: EdgeInsets.symmetric(
                              vertical: 16, horizontal: 30),

                          child: Text("Aktualizovat",
                              style: TextStyle(fontSize: 18, color: Colors
                                  .white)),
                          onPressed: () {
                            setState(() {
                              _handleRefresh();
                            });
                          })),
                    ],
                  );
                }
              }
          )
    );
  }

  String dateTimeFormatToString(DateTime dateTime) =>
      DateFormat("HH:mm:ss dd-MM-yyyy ").format(dateTime);
}

