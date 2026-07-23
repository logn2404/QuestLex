import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QuestLexApp());
}

class QuestLexApp extends StatelessWidget {
  const QuestLexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuestLex',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}