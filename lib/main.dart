import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WebTVApp());
}

class WebTVApp extends StatelessWidget {
  const WebTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Color(AppConfig.primaryColorValue),
        colorScheme: ColorScheme.dark(
          primary: Color(AppConfig.primaryColorValue),
          secondary: Color(AppConfig.accentColorValue),
          surface: const Color(0xFF121212),
          background: const Color(0xFF000000),
        ),
        scaffoldBackgroundColor: const Color(0xFF000000),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
