import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 80,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 5, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Speed", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("0 km/h", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }
}
