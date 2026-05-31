import 'package:flutter/material.dart';

// TODO: Samuel — descomentar cuando Firebase esté configurado
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Samuel — descomentar cuando agregues google-services.json
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D9E75)),
        useMaterial3: true,
      ),
      // TODO: equipo — reemplazar con sus pantallas reales
      home: const Scaffold(
        body: Center(
          child: Text('Encuéntralo — estructura base lista'),
        ),
      ),
    );
  }
}
