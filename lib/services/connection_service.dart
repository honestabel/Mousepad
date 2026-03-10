import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

enum ConnState { disconnected, connecting, connected, error }

/// UDP-based transport. "Connecting" = DNS resolve + open local socket.
/// No TCP handshake — packets are sent fire-and-forget after configuration.
class ConnectionService {
  static final ConnectionService instance = ConnectionService._();
  ConnectionService._();

  RawDatagramSocket? _socket;
  InternetAddress? _targetAddr;
  int _targetPort = 8765;

  final _stateCtrl = StreamController<ConnState>.broadcast();
  Stream<ConnState> get stateStream => _stateCtrl.stream;

  ConnState _state = ConnState.disconnected;
  ConnState get state => _state;
  String lastError = '';

  void _emit(ConnState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  /// Resolve [host] and open a local UDP socket bound to any available port.
  /// Returns null on success, an error message on failure.
  Future<String?> connect(String host, int port) async {
    await disconnect();
    _emit(ConnState.connecting);
    try {
      final addresses = await InternetAddress.lookup(host);
      _targetAddr = addresses.first;
      _targetPort = port;
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _emit(ConnState.connected);
      return null;
    } catch (e) {
      lastError = e.toString();
      _emit(ConnState.error);
      return lastError;
    }
  }

  Future<void> disconnect() async {
    _socket?.close();
    _socket = null;
    _targetAddr = null;
    _emit(ConnState.disconnected);
  }

  /// Send a raw UDP datagram string. Drops silently if socket not ready.
  /// Protocol examples:
  ///   "MOVE:10.5,-3.2"   — relative mouse move
  ///   "LEFT"             — left click
  ///   "RIGHT"            — right click
  ///   "SCROLL:-2"        — scroll (negative = up, positive = down)
  void send(String message) {
    if (_state == ConnState.connected &&
        _socket != null &&
        _targetAddr != null) {
      _socket!.send(
        Uint8List.fromList(message.codeUnits),
        _targetAddr!,
        _targetPort,
      );
    }
  }
}
