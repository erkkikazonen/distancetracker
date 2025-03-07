import 'package:flutter/material.dart';

class TrackingControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50,
      right: 16,
      child: Row(
        children: [
          ElevatedButton(onPressed: () {}, child: Text("Start")),
          SizedBox(width: 10),
          ElevatedButton(onPressed: () {}, child: Text("Pause")),
          SizedBox(width: 10),
          ElevatedButton(onPressed: () {}, child: Text("Stop")),
        ],
      ),
    );
  }
}
