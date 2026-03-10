import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../services/connection_service.dart';
import '../theme/colors.dart';
import '../widgets/mouse_button.dart';
import '../widgets/scroll_strip.dart';
import '../widgets/settings_overlay.dart';
import '../widgets/trackpad_surface.dart';

class TrackpadScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const TrackpadScreen({super.key, required this.prefs});

  @override
  State<TrackpadScreen> createState() => _TrackpadScreenState();
}

class _TrackpadScreenState extends State<TrackpadScreen> {
  late AppSettings _settings;
  final _conn = ConnectionService.instance;
  StreamSubscription<ConnState>? _connSub;
  ConnState _connState = ConnState.disconnected;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(); // defaults until prefs load
    _loadSettings();
    _connSub = _conn.stateStream.listen((s) {
      if (mounted) setState(() => _connState = s);
    });
  }

  Future<void> _loadSettings() async {
    final s = await AppSettings.load(widget.prefs);
    if (mounted) setState(() => _settings = s);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  void _onSaved(AppSettings s) async {
    await s.save(widget.prefs);
    if (mounted) setState(() => _settings = s);
  }

  Future<String?> _onConnect(String host, int port) =>
      _conn.connect(host, port);

  void _showSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => SettingsOverlay(
        settings: _settings,
        connState: _connState,
        onConnect: _onConnect,
        onDisconnect: _conn.disconnect,
        onSave: _onSaved,
      ),
    );
  }

  // ── Status helpers ─────────────────────────────────────────────────────────

  Color get _statusColor => switch (_connState) {
        ConnState.connected => AppColors.connected,
        ConnState.connecting => AppColors.connecting,
        ConnState.error => AppColors.disconnected,
        ConnState.disconnected => AppColors.textSecondary,
      };

  String get _statusLabel => switch (_connState) {
        ConnState.connected => 'CONNECTED',
        ConnState.connecting => 'CONNECTING',
        ConnState.error => 'ERROR',
        ConnState.disconnected => 'OFFLINE',
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child: Column(
              children: [
                // Trackpad surface — 72 % of remaining height
                Expanded(
                  flex: 72,
                  child: TrackpadSurface(
                    sensitivity: _settings.sensitivity,
                    onMove: (dx, dy) => _conn.send({'t': 'm', 'x': dx, 'y': dy}),
                    isConnected: _connState == ConnState.connected,
                  ),
                ),
                Container(height: 1, color: AppColors.divider),
                // Button bar — 28 %
                Expanded(
                  flex: 28,
                  child: _buttonBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 38,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'MOUSEPAD',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.5,
            ),
          ),
          const SizedBox(width: 20),
          // Live status dot + label
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
              boxShadow: _connState == ConnState.connected
                  ? [BoxShadow(color: _statusColor.withValues(alpha: 0.5), blurRadius: 5)]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel,
            style: TextStyle(
              color: _statusColor,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showSettings,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.tune, color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: MouseButton(
            label: 'LEFT',
            color: AppColors.leftBtn,
            accentColor: AppColors.accent,
            onTap: () => _conn.send({'t': 'l'}),
          ),
        ),
        Container(width: 1, color: AppColors.divider),
        Expanded(
          flex: 4,
          child: ScrollStrip(
            scrollSpeed: _settings.scrollSpeed,
            naturalScroll: _settings.naturalScroll,
            onScroll: (ticks) => _conn.send({'t': 's', 'd': ticks}),
          ),
        ),
        Container(width: 1, color: AppColors.divider),
        Expanded(
          flex: 3,
          child: MouseButton(
            label: 'RIGHT',
            color: AppColors.rightBtn,
            accentColor: const Color(0xFFFF6B9D),
            onTap: () => _conn.send({'t': 'r'}),
          ),
        ),
      ],
    );
  }
}
