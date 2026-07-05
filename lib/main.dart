import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() => runApp(const IcheonHighApp());

class IcheonHighApp extends StatelessWidget {
  const IcheonHighApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // TODO (3번 담당자): 앱 이름 변경!
      title: '이천고 학사일정',
      theme: ThemeData(
        useMaterial3: true,
        // TODO (3번 담당자): 이천고 상징색으로 테마 변경!
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const SplashScreen(),
    );
  }
}
