import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'provider/queue_notifier.dart';
import 'screens/role_selection_screen.dart';
import 'screens/patient_login_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => QueueNotifier())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/patient-login': (context) => const PatientLoginScreen(),
        '/patient-home': (context) => const PatientHomeScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin': (context) => const AdminScreen(),
      },
    );
  }
}
