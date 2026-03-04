import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    setWindowMinSize(const Size(400, 600));
    setWindowFrame(const Rect.fromLTWH(100, 100, 600, 1000));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterLog',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
