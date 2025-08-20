import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

Future<void> main() async {
  //await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ola Maps App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapScreen(),
    );
  }
}