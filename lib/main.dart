import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const DroppiesApp());
}

class DroppiesApp extends StatelessWidget {
  const DroppiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Droppies Canvas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
