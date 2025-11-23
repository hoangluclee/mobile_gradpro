// lib/screens/lecturer/lich_day_screen.dart
import 'package:flutter/material.dart';

class LichDayScreen extends StatelessWidget {
  const LichDayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lịch hướng dẫn"), backgroundColor: Colors.blueAccent),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text("Lịch họp với các nhóm sẽ hiển thị ở đây", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}