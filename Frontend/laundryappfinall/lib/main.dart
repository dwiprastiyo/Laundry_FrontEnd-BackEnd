import 'alurautentikasi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  runApp(LaundryApp(isLoggedIn: isLoggedIn));
}

class LaundryApp extends StatelessWidget {
  final bool isLoggedIn;
  const LaundryApp({Key? key, this.isLoggedIn = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaundryMuna',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        primaryColor: Colors.blue[600],
        scaffoldBackgroundColor: Colors.grey[50], // Default light background
        cardColor: Colors.white, // Default light card
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.blue[600],
          secondary: Colors.cyan[500],
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        dividerColor: Colors.grey[100],
      ),
      home: isLoggedIn ? const MainScreen() : const WelcomeScreen(),
    );
  }
}
