import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'core/database/database_helper.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // 1. Captura erros de renderização e widgets do Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    DatabaseHelper.instance.logGlobalError(details.exceptionAsString());
  };

  // 2. Captura erros assíncronos (exceções não tratadas no Dart)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    DatabaseHelper.instance.logGlobalError(error.toString());
    return true; // Retorna true para evitar que o app crashe
  };
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dona Guió',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F9DA1), // Teal/Verde-Água
          primary: const Color(0xFF1F9DA1),
          secondary: const Color(0xFFE4C09A), // Areia/Dourado
          surface: const Color(0xFFFDF8ED), // Fundo bege claro
        ),
        scaffoldBackgroundColor: const Color(0xFFFDF8ED),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F9DA1),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
