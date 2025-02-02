import 'package:flutter/material.dart';
import 'package:object_project/AgendaDocuments.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String,dynamic> jsonData = {};

  @override
  void initState() {
    super.initState();
    _incrementCounter();
  }

  void _incrementCounter() async {
    final String response = await rootBundle.loadString('assets/data.json');
    setState(()  {
      jsonData = json.decode(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: jsonData != {} ? Container(
          color: Colors.white,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: AgendaDocuments(
            inventoryData: jsonData,
          ),
        ) : Text("loading"),
      ),
    );
  }
}
