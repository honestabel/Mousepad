import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnState { disconnected, connecting, connected, error }

class ConnectionService {
  static final ConnectionService instance = ConnectionService._();
  ConnectionService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;

  final _stateCtrl = StreamController<ConnState>.broadcast();
  Stream<ConnState> get stateStream => _stateCtrl.stream;

  ConnState _state = ConnState.disconnected;
  ConnState get state => _state;
  String lastError = '';

  // Reconnect state
  String? _lastHost;
  int? _lastPort;
  int _reconnectAttempt = 0;
  static const _reconnectDelays = [2, 5, 10, 20, 30]; // seconds

  void _emit(ConnState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  /// Returns null on success, an error message on failure.
  /// Saves host/port for automatic reconnection on unexpected drops.
  Future<String?> connect(String host, int port) async {
    _cancelReconnect();
    if (_state == ConnState.connected || _state == ConnState.connecting) {
      await _closeChannel();
    }
    _lastHost = host;
    _lastPort = port;
    _reconnectAttempt = 0;
    return _doConnect(host, port);
  }

  Future<String?> _doConnect(String host, int port) async {
    _emit(ConnState.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _reconnectAttempt = 0; // reset on successful connect
      _emit(ConnState.connected);
      _sub = _channel!.stream.listen(
        (_) {},
        onDone: () {
          _sub = null;
          _emit(ConnState.disconnected);
          _scheduleReconnect(); // unexpected close → retry
        },
        onError: (dynamic e) {
          lastError = e.toString();
          _sub = null;
          _emit(ConnState.error);
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
      return null;
    } catch (e) {
      lastError = e.toString();
      _emit(ConnState.error);
      _scheduleReconnect();
      return lastError;
    }
  }

  void _scheduleReconnect() {
    if (_lastHost == null || _lastPort == null) return;
    final delaySecs = _reconnectAttempt < _reconnectDelays.length
        ? _reconnectDelays[_reconnectAttempt]
        : _reconnectDelays.last;
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySecs), () {
      if (_lastHost != null && _state != ConnState.connected) {
        _doConnect(_lastHost!, _lastPort!);
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _closeChannel() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }

  /// Explicit user disconnect — cancels auto-reconnect.
  Future<void> disconnect() async {
    _cancelReconnect();
    _lastHost = null;
    _lastPort = null;
    _reconnectAttempt = 0;
    await _closeChannel();
    _emit(ConnState.disconnected);
  }

  /// Fire-and-forget. Silently drops if not connected.
  void send(Map<String, dynamic> data) {
    if (_state == ConnState.connected) {
      _channel?.sink.add(jsonEncode(data));
    }
  }
}
