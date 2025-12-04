import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/app_ui.dart';
import 'app/home/home_screen.dart';
import 'app/chat/chat_screen.dart';
import 'app/example/example_screen.dart';
import 'app/common/login_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaeumBomApp(),
    ),
  );
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
        //테스트용
        '/example': (context) => const ExampleScreen(),

        //실제 앱
        '/': (context) => const HomeScreen(),
        '/chat': (context) => const ChatScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
