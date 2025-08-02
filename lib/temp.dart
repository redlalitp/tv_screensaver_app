
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Temp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Directly return the simplest UI. No conditions, no state checks.
    return Scaffold(
      backgroundColor: Colors.green,
      // Changed color to be sure it's this version
      body: Center(
        child: Text(
          "ULTRA SIMPLE TEST",
          style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}