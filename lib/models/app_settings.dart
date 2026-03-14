import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  String host;
  int port;
  double sensitivity;
  double scrollSpeed;
  bool naturalScroll;

  AppSettings({
    this.host = '192.168.1.100',
    this.port = 8765,
    this.sensitivity = 6.0,
    this.scrollSpeed = 3.0,
    this.naturalScroll = false,
  });

  static Future<AppSettings> load(SharedPreferences prefs) async {
    return AppSettings(
      host: prefs.getString('mp_host') ?? '192.168.1.100',
      port: prefs.getInt('mp_port') ?? 8765,
      sensitivity: prefs.getDouble('mp_sensitivity') ?? 6.0,
      scrollSpeed: prefs.getDouble('mp_scrollSpeed') ?? 3.0,
      naturalScroll: prefs.getBool('mp_naturalScroll') ?? false,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    await Future.wait([
      prefs.setString('mp_host', host),
      prefs.setInt('mp_port', port),
      prefs.setDouble('mp_sensitivity', sensitivity),
      prefs.setDouble('mp_scrollSpeed', scrollSpeed),
      prefs.setBool('mp_naturalScroll', naturalScroll),
    ]);
  }

  AppSettings copyWith({
    String? host,
    int? port,
    double? sensitivity,
    double? scrollSpeed,
    bool? naturalScroll,
  }) {
    return AppSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      sensitivity: sensitivity ?? this.sensitivity,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      naturalScroll: naturalScroll ?? this.naturalScroll,
    );
  }
}
