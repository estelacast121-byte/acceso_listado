import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pantallas/login.dart';

void main() => runApp(const ProviderScope(child: Aplicacion()));

class Aplicacion extends StatelessWidget {
  const Aplicacion({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Acceso y listado',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF102C44),
        primary: const Color(0xFF102C44),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF102C44),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEF3FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE8EDF5))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
    ),
    home: const PantallaLogin(),
  );
}
