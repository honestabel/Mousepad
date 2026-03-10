import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multicast_dns/multicast_dns.dart';

import '../models/app_settings.dart';
import '../services/connection_service.dart';
import '../theme/colors.dart';

class SettingsOverlay extends StatefulWidget {
  final AppSettings settings;
  final ConnState connState;
  final Future<String?> Function(String host, int port) onConnect;
  final Future<void> Function() onDisconnect;
  final void Function(AppSettings) onSave;

  const SettingsOverlay({
    super.key,
    required this.settings,
    required this.connState,
    required this.onConnect,
    required this.onDisconnect,
    required this.onSave,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late double _sensitivity;
  late double _scrollSpeed;
  late bool _naturalScroll;
  bool _connecting = false;
  bool _discovering = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: widget.settings.host);
    _portCtrl = TextEditingController(text: widget.settings.port.toString());
    _sensitivity = widget.settings.sensitivity;
    _scrollSpeed = widget.settings.scrollSpeed;
    _naturalScroll = widget.settings.naturalScroll;
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  AppSettings get _current => widget.settings.copyWith(
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text) ?? widget.settings.port,
        sensitivity: _sensitivity,
        scrollSpeed: _scrollSpeed,
        naturalScroll: _naturalScroll,
      );

  // ── mDNS discovery ─────────────────────────────────────────────────────────

  Future<void> _discover() async {
    setState(() {
      _discovering = true;
      _errorText = null;
    });

    final client = MDnsClient();
    final completer = Completer<(String, int)?>();

    try {
      await client.start();

      // Timeout after 6 seconds
      Timer(const Duration(seconds: 6), () {
        if (!completer.isCompleted) completer.complete(null);
      });

      client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('_mousepad._udp.local'),
          )
          .listen((PtrResourceRecord ptr) async {
        await for (final SrvResourceRecord srv in client
            .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client
              .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target))) {
            if (!completer.isCompleted) {
              completer.complete((ip.address.address, srv.port));
            }
            break;
          }
          break;
        }
      });

      final found = await completer.future;
      client.stop();

      if (!mounted) return;

      if (found != null) {
        _hostCtrl.text = found.$1;
        _portCtrl.text = found.$2.toString();
        setState(() => _discovering = false);
      } else {
        setState(() {
          _discovering = false;
          _errorText = 'Desktop not found — enter IP manually';
        });
      }
    } catch (e) {
      client.stop();
      if (mounted) {
        setState(() {
          _discovering = false;
          _errorText = 'Discovery failed — enter IP manually';
        });
      }
    }
  }

  // ── Connect / Save ──────────────────────────────────────────────────────────

  Future<void> _connect() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      setState(() => _errorText = 'Enter a desktop IP address');
      return;
    }
    final port = int.tryParse(_portCtrl.text) ?? 8765;
    widget.onSave(_current);
    setState(() {
      _connecting = true;
      _errorText = null;
    });
    final err = await widget.onConnect(host, port);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _connecting = false;
        _errorText = err;
      });
    }
  }

  void _save() {
    widget.onSave(_current);
    Navigator.of(context).pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.connState == ConnState.connected;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const SizedBox(height: 20),
              _label('CONNECTION'),
              // IP row with FIND button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _field(_hostCtrl, 'Desktop IP  (e.g. 192.168.1.100)',
                        type: TextInputType.number),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed:
                          (_discovering || _connecting) ? null : _discover,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceHigh,
                        foregroundColor: AppColors.accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _discovering
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent))
                          : const Text('FIND',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field(_portCtrl, 'Port  (default: 8765)',
                  type: TextInputType.number),
              const SizedBox(height: 12),
              _connectBtn(isConnected),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!,
                    style: const TextStyle(
                        color: AppColors.disconnected, fontSize: 11)),
              ],
              _divider(),
              _label('INPUT'),
              _slider('Sensitivity', _sensitivity, 0.5, 4.0, 7,
                  (v) => setState(() => _sensitivity = v)),
              _slider('Scroll Speed', _scrollSpeed, 1.0, 8.0, 14,
                  (v) => setState(() => _scrollSpeed = v)),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Natural Scroll',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Switch(
                    value: _naturalScroll,
                    onChanged: (v) => setState(() => _naturalScroll = v),
                    activeThumbColor: AppColors.accent,
                    activeTrackColor: AppColors.accentDim,
                    inactiveTrackColor: AppColors.surfaceHigh,
                  ),
                ],
              ),
              _divider(),
              _serverHint(),
              const SizedBox(height: 20),
              _bottomBtns(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _header() {
    final color = switch (widget.connState) {
      ConnState.connected => AppColors.connected,
      ConnState.connecting => AppColors.connecting,
      ConnState.error => AppColors.disconnected,
      ConnState.disconnected => AppColors.textSecondary,
    };
    final label = switch (widget.connState) {
      ConnState.connected => 'READY',
      ConnState.connecting => 'APPLYING',
      ConnState.error => 'ERROR',
      ConnState.disconnected => 'OFFLINE',
    };
    return Row(
      children: [
        const Icon(Icons.settings, color: AppColors.accent, size: 18),
        const SizedBox(width: 10),
        const Text('SETTINGS',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 9,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700)),
      );

  Widget _divider() => Container(
      height: 1,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(vertical: 16));

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: type == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      ),
    );
  }

  Widget _connectBtn(bool isConnected) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _connecting ? null : (isConnected ? widget.onDisconnect : _connect),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected
              ? AppColors.disconnected.withValues(alpha: 0.12)
              : AppColors.accentDim,
          foregroundColor:
              isConnected ? AppColors.disconnected : AppColors.accent,
          side: BorderSide(
              color: isConnected
                  ? AppColors.disconnected.withValues(alpha: 0.35)
                  : AppColors.accent.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: const EdgeInsets.symmetric(vertical: 11),
          elevation: 0,
        ),
        child: _connecting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent))
            : Text(
                isConnected ? 'CLEAR' : 'APPLY',
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      int divisions, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surfaceHigh,
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accent.withValues(alpha: 0.1),
                trackHeight: 2,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(value.toStringAsFixed(1),
                style:
                    const TextStyle(color: AppColors.accent, fontSize: 11),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _serverHint() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DESKTOP SERVER SETUP',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 8.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 7),
            Text(
              'pip install pyautogui zeroconf\npython server/server.py',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          ],
        ),
      );

  Widget _bottomBtns() => Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                      fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentDim,
                foregroundColor: AppColors.accent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
              child: const Text('SAVE',
                  style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ),
          ),
        ],
      );
}
