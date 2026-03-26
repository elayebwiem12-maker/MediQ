import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttercousd/provider/queue_notifier.dart';
import 'package:fluttercousd/screens/role_selection_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => QueueNotifier(),
      child: const MediQApp(),
    ),
  );
}

class MediQApp extends StatelessWidget {
  const MediQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      home: const RoleSelectionScreen(),
    );
  }
}