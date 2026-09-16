import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(child: Text('No route for ${settings.name}')),
      ),
    );
  }
}
