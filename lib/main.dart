import 'package:capstone/app_home_page.dart';
import 'package:capstone/web_home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: const Color(0xffE5E5E5)),
      home: kIsWeb ? const WebHomePage() : const AppHomePage(),
    );
  }
}
