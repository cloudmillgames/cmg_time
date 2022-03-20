import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMG::TIME',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'CMG::TIME'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _tunits = 0;
  late Timer _timer;
  List<Widget> _existingTimers = <Widget>[];
  late SharedPreferences _sharedPreferences;
  bool sharedPrefsInitialized = false;
  List<String> _savedTimers = <String>[];
  bool _refreshSavedTimers = false;

  @override
  void initState() {
    super.initState();
    _initSharedPrefs();
    _tick();
  }

  void _initSharedPrefs() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    final int? freshTimersCount = _sharedPreferences.getInt('timersCount');
    sharedPrefsInitialized = true;
  }

  void _readSavedTimers() {
    final int? freshTimersCount = _sharedPreferences.getInt('timersCount');
    int tc = freshTimersCount ?? 0;
    if (tc != _savedTimers.length) {
      _refreshSavedTimers = true;
      final List<String>? freshSavedTimers = _sharedPreferences.getStringList('timers');
      _savedTimers = freshSavedTimers as List<String>;
    }
  }

  void _saveTimer(String desc, String duration, DateTime endtime) async {
    String start = DateTime.now().toIso8601String();
    String end = endtime.toIso8601String();
    String data = '{ "desc": "$desc", "duration": "$duration", "start": "$start", "end": "$end" }';
    //_savedTimers.add(data);
    //await _sharedPreferences.setStringList('timers', _savedTimers);
    print(data);
  }

  void _tick() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _tunits = _calcTimeUnits().toInt();
      _timer = Timer(Duration(seconds: 1), _tick);
      if (sharedPrefsInitialized) {
        _readSavedTimers();
      }
    });
  }

  double _calcTimeUnits() {
    final now = DateTime.now();
    const ratio = 1000/24.0;
    return (now.hour * ratio) + (now.minute / 60.0 * ratio);
  }

  // Returns error message in case of well, error.
  String _initTimer(String duration, String desc) {
    const SECS_PER_TICK = 24.0 * 60.0 * 60.0 / 1000.0;

    // 1. is duration valid?
    if (duration.isEmpty) {
      return "Failed: Empty duration";
    }
    duration = duration.trim();
    String duration_str = duration; // used for saved information

    // 2. is it ticks or HH:MM
    RegExp exp_hhmm = RegExp(r"^([0-9]+):([0-9]+)$");
    var match_hhmm = exp_hhmm.firstMatch(duration);
    RegExp exp_ticks = RegExp(r"^[0-9]+$");
    var match_ticks = exp_ticks.firstMatch(duration);

    // 3. setup timer
    int _timerSecs = 0;
    if (match_hhmm != null && match_hhmm.groupCount == 2) {
      // is hh:mm
      int hours = double.parse(match_hhmm.group(1).toString()).toInt();
      int minutes = double.parse(match_hhmm.group(2).toString()).toInt();
      _timerSecs = hours * 3600 + minutes * 60;
      duration_str = "";
      if (hours > 0) {
        duration_str = hours.toString() + " hours ";
      }
      if (minutes > 0) {
        duration_str = minutes.toString() + " minutes";
      }
    } else if (match_ticks != null) {
      // is ticks
      _timerSecs = (double.parse(match_ticks.group(0).toString()) * SECS_PER_TICK).toInt();
      duration_str = duration_str + " Ticks";
    } else {
      // is potato
      return "Failed: Unrecognizable duration value";
    }

    // 4. Init timer
    if (_timerSecs <= 0) {
      return "Failed: timer duration evaluates to 0 or less";
    }

    FlutterAlarmClock.createTimer(_timerSecs, title: desc, skipUi: true);
    print("Started CMG::Timer for $_timerSecs seconds titled: $desc");

    _saveTimer(desc, duration_str, DateTime.now().toUtc());

    return "";
  }

  void _showAddTimer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          String timerDesc = "";
          String timerDuration = "";
          String _errorMsg = "";
          return Scaffold(
              appBar: AppBar(title: const Text('New Timer')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter time amount in ticks or HH:MM',
                      ),
                      keyboardType: TextInputType.datetime,
                      onChanged: (text) { timerDuration = text; },
                    ),
                    const Divider(),
                    TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Description (optional)',
                      ),
                      onChanged: (text) { timerDesc = text; },
                    ),
                    const Divider(),
                    ElevatedButton(
                      child:  const Text('Init Timer', style: TextStyle(fontSize: 20.0)),
                      onPressed: () {
                        setState(() {
                          String err = _initTimer(timerDuration, timerDesc);
                          if (err.isEmpty) {
                            Navigator.pop(context);
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return const SimpleDialog(
                                    children: [
                                      Center(
                                        child: Text("Timer is set",
                                            style: TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  );
                                });
                          } else {
                            _errorMsg = err;
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return SimpleDialog(
                                    children: [
                                      Center(
                                        child: Text(_errorMsg,
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  );
                                });
                            print(_errorMsg);
                          }
                        });
                      },
                    ),
                    Text(_errorMsg),
                  ],
                ),
              ),
          );
        }
      )
    );
  }

  Widget _createTimerTile(String desc, String duration) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.timer),
        title: Text(desc),
        subtitle: Text(duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    // _existingTimers = [
    //   _createTimerTile("I AM FIRST"),
    //   _createTimerTile("SECOND AM I?"),
    // ];

    // '{ "desc": "I AM TIMER", "duration": "120 ticks", "start": "datetime_in_iso8601", "end": "datetime_in_iso8601" }'

    if (_refreshSavedTimers) {
      _refreshSavedTimers = false;
      _existingTimers.clear();
      for (var s in _savedTimers) {
        final parsed = jsonDecode(s);
        _existingTimers.add(_createTimerTile(parsed.desc, parsed.duration));
      }
    }
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_tunits',
              style: Theme.of(context).textTheme.headline1,
            ),
            Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _existingTimers,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimer,
        tooltip: 'Add Timer',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
