import 'package:flutter/material.dart';
import 'package:landmark_recognition_example/camera.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.green
      ),
      routes: {
        '/': (context) => MainScreen(),
        '/camera': (context) => LandmarkRecognitionTest()
      },
    );
  }
}

class MainScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Здесь все сумасшедшие'),
      ),
      body: Container(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
