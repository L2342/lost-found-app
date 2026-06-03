import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/feed/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AuthService().init();

  runApp(const EncuentraloApp());
}

class EncuentraloApp extends StatelessWidget {
  const EncuentraloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encuéntralo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D9E75),
        ),
        useMaterial3: true,
      ),
      home: AuthService().isLoggedIn
          ? const FeedScreen()
          : const LoginScreen(),
    );
  }
}