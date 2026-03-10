import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/trackpad_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape for tablet use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for full-screen immersive feel
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  runApp(MousepadApp(prefs: prefs));
}

class MousepadApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MousepadApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mousepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4D9FFF),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: TrackpadScreen(prefs: prefs),
    );
  }
}
