import 'package:flutter/material.dart';
import 'services/websocket_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test WebSocket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TestSocketScreen(),
    );
  }
}

class TestSocketScreen extends StatefulWidget {
  const TestSocketScreen({super.key});

  @override
  State<TestSocketScreen> createState() => _TestSocketScreenState();
}

class _TestSocketScreenState extends State<TestSocketScreen> {
  final WebSocketService socketService = WebSocketService();
  String log = '--- LOG ---\n';

  @override
  void initState() {
    super.initState();

    // 🔌 Conectar al iniciar
    socketService.connect();

    // 👂 Escuchar mensajes del servidor
    socketService.messagesStream?.listen((data) {
      setState(() {
        log += '\n$data';
      });
    });
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }

  // 🚀 Crear sala
  void crearSala() {
    socketService.sendMessage({
      "type": "create_room",
      "player_name": "Carlitos"
    });
  }

  // 👥 Unirse a sala (opcional prueba)
  void unirseSala() {
    socketService.sendMessage({
      "type": "join_room",
      "player_name": "Carlitos",
      "room_code": "ABC123" // cambia por uno real
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba WebSocket AWS'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: crearSala,
              child: const Text('Crear sala'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: unirseSala,
              child: const Text('Unirse a sala'),
            ),
            const SizedBox(height: 20),

            // 🧾 Consola de mensajes
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: Colors.black,
                child: SingleChildScrollView(
                  child: Text(
                    log,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}