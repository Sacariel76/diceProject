import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  String? _lastError;

  final String _serverUrl = 'ws://34.232.89.243:5000';

  bool get isConnected => _channel != null;
  String? get lastError => _lastError;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _lastError = null;
    } catch (e) {
      _lastError = 'No se pudo conectar al servidor: $e';
    }
  }

  Stream<Map<String, dynamic>>? get messagesStream {
    return _channel?.stream.map((message) {
      try {
        _lastError = null;
        return jsonDecode(message) as Map<String, dynamic>;
      } catch (e) {
        _lastError = 'Error al decodificar mensaje: $e';
        return {
          'type': 'error',
          'message': 'Mensaje invalido recibido del servidor',
        };
      }
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_channel == null) {
      _lastError = 'No hay conexion activa';
      return;
    }

    try {
      final jsonString = jsonEncode(data);
      _channel!.sink.add(jsonString);
      _lastError = null;
    } catch (e) {
      _lastError = 'Error al enviar mensaje: $e';
    }
  }

  void disconnect() {
    try {
      _channel?.sink.close();
      _channel = null;
      _lastError = null;
    } catch (e) {
      _lastError = 'Error al cerrar conexion: $e';
    }
  }
}
