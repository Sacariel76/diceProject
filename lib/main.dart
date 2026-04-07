import 'dart:convert';
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
      title: 'Dado Triple Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SocketTestScreen(),
    );
  }
}

class SocketTestScreen extends StatefulWidget {
  const SocketTestScreen({super.key});

  @override
  State<SocketTestScreen> createState() => _SocketTestScreenState();
}

class _SocketTestScreenState extends State<SocketTestScreen> {
  final WebSocketService socketService = WebSocketService();

  final TextEditingController playerNameController =
      TextEditingController(text: 'Carlitos');
  final TextEditingController roomCodeController = TextEditingController();
  final TextEditingController playerIdController = TextEditingController();
  final TextEditingController diceIdsController =
      TextEditingController(text: 'w1,w2,w3');

  String selectedPrediction = 'MIN';
  String log = '--- LOG DEL SERVIDOR ---\n';

  String currentRoomCode = '';
  String currentPlayerId = '';

  @override
  void initState() {
    super.initState();
    socketService.connect();

    socketService.messagesStream?.listen(
      (data) {
        setState(() {
          log += '\n${const JsonEncoder.withIndent('  ').convert(data)}\n';
        });

        final type = data['type'];

        if (type == 'room_created') {
          final roomCode = data['room_code']?.toString() ?? '';
          final playerId = data['player_id']?.toString() ?? '';

          setState(() {
            currentRoomCode = roomCode;
            currentPlayerId = playerId;
            roomCodeController.text = roomCode;
            playerIdController.text = playerId;
          });
        }

        if (type == 'room_joined') {
          final playerId = data['player_id']?.toString() ?? '';
          setState(() {
            currentPlayerId = playerId;
            playerIdController.text = playerId;
          });
        }
      },
      onError: (error) {
        setState(() {
          log += '\nERROR STREAM: $error\n';
        });
      },
    );
  }

  @override
  void dispose() {
    playerNameController.dispose();
    roomCodeController.dispose();
    playerIdController.dispose();
    diceIdsController.dispose();
    socketService.disconnect();
    super.dispose();
  }

  void sendCreateRoom() {
    socketService.sendMessage({
      "type": "create_room",
      "player_name": playerNameController.text.trim(),
    });
  }

  void sendJoinRoom() {
    socketService.sendMessage({
      "type": "join_room",
      "player_name": playerNameController.text.trim(),
      "room_code": roomCodeController.text.trim(),
    });
  }

  void sendStartGame() {
    socketService.sendMessage({
      "type": "start_game",
      "room_code": roomCodeController.text.trim(),
      "player_id": playerIdController.text.trim(),
    });
  }

  void sendRollDice() {
    socketService.sendMessage({
      "type": "roll_all_dice",
      "room_code": roomCodeController.text.trim(),
      "player_id": playerIdController.text.trim(),
    });
  }

  void sendPrediction() {
    socketService.sendMessage({
      "type": "select_prediction",
      "room_code": roomCodeController.text.trim(),
      "player_id": playerIdController.text.trim(),
      "prediction": selectedPrediction,
    });
  }

  void sendCombination() {
    final diceIds = diceIdsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    socketService.sendMessage({
      "type": "submit_combination",
      "room_code": roomCodeController.text.trim(),
      "player_id": playerIdController.text.trim(),
      "dice_ids": diceIds,
    });
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connectedText = socketService.isConnected ? 'Conectado' : 'Desconectado';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pruebas Dado Triple'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Estado socket: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(connectedText),
                      ],
                    ),
                    const SizedBox(height: 12),
                    buildTextField('Nombre del jugador', playerNameController),
                    buildTextField('Código de sala', roomCodeController),
                    buildTextField('Player ID', playerIdController),
                    buildTextField(
                      'Dice IDs (ej: w1,w2,r1)',
                      diceIdsController,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedPrediction,
                      decoration: const InputDecoration(
                        labelText: 'Predicción',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ZERO', child: Text('ZERO')),
                        DropdownMenuItem(value: 'MIN', child: Text('MIN')),
                        DropdownMenuItem(value: 'MORE', child: Text('MORE')),
                        DropdownMenuItem(value: 'MAX', child: Text('MAX')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPrediction = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          buildActionButton('Crear sala', sendCreateRoom),
                          const SizedBox(height: 8),
                          buildActionButton('Unirse a sala', sendJoinRoom),
                          const SizedBox(height: 8),
                          buildActionButton('Iniciar partida', sendStartGame),
                          const SizedBox(height: 8),
                          buildActionButton('Tirar dados', sendRollDice),
                          const SizedBox(height: 8),
                          buildActionButton('Enviar predicción', sendPrediction),
                          const SizedBox(height: 8),
                          buildActionButton(
                            'Enviar combinación',
                            sendCombination,
                          ),
                          const SizedBox(height: 8),
                          buildActionButton('Limpiar log', () {
                            setState(() {
                              log = '--- LOG DEL SERVIDOR ---\n';
                            });
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          log,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Sala actual: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(currentRoomCode.isEmpty ? '-' : currentRoomCode)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Mi Player ID: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(child: Text(currentPlayerId.isEmpty ? '-' : currentPlayerId)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}