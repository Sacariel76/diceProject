import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/player_model.dart';
import '../models/round_score_model.dart';
import '../services/websocket_service.dart';

enum RoomPhase { initial, hostWaiting, guestWaiting, playing }

enum ConnectionStatus {
  connected,
  connecting,
  reconnecting,
  disconnected,
  critical,
}

enum GameTurnPhase {
  waiting,
  rolling,
  selecting,
  predicting,
  roundResults,
  finalResults,
}

class GameProvider extends ChangeNotifier {
  final WebSocketService _socket = WebSocketService();
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  final Completer<void> _initializationCompleter = Completer<void>();

  String playerName = '';
  String roomCode = '';
  String playerId = '';
  bool isHost = false;
  RoomPhase phase = RoomPhase.initial;
  List<PlayerModel> players = [];
  String? errorMessage;
  String? infoMessage;

  ConnectionStatus connectionStatus = ConnectionStatus.connecting;

  int currentRound = 1;
  final int totalRounds = 4;
  String currentTurnPlayerId = '';
  GameTurnPhase gameTurnPhase = GameTurnPhase.waiting;
  List<int> visibleDice = [];
  List<int> hiddenDice = [];
  String? selectedCombination;
  String? selectedPrediction;
  bool predictionSubmitted = false;
  int submittedPredictions = 0;
  int expectedPredictions = 0;
  bool tieDetected = false;
  String? tieMessage;
  List<RoundScoreModel> roundScores = [];
  Map<String, int> totalScores = {};
  bool isInitializationComplete = false;
  bool isRoundPaused = false;
  String? supportErrorCode;
  List<String> activityFeed = [];

  bool get isConnected => _socket.isConnected;
  bool get allPlayersReady =>
      players.isNotEmpty && players.every((p) => p.isReady);
  bool get isMyTurn =>
      currentTurnPlayerId.isEmpty || currentTurnPlayerId == playerId;
  bool get canPresentHand =>
      phase == RoomPhase.playing &&
      isMyTurn &&
      (gameTurnPhase == GameTurnPhase.waiting ||
          gameTurnPhase == GameTurnPhase.rolling ||
          gameTurnPhase == GameTurnPhase.selecting);
  bool get showConnectionBanner =>
      connectionStatus == ConnectionStatus.reconnecting ||
      connectionStatus == ConnectionStatus.disconnected;
  bool get showCriticalDisconnectModal =>
      connectionStatus == ConnectionStatus.critical;
  Future<void> get initializationDone => _initializationCompleter.future;

  String get connectionBannerText {
    switch (connectionStatus) {
      case ConnectionStatus.reconnecting:
        return 'Reconectando con la sala...';
      case ConnectionStatus.disconnected:
        return 'Sin conexion. Reintentando...';
      default:
        return '';
    }
  }

  String get currentTurnPlayerName {
    if (currentTurnPlayerId.isEmpty) {
      return players.isNotEmpty ? players.first.name : 'Jugador';
    }

    final player = players.where((p) => p.id == currentTurnPlayerId);
    if (player.isEmpty) {
      return 'Jugador';
    }
    return player.first.name;
  }

  List<int> get dicePoolForSelection {
    if (visibleDice.length >= 3) {
      return visibleDice;
    }
    return const [1, 2, 3, 4, 5, 6];
  }

  String? consumeInfoMessage() {
    final msg = infoMessage;
    infoMessage = null;
    return msg;
  }

  GameProvider() {
    _connectSocket();
  }

  void _connectSocket() {
    connectionStatus = ConnectionStatus.connecting;
    _socket.connect();

    if (!_socket.isConnected) {
      connectionStatus = ConnectionStatus.disconnected;
      errorMessage = _socket.lastError ?? 'No se pudo establecer la conexion.';
      _markInitialized();
      notifyListeners();
      return;
    }

    connectionStatus = ConnectionStatus.connected;
    _socketSub?.cancel();
    _socketSub = _socket.messagesStream?.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
    );
    _markInitialized();
    notifyListeners();
  }

  void _markInitialized() {
    if (!isInitializationComplete) {
      isInitializationComplete = true;
    }
    if (!_initializationCompleter.isCompleted) {
      _initializationCompleter.complete();
    }
  }

  void _handleDone() {
    connectionStatus = ConnectionStatus.disconnected;
    errorMessage = 'Conexion cerrada por el servidor.';
    notifyListeners();
  }

  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';

    switch (type) {
      case 'connected':
        _applyConnectionState('connected');
        break;
      case 'connection_state_changed':
        _applyConnectionState(data['state']?.toString() ?? 'connected');
        break;
      case 'reconnecting':
        _applyConnectionState('reconnecting');
        infoMessage = 'Intentando reconectar...';
        break;
      case 'reconnected':
        _applyConnectionState('connected');
        infoMessage = 'Conexion restablecida.';
        break;
      case 'critical_disconnect':
        _applyConnectionState('critical');
        errorMessage =
            data['message']?.toString() ?? 'Desconexion critica detectada.';
        break;
      case 'room_created':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['player_id']?.toString() ?? playerId;
        isHost = true;
        phase = RoomPhase.hostWaiting;
        players = [
          PlayerModel(
            id: playerId,
            name: playerName,
            isReady: true,
            isHost: true,
          ),
        ];
        errorMessage = null;
        supportErrorCode = null;
        break;
      case 'room_joined':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['player_id']?.toString() ?? playerId;
        isHost = false;
        phase = RoomPhase.guestWaiting;
        errorMessage = null;
        supportErrorCode = null;
        players = _parsePlayers(data['players']);
        break;
      case 'player_joined':
        _handlePlayerJoined(data);
        _appendActivity(
          '${data['player_name'] ?? 'Jugador'} ingreso a la sala.',
        );
        break;
      case 'player_left':
        _handlePlayerLeft(data);
        _appendActivity('Un jugador salio de la sala.');
        break;
      case 'player_ready_changed':
        _handlePlayerReadyChanged(data);
        break;
      case 'game_started':
        _handleGameStarted(data);
        break;
      case 'turn_changed':
        currentTurnPlayerId = data['player_id']?.toString() ?? '';
        gameTurnPhase = GameTurnPhase.selecting;
        _appendActivity('Cambio de turno: $currentTurnPlayerName.');
        break;
      case 'phase_changed':
        gameTurnPhase = _parseGameTurnPhase(data['phase']?.toString());
        break;
      case 'dice_rolled':
        visibleDice = _parseDice(data['visible_dice']);
        hiddenDice = _parseDice(data['hidden_dice']);
        gameTurnPhase = GameTurnPhase.selecting;
        break;
      case 'hand_submitted':
        _handleHandSubmitted(data);
        break;
      case 'prediction_submitted':
        submittedPredictions =
            (data['submitted_count'] as num?)?.toInt() ?? submittedPredictions;
        expectedPredictions =
            (data['total_players'] as num?)?.toInt() ??
            (players.isEmpty ? expectedPredictions : players.length);
        if (submittedPredictions >= expectedPredictions &&
            expectedPredictions > 0) {
          gameTurnPhase = GameTurnPhase.roundResults;
        }
        break;
      case 'round_result_ready':
        _handleRoundResults(data);
        _appendActivity('Resultados de ronda disponibles.');
        break;
      case 'final_result_ready':
        _handleFinalResults(data);
        _appendActivity('Resultados finales disponibles.');
        break;
      case 'tie_detected':
        tieDetected = true;
        tieMessage = data['message']?.toString() ?? 'Empate tecnico detectado.';
        _appendActivity('Empate tecnico detectado.');
        break;
      case 'join_failed':
        errorMessage =
            data['message']?.toString() ??
            'Codigo no encontrado. Verifica con el anfitrion.';
        supportErrorCode =
            data['code']?.toString() ??
            data['error_code']?.toString() ??
            'JOIN-FAILED';
        break;
      case 'error':
        errorMessage = data['message']?.toString() ?? 'Error desconocido.';
        supportErrorCode =
            data['code']?.toString() ?? data['error_code']?.toString();
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void _applyConnectionState(String state) {
    switch (state) {
      case 'connected':
        connectionStatus = ConnectionStatus.connected;
        break;
      case 'connecting':
        connectionStatus = ConnectionStatus.connecting;
        break;
      case 'reconnecting':
        connectionStatus = ConnectionStatus.reconnecting;
        break;
      case 'critical':
      case 'critical_disconnect':
        connectionStatus = ConnectionStatus.critical;
        break;
      default:
        connectionStatus = ConnectionStatus.disconnected;
        break;
    }
  }

  void _handlePlayerJoined(Map<String, dynamic> data) {
    final newId = data['player_id']?.toString() ?? '';
    if (newId.isEmpty) {
      return;
    }

    final already = players.any((p) => p.id == newId);
    if (!already) {
      players = [
        ...players,
        PlayerModel(
          id: newId,
          name: data['player_name']?.toString() ?? 'Jugador',
          isHost: data['is_host'] as bool? ?? false,
          isConnected: true,
        ),
      ];
      infoMessage = '${data['player_name'] ?? 'Un jugador'} se unio a la sala.';
      return;
    }

    players = players
        .map(
          (p) => p.id == newId
              ? p.copyWith(
                  isConnected: true,
                  name: data['player_name']?.toString(),
                )
              : p,
        )
        .toList();
  }

  void _handlePlayerLeft(Map<String, dynamic> data) {
    final leftId = data['player_id']?.toString() ?? '';
    if (leftId.isEmpty) {
      return;
    }

    final isPermanent = data['permanent'] as bool? ?? false;
    if (isPermanent) {
      final leftName = players.where((p) => p.id == leftId).isNotEmpty
          ? players.firstWhere((p) => p.id == leftId).name
          : 'Jugador';
      players = players.where((p) => p.id != leftId).toList();
      resumeRound('$leftName abandono la sala. Ronda reanudada.');
      return;
    }

    players = players
        .map(
          (p) => p.id == leftId
              ? p.copyWith(isConnected: false, isReady: false)
              : p,
        )
        .toList();

    final name = players.where((p) => p.id == leftId).isNotEmpty
        ? players.firstWhere((p) => p.id == leftId).name
        : 'Un jugador';
    pauseRound('$name abandono temporalmente la sala. Ronda en pausa.');
  }

  void _handlePlayerReadyChanged(Map<String, dynamic> data) {
    final pid = data['player_id']?.toString() ?? '';
    final ready = data['is_ready'] as bool? ?? false;

    players = players
        .map((p) => p.id == pid ? p.copyWith(isReady: ready) : p)
        .toList();
  }

  void _handleGameStarted(Map<String, dynamic> data) {
    phase = RoomPhase.playing;
    currentRound = (data['round'] as num?)?.toInt() ?? 1;
    gameTurnPhase = GameTurnPhase.waiting;
    currentTurnPlayerId = data['current_turn_player_id']?.toString() ?? '';
    visibleDice = _parseDice(data['visible_dice']);
    hiddenDice = _parseDice(data['hidden_dice']);
    selectedCombination = null;
    selectedPrediction = null;
    predictionSubmitted = false;
    submittedPredictions = 0;
    expectedPredictions = players.isEmpty ? 0 : players.length;
    tieDetected = false;
    tieMessage = null;
  }

  void _handleHandSubmitted(Map<String, dynamic> data) {
    final ownerId = data['player_id']?.toString() ?? '';
    final combination = data['combination']?.toString();

    if (ownerId == playerId && combination != null) {
      selectedCombination = combination;
      gameTurnPhase = GameTurnPhase.predicting;
    }
  }

  void _handleRoundResults(Map<String, dynamic> data) {
    roundScores = _parseRoundScores(data);

    if (data['total_scores'] != null) {
      totalScores = _parseTotalScores(data['total_scores']);
    }

    gameTurnPhase = GameTurnPhase.roundResults;
    submittedPredictions = 0;
    predictionSubmitted = false;
  }

  void _handleFinalResults(Map<String, dynamic> data) {
    if (data['total_scores'] != null) {
      totalScores = _parseTotalScores(data['total_scores']);
    }
    gameTurnPhase = GameTurnPhase.finalResults;
  }

  List<PlayerModel> _parsePlayers(dynamic rawPlayers) {
    if (rawPlayers is! List) {
      return players;
    }

    return rawPlayers.whereType<Map>().map((dynamic raw) {
      final map = raw.cast<String, dynamic>();
      return PlayerModel(
        id: map['player_id']?.toString() ?? '',
        name: map['player_name']?.toString() ?? 'Jugador',
        isReady: map['is_ready'] as bool? ?? false,
        isHost: map['is_host'] as bool? ?? false,
        isConnected: map['is_connected'] as bool? ?? true,
      );
    }).toList();
  }

  List<int> _parseDice(dynamic rawDice) {
    if (rawDice is! List) {
      return [];
    }

    return rawDice
        .map((value) => (value as num?)?.toInt())
        .whereType<int>()
        .toList();
  }

  GameTurnPhase _parseGameTurnPhase(String? rawPhase) {
    switch (rawPhase) {
      case 'rolling':
        return GameTurnPhase.rolling;
      case 'selecting':
        return GameTurnPhase.selecting;
      case 'predicting':
        return GameTurnPhase.predicting;
      case 'round_results':
        return GameTurnPhase.roundResults;
      case 'final_results':
        return GameTurnPhase.finalResults;
      case 'waiting':
      default:
        return GameTurnPhase.waiting;
    }
  }

  List<RoundScoreModel> _parseRoundScores(Map<String, dynamic> data) {
    final dynamic raw = data['scores'] ?? data['round_scores'];
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((dynamic e) => RoundScoreModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Map<String, int> _parseTotalScores(dynamic rawScores) {
    final result = <String, int>{};

    if (rawScores is Map) {
      rawScores.forEach((key, value) {
        final score = (value as num?)?.toInt();
        if (score != null) {
          result[key.toString()] = score;
        }
      });
      return result;
    }

    if (rawScores is List) {
      for (final item in rawScores.whereType<Map>()) {
        final row = item.cast<String, dynamic>();
        final id = row['player_id']?.toString();
        final score = (row['score'] as num?)?.toInt();
        if (id != null && score != null) {
          result[id] = score;
        }
      }
    }

    return result;
  }

  void _handleError(dynamic error) {
    connectionStatus = ConnectionStatus.disconnected;
    errorMessage = 'Error de conexion: $error';
    supportErrorCode = 'CONN-ERROR';
    _appendActivity('Error de conexion detectado.');
    notifyListeners();
  }

  void _appendActivity(String entry) {
    activityFeed = [entry, ...activityFeed];
    if (activityFeed.length > 10) {
      activityFeed = activityFeed.take(10).toList();
    }
  }

  void retryConnection() {
    connectionStatus = ConnectionStatus.reconnecting;
    supportErrorCode = null;
    notifyListeners();
    _socketSub?.cancel();
    _socket.disconnect();
    _connectSocket();
  }

  void dismissCriticalDisconnect() {
    if (connectionStatus == ConnectionStatus.critical) {
      connectionStatus = ConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  void createRoom(String name) {
    playerName = name;
    errorMessage = null;
    _socket.sendMessage({'type': 'create_room', 'player_name': name});
    _appendActivity('Solicitud para crear sala enviada.');
    notifyListeners();
  }

  void joinRoom(String name, String code) {
    playerName = name;
    roomCode = code;
    errorMessage = null;
    _socket.sendMessage({
      'type': 'join_room',
      'player_name': name,
      'room_code': code,
    });
    _appendActivity('Intentando unirse a sala $code.');
    notifyListeners();
  }

  void setReady() {
    _socket.sendMessage({
      'type': 'player_ready',
      'room_code': roomCode,
      'player_id': playerId,
    });

    players = players
        .map((p) => p.id == playerId ? p.copyWith(isReady: true) : p)
        .toList();
    _appendActivity('Marcado como listo.');
    notifyListeners();
  }

  void startGame() {
    _socket.sendMessage({
      'type': 'start_game',
      'room_code': roomCode,
      'player_id': playerId,
    });
    _appendActivity('Partida iniciada por host.');
  }

  void rollDice() {
    gameTurnPhase = GameTurnPhase.rolling;
    _socket.sendMessage({
      'type': 'roll_all_dice',
      'room_code': roomCode,
      'player_id': playerId,
    });
    _appendActivity('Lanzamiento de dados solicitado.');
    notifyListeners();
  }

  void submitHand(List<int> selectedDice, String combination) {
    selectedCombination = combination;
    gameTurnPhase = GameTurnPhase.predicting;
    _socket.sendMessage({
      'type': 'submit_combination',
      'room_code': roomCode,
      'player_id': playerId,
      'dice_ids': selectedDice,
      'selected_dice': selectedDice,
      'combination': combination,
    });
    _appendActivity('Combinacion enviada: $combination.');
    notifyListeners();
  }

  void submitPrediction(String card) {
    selectedPrediction = card;
    predictionSubmitted = true;
    if (expectedPredictions == 0 && players.isNotEmpty) {
      expectedPredictions = players.length;
    }
    submittedPredictions = submittedPredictions + 1;

    _socket.sendMessage({
      'type': 'select_prediction',
      'room_code': roomCode,
      'player_id': playerId,
      'prediction': card,
      'card': card,
    });
    _appendActivity('Prediccion enviada: $card.');

    if (expectedPredictions <= 1 ||
        (expectedPredictions > 0 &&
            submittedPredictions >= expectedPredictions)) {
      gameTurnPhase = GameTurnPhase.roundResults;
    }

    notifyListeners();
  }

  void setPredictionDraft(String card) {
    selectedPrediction = card;
    notifyListeners();
  }

  void markRoundResultsReadyForPreview() {
    gameTurnPhase = GameTurnPhase.roundResults;
    notifyListeners();
  }

  void continueAfterRoundResults() {
    if (currentRound >= totalRounds) {
      gameTurnPhase = GameTurnPhase.finalResults;
    } else {
      currentRound = currentRound + 1;
      gameTurnPhase = GameTurnPhase.waiting;
      visibleDice = [];
      hiddenDice = [];
      selectedCombination = null;
      selectedPrediction = null;
      predictionSubmitted = false;
      submittedPredictions = 0;
      roundScores = [];
      tieDetected = false;
      tieMessage = null;
      _socket.sendMessage({
        'type': 'continue_next_round',
        'room_code': roomCode,
        'player_id': playerId,
      });
      _appendActivity('Paso a la siguiente ronda.');
    }

    notifyListeners();
  }

  void cancelRoom() {
    _socket.sendMessage({
      'type': 'cancel_room',
      'room_code': roomCode,
      'player_id': playerId,
    });
    _appendActivity('Sala cancelada.');
    reset();
  }

  void pauseRound(String message) {
    isRoundPaused = true;
    infoMessage = message;
    _appendActivity(message);
    notifyListeners();
  }

  void resumeRound(String message) {
    isRoundPaused = false;
    infoMessage = message;
    _appendActivity(message);
    notifyListeners();
  }

  void reset() {
    roomCode = '';
    playerId = '';
    isHost = false;
    phase = RoomPhase.initial;
    players = [];
    errorMessage = null;
    infoMessage = null;
    currentRound = 1;
    currentTurnPlayerId = '';
    gameTurnPhase = GameTurnPhase.waiting;
    visibleDice = [];
    hiddenDice = [];
    selectedCombination = null;
    selectedPrediction = null;
    predictionSubmitted = false;
    submittedPredictions = 0;
    expectedPredictions = 0;
    tieDetected = false;
    tieMessage = null;
    roundScores = [];
    totalScores = {};
    isRoundPaused = false;
    supportErrorCode = null;
    activityFeed = [];
    notifyListeners();
  }

  void seedDemoDataForPreview() {
    playerName = 'Sebastian';
    playerId = 'p1';
    roomCode = 'A1B2C3';
    phase = RoomPhase.playing;
    players = const [
      PlayerModel(id: 'p1', name: 'Sebastian', isReady: true, isHost: true),
      PlayerModel(id: 'p2', name: 'Luis', isReady: true),
      PlayerModel(id: 'p3', name: 'Samiel', isReady: true),
    ];
    visibleDice = [1, 3, 5, 2, 6];
    hiddenDice = [4, 2, 6];
    currentRound = 2;
    currentTurnPlayerId = 'p1';
    gameTurnPhase = GameTurnPhase.selecting;
    totalScores = {'p1': 12, 'p2': 9, 'p3': 7};
    selectedCombination = 'Escalera';
    selectedPrediction = 'More';
    predictionSubmitted = true;
    expectedPredictions = 3;
    submittedPredictions = 2;
    tieDetected = false;
    tieMessage = null;
    isRoundPaused = false;
    supportErrorCode = null;
    roundScores = const [
      RoundScoreModel(
        playerId: 'p1',
        playerName: 'Sebastian',
        combination: 'Escalera',
        basePoints: 12,
        bonusPoints: 2,
      ),
      RoundScoreModel(
        playerId: 'p2',
        playerName: 'Luis',
        combination: 'Doble',
        basePoints: 8,
        bonusPoints: 1,
      ),
      RoundScoreModel(
        playerId: 'p3',
        playerName: 'Samiel',
        combination: 'Sencillo',
        basePoints: 5,
        bonusPoints: 0,
      ),
    ];
    activityFeed = [
      'Prediccion enviada: More.',
      'Combinacion enviada: Escalera.',
      'Cambio de turno: Sebastian.',
    ];
    errorMessage = null;
    infoMessage = 'Estado demo activo para revisar UI.';
    notifyListeners();
  }

  void seedRecoverableErrorPreview() {
    connectionStatus = ConnectionStatus.disconnected;
    errorMessage = 'No se pudo sincronizar con la sala en este momento.';
    supportErrorCode = 'NET-408';
    infoMessage = 'Error recuperable detectado.';
    notifyListeners();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socket.disconnect();
    super.dispose();
  }
}
