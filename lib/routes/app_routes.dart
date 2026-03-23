import 'package:flutter/material.dart';
import '../screens/auth/loginScreen.dart';
import '../screens/home/homeScreen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    home: (context) => HomeScreen(),
  };
}
