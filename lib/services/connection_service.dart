import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnState { disconnected, connecting, connected, error }

class ConnectionService {
  static final ConnectionService instance = ConnectionService._();
  ConnectionService._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  final _stateCtrl = StreamController<ConnState>.broadcast();
  Stream<ConnState> get stateStream => _stateCtrl.stream;

  ConnState _state = ConnState.disconnected;
  ConnState get state => _state;
  String lastError = '';

  void _emit(ConnState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  /// Returns null on success, an error message on failure.
  Future<String?> connect(String host, int port) async {
    if (_state == ConnState.connected || _state == ConnState.connecting) {
      await disconnect();
    }
    _emit(ConnState.connecting);
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _emit(ConnState.connected);
      _sub = _channel!.stream.listen(
        (_) {},
        onDone: () {
          _sub = null;
          _emit(ConnState.disconnected);
        },
        onError: (dynamic e) {
          lastError = e.toString();
          _sub = null;
          _emit(ConnState.error);
        },
        cancelOnError: true,
      );
      return null;
    } catch (e) {
      lastError = e.toString();
      _emit(ConnState.error);
      return lastError;
    }
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _emit(ConnState.disconnected);
  }

  /// Fire-and-forget. Silently drops if not connected.
  void send(Map<String, dynamic> data) {
    if (_state == ConnState.connected) {
      _channel?.sink.add(jsonEncode(data));
    }
  }
}
