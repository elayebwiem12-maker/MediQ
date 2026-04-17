import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'provider/queue_notifier.dart';
import 'screens/role_selection_screen.dart';
import 'screens/patient_login_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_screen.dart';
import 'services/socket_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser OneSignal
  OneSignal.initialize("761ea292-91d7-4566-8fa5-a7313205f0bf");

  // Demander la permission
  OneSignal.Notifications.requestPermission(true);

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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final ApiService _api = ApiService();
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await _api.isLoggedIn();
    if (isLoggedIn) {
      final token = await _api.getToken();
      if (token != null) {
        final socketService = SocketService();
        socketService.connect(token);
        final userId = await _api.getUserId();
        if (userId != null) {
          await OneSignal.login(userId);
          await OneSignal.User.addTagWithKey("user_role", "patient");
        }
      }
    }
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isLoggedIn) {
      return const RoleSelectionScreen();
    } else {
      return const PatientLoginScreen();
    }
  }
}
