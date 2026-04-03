import 'package:flutter/material.dart';
import 'package:frontend/Home_pages/home_user.dart';


class Switcher extends StatefulWidget {
  @override
  State<Switcher> createState() {
    return _Switcher();
  }
}

class _Switcher extends State<Switcher> {
  late Map<String,Widget> screens;
  Widget? currentScreen;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFEAF7FF),body:currentScreen!,
      ),
    );
  }
}