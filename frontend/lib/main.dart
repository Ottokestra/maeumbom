import 'package:flutter/material.dart';
import 'ui/app_ui.dart';
import 'app/home/home_screen.dart';
import 'app/chat/chat_screen.dart';
import 'app/common/example_screen.dart';

void main() {
  runApp(const MaeumBomApp());
}

class MaeumBomApp extends StatelessWidget {
  const MaeumBomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maeumbom',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: '/example',
      routes: {
        '/': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/example': (context) => const ExampleScreen(),
      },
    );
  }
}
