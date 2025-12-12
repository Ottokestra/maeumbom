import 'package:flutter/material.dart';
import 'alarm_test_screen.dart';

void main() {
  runApp(const AlarmTestApp());
}

class AlarmTestApp extends StatelessWidget {
  const AlarmTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm Test',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AlarmTestScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
