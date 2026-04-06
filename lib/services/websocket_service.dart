import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;

  final String _serverUrl = 'ws://3.228.25.228:5000';

  bool get isConnected => _channel != null;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      print('Conectando al servidor...');
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  Stream<Map<String, dynamic>>? get messagesStream {
    return _channel?.stream.map((message) {
      try {
        return jsonDecode(message) as Map<String, dynamic>;
      } catch (e) {
        print('Error al decodificar mensaje: $e');
        return {
          "type": "error",
          "message": "Mensaje inválido recibido del servidor"
        };
      }
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_channel == null) {
      print('No hay conexión activa');
      return;
    }

    try {
      final jsonString = jsonEncode(data);
      _channel!.sink.add(jsonString);
      print('Enviado: $jsonString');
    } catch (e) {
      print('Error al enviar mensaje: $e');
    }
  }

  void disconnect() {
    try {
      _channel?.sink.close();
      _channel = null;
      print('Sesión cerrada');
    } catch (e) {
      print('Error al cerrar conexión: $e');
    }
  }
}