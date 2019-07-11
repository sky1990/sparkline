import 'package:flutter/material.dart';
import 'package:flutter_sparkline/flutter_sparkline.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  List<SparkLineStockModel> lineValuesList = List();
  List<SparkLineStockModel> lineList = List();
  double lineCount;
  double yMax = 0.0; //Maximum on the Y axis
  double yMin = 0.0; //Minimum on the Y axis


  @override
  void initState() {
    super.initState();

    lineValuesList.clear();
    lineCount = 0; //
    iniData();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
      width: 300,
          height: 200,
          child: Container(
              height: 200,
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9 * (8 / 12),

              child: new Sparkline(
                data: lineValuesList,
                allLength: lineCount,
                fillMode: FillMode.below,
                fillColor: Colors.grey,
                lineColor: Colors.deepOrangeAccent,
                lineWidth: 1.0,
                yMax: yMax,
                yMin: yMin,
              )
          )
      ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void iniData() {

    ///edit the fake sample data
    lineValuesList.add(
        SparkLineStockModel(
            value: 26.91,
            time: '9:45:00',
            riseAndFall: '-0.14',
            amplitude: '-0.52%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 26.1,
            time: '9:30:00',
            riseAndFall: '-0.23',
            amplitude: '-0.50%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.1,
            time: '9:47:00',
            riseAndFall: '0.25',
            amplitude: '0.86%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.1,
            time: '9:50:00',
            riseAndFall: '0.25',
            amplitude: '0.93%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.9,
            time: '9:55:00',
            riseAndFall: '0.32',
            amplitude: '1.12%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.0,
            time: '9:59:00',
            riseAndFall: '0.25',
            amplitude: '0.93%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 26.96,
            time: '10:03:00',
            riseAndFall: '0.12',
            amplitude: '0.45%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.07,
            time: '10:19:00',
            riseAndFall: '0.22',
            amplitude: '0.82%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.16,
            time: '10:20:00',
            riseAndFall: '0.29',
            amplitude: '1.08%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.11,
            time: '10:39:00',
            riseAndFall: '0.26',
            amplitude: '0.97%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 28.1,
            time: '10:49:00',
            riseAndFall: '0.35',
            amplitude: '1.12%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.78,
            time: '10:51:00',
            riseAndFall: '0.31',
            amplitude: '1.09%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.31,
            time: '10:56:00',
            riseAndFall: '0.29',
            amplitude: '0.98%'
        )
    );
    lineValuesList.add(
        SparkLineStockModel(
            value: 27.32,
            time: '11:02:00',
            riseAndFall: '0.29',
            amplitude: '0.99%'
        )
    );


    double max = 0.0; //Maximum value of array
    double min = 1000.0; //Minimum value of array

    for (SparkLineStockModel model in lineValuesList) {
      lineList.add(model);

      lineCount += 1;
      if(model.value < 0) {
        continue;
      }

      if(max < model.value) {
        max = model.value;
      }
      if(min > model.value) {
        min = model.value;
      }
    }
    lineCount += 5;

    ///Get the maximum and minimum values on the Y-axis in the line graph
    double ytp = 27.2; //yesterday's closing price
    double bilu;

    if(max >= ytp) {
      bilu = (max - ytp) / ytp + 0.02;
    }else {
      bilu = (ytp - max) / ytp + 0.02;
    }
    yMax = (1 + bilu) * ytp;
    yMin = (1 - bilu) * ytp;

    setState(() {

    });
  }

}
