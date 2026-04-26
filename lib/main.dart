import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

// Stitch Design System Colors (Industrial Precision)
const ColorScheme jikensColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF031632), // Deep Blue
  onPrimary: Colors.white,
  primaryContainer: Color(0xFF1A2B48),
  onPrimaryContainer: Color(0xFF8293B5),
  secondary: Color(0xFFFE6B00), // Vibrant Orange
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFFFDBCC),
  onSecondaryContainer: Color(0xFF572000),
  tertiary: Color(0xFF0C1728),
  onTertiary: Colors.white,
  error: Color(0xFFBA1A1A),
  onError: Colors.white,
  surface: Color(0xFFF7F9FB), // Clean Cool Gray
  onSurface: Color(0xFF191C1E),
  surfaceContainerHighest: Color(0xFFE0E3E5),
  onSurfaceVariant: Color(0xFF44474D),
  outline: Color(0xFF75777E),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      title: 'Jikens Auto Garage',
      theme: ThemeData(
        colorScheme: jikensColorScheme,
        useMaterial3: true,
        textTheme: textTheme,
        scaffoldBackgroundColor: jikensColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: jikensColorScheme.surface,
          foregroundColor: jikensColorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: jikensColorScheme.onSurface,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, // Ensure cards pop forward
          elevation: 0, // Using shape outlines instead of heavy shadows
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: jikensColorScheme.surfaceContainerHighest, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: jikensColorScheme.primary,
            foregroundColor: jikensColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: jikensColorScheme.secondary,
            foregroundColor: jikensColorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: jikensColorScheme.primary,
            side: BorderSide(color: jikensColorScheme.primary, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: jikensColorScheme.outlineVariant, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: jikensColorScheme.outlineVariant, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: jikensColorScheme.primary, width: 2),
          ),
          labelStyle: TextStyle(color: jikensColorScheme.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      themeMode: ThemeMode.light, // Enforcing light mode as per design system
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
