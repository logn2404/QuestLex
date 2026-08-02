import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Navigation Features
import 'features/navigation/presentation/controllers/navigation_controller.dart';
import 'features/navigation/presentation/pages/main_shell_page.dart';

void main() {
  runApp(const QuestLexApp());
}

class QuestLexApp extends StatelessWidget {
  const QuestLexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🛡️ Bọc NavigationController ở cấp gốc cao nhất của App
        ChangeNotifierProvider(create: (_) => NavigationController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'QuestLex',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        // 🛡️ Dùng MainShellPage làm khung chứa thay vì gọi HomePage trực tiếp
        home: const MainShellPage(),
      ),
    );
  }
}