import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService {
  WebSocketChannel? _channel;
  
  // future URL of the WebSocket server (in AWS, it will be the public IP of EC2 instance)
  final String _serverUrl = 'ws://TU_IP_DE_AWS:5000';

  /// initialize the connection to the WebSocket server
  void connect(String playerName) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      print('Conectando al servidor...');
      
      // send the first mesage to the server to identify the player
      sendMessage({
        "accion": "conectar",
        "jugador": playerName
      });
      
    } catch (e) {
      print('Error de conexión: $e');
    }
  }

  /// listen the messages from the server
  Stream<dynamic>? get messagesStream {
    return _channel?.stream;
  }

  /// send data to the server (JSON format)
  void sendMessage(Map<String, dynamic> data) {
    if (_channel != null) {
      // convert the data to JSON string before sending
      String jsonString = jsonEncode(data);
      _channel!.sink.add(jsonString);
      print('Enviado: $jsonString');
    }
  }

  /// initialize the disconnection from the WebSocket server
  void disconnect() {
    _channel?.sink.close();
    print('Sesión cerrada');
  }
}