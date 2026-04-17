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
  bool isSpectator = false;
  RoomPhase phase = RoomPhase.initial;
  List<PlayerModel> players = [];
  List<String> spectators = [];

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

  List<_DieSnapshot> _myDice = [];
  String? _lastServerPhase;
  bool _myHasRolled = false;
  int _mySubmittedCount = 0;
  int _currentPresentationStep = 0;

  bool get isConnected => _socket.isConnected;
  bool get allPlayersReady => players.length >= 2;

  bool get isMyTurn =>
      !isSpectator &&
      (currentTurnPlayerId.isEmpty || currentTurnPlayerId == playerId);

  bool get canRollDice =>
      !isSpectator &&
      phase == RoomPhase.playing &&
      gameTurnPhase == GameTurnPhase.rolling &&
      !_myHasRolled;

  bool get canOpenPrediction =>
      !isSpectator &&
      phase == RoomPhase.playing &&
      gameTurnPhase == GameTurnPhase.predicting;

  bool get canPresentHand =>
      !isSpectator &&
      phase == RoomPhase.playing &&
      gameTurnPhase == GameTurnPhase.selecting &&
      isMyTurn &&
      (_mySubmittedCount < _currentPresentationStep ||
          _currentPresentationStep == 0);

  bool get canStartGame =>
      !isSpectator &&
      isHost &&
      phase != RoomPhase.playing &&
      players.length >= 2;

  bool get isReadOnlyViewer => isSpectator;

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
    final available = _myDice
        .where((d) => !d.used)
        .map((d) => d.value)
        .toList(growable: false);
    if (available.isNotEmpty) {
      return available;
    }
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
      case 'room_created':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['player_id']?.toString() ?? playerId;
        isHost = true;
        isSpectator = false;
        phase = RoomPhase.hostWaiting;
        players = [
          PlayerModel(
            id: playerId,
            name: playerName,
            isReady: true,
            isHost: true,
          ),
        ];
        spectators = [];
        errorMessage = null;
        supportErrorCode = null;
        _appendActivity('Sala creada: $roomCode');
        break;

      case 'room_joined':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['player_id']?.toString() ?? playerId;
        isHost = false;
        isSpectator = false;
        phase = RoomPhase.guestWaiting;
        errorMessage = null;
        supportErrorCode = null;
        _appendActivity('Ingreso exitoso a sala: $roomCode');
        break;

      case 'spectator_joined':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['spectator_id']?.toString() ?? playerId;
        isHost = false;
        isSpectator = true;
        phase = RoomPhase.guestWaiting;
        errorMessage = null;
        supportErrorCode = null;
        _appendActivity('Ingreso como espectador a sala: $roomCode');
        _appendActivity('Modo espectador activado');
        break;

      case 'state_update':
        final rawState = data['state'];
        if (rawState is Map) {
          _handleServerState(rawState.cast<String, dynamic>());
        }
        break;

      case 'error':
        errorMessage = data['message']?.toString() ?? 'Error desconocido.';
        supportErrorCode =
            data['code']?.toString() ?? data['error_code']?.toString();
        _appendActivity(errorMessage ?? 'Error');
        break;

      default:
        break;
    }

    notifyListeners();
  }

  void _handleServerState(Map<String, dynamic> state) {
    roomCode = state['room_code']?.toString() ?? roomCode;
    currentRound = (state['current_round'] as num?)?.toInt() ?? currentRound;

    final hostId = state['host_id']?.toString() ?? '';
    if (!isSpectator && hostId.isNotEmpty && playerId.isNotEmpty) {
      isHost = hostId == playerId;
    } else if (isSpectator) {
      isHost = false;
    }

    final started = state['started'] as bool? ?? false;
    if (started) {
      phase = RoomPhase.playing;
    } else if (roomCode.isEmpty) {
      phase = RoomPhase.initial;
    } else {
      phase = isHost ? RoomPhase.hostWaiting : RoomPhase.guestWaiting;
    }

    final rawPlayers = state['players'];
    players = _parsePlayers(rawPlayers, hostId);

    final rawSpectators = state['spectators'];
    spectators = _parseSpectators(rawSpectators);

    if (!isSpectator) {
      final me = players.where((p) => p.id == playerId);
      if (me.isNotEmpty) {
        final meRaw = _findPlayerRaw(rawPlayers, playerId);
        _syncDiceFromMe(meRaw);
        selectedPrediction = meRaw?['prediction']?.toString();
        predictionSubmitted = selectedPrediction != null;
        _myHasRolled = meRaw?['has_rolled'] as bool? ?? false;
        _mySubmittedCount = _countSubmittedCombinations(meRaw);
      }
    } else {
      _myDice = [];
      visibleDice = [];
      hiddenDice = [];
      selectedPrediction = null;
      predictionSubmitted = false;
      _myHasRolled = false;
      _mySubmittedCount = 0;
    }

    submittedPredictions = _countPredictions(rawPlayers);
    expectedPredictions = players.length;

    final rawPhase = state['current_phase']?.toString();
    gameTurnPhase = _mapServerPhaseToTurn(rawPhase);
    _currentPresentationStep = _presentationStep(rawPhase);
    _applyTurnFromServerState(state, rawPhase);

    if (_lastServerPhase != rawPhase) {
      _appendActivity('Fase: ${rawPhase ?? 'desconocida'}');
      _lastServerPhase = rawPhase;
    }

    totalScores = _parseTotalScores(rawPlayers);
    roundScores = _parseRoundScores(rawPlayers);

    final lastResult = state['last_result'];
    tieDetected = false;
    tieMessage = null;
    if (lastResult is Map) {
      tieDetected = lastResult['tie'] as bool? ?? false;
      if (tieDetected) {
        tieMessage = 'Empate tecnico detectado en presentacion actual.';
      }
    }

    final anyDisconnected = players.any((p) => !p.isConnected);
    if (anyDisconnected) {
      isRoundPaused = true;
      infoMessage = 'Hay jugadores desconectados. Esperando reconexion.';
    } else if (isRoundPaused) {
      isRoundPaused = false;
      infoMessage = 'Conexion restablecida. Ronda reanudada.';
    }

    if (gameTurnPhase == GameTurnPhase.finalResults) {
      phase = RoomPhase.playing;
    }
  }

  void _applyTurnFromServerState(Map<String, dynamic> state, String? rawPhase) {
    if (rawPhase == 'Presentation2' || rawPhase == 'Presentation3') {
      final order =
          (state['turn_order'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const <String>[];
      final turnIndex = (state['turn_index'] as num?)?.toInt() ?? 0;
      if (turnIndex >= 0 && turnIndex < order.length) {
        currentTurnPlayerId = order[turnIndex];
        return;
      }
    }
    currentTurnPlayerId = '';
  }

  List<PlayerModel> _parsePlayers(dynamic rawPlayers, String hostId) {
    if (rawPlayers is! List) {
      return players;
    }

    return rawPlayers.whereType<Map>().map((dynamic raw) {
      final map = raw.cast<String, dynamic>();
      final id = map['id']?.toString() ?? map['player_id']?.toString() ?? '';
      return PlayerModel(
        id: id,
        name:
            map['name']?.toString() ??
            map['player_name']?.toString() ??
            'Jugador',
        isReady: true,
        isHost: id == hostId,
        isConnected:
            map['connected'] as bool? ?? map['is_connected'] as bool? ?? true,
      );
    }).toList();
  }

  List<String> _parseSpectators(dynamic rawSpectators) {
    if (rawSpectators is! List) {
      return [];
    }

    return rawSpectators
        .whereType<Map>()
        .map((dynamic raw) {
          final map = raw.cast<String, dynamic>();
          return map['name']?.toString() ??
              map['spectator_name']?.toString() ??
              'Espectador';
        })
        .toList();
  }

  Map<String, dynamic>? _findPlayerRaw(dynamic rawPlayers, String id) {
    if (rawPlayers is! List) {
      return null;
    }

    for (final item in rawPlayers.whereType<Map>()) {
      final map = item.cast<String, dynamic>();
      final playerIdFromState =
          map['id']?.toString() ?? map['player_id']?.toString() ?? '';
      if (playerIdFromState == id) {
        return map;
      }
    }
    return null;
  }

  int _countSubmittedCombinations(Map<String, dynamic>? meRaw) {
    if (meRaw == null) {
      return 0;
    }

    final raw = meRaw['combinations_submitted'];
    if (raw is! List) {
      return 0;
    }
    return raw.length;
  }

  int _presentationStep(String? rawPhase) {
    switch (rawPhase) {
      case 'Presentation1':
        return 1;
      case 'Presentation2':
        return 2;
      case 'Presentation3':
        return 3;
      default:
        return 0;
    }
  }

  void _syncDiceFromMe(Map<String, dynamic>? meRaw) {
    _myDice = [];
    visibleDice = [];
    hiddenDice = [];

    final rawDice = meRaw?['dice'];
    if (rawDice is! List) {
      return;
    }

    for (final item in rawDice.whereType<Map>()) {
      final die = item.cast<String, dynamic>();
      final id = die['id']?.toString() ?? '';
      final value = (die['value'] as num?)?.toInt() ?? 0;
      final hidden = die['hidden'] as bool? ?? false;
      final used = die['used'] as bool? ?? false;

      if (id.isEmpty || value <= 0) {
        continue;
      }

      _myDice.add(
        _DieSnapshot(id: id, value: value, hidden: hidden, used: used),
      );
      if (hidden) {
        hiddenDice.add(value);
      } else {
        visibleDice.add(value);
      }
    }
  }

  int _countPredictions(dynamic rawPlayers) {
    if (rawPlayers is! List) {
      return submittedPredictions;
    }

    var count = 0;
    for (final item in rawPlayers.whereType<Map>()) {
      final map = item.cast<String, dynamic>();
      if (map['prediction'] != null) {
        count += 1;
      }
    }
    return count;
  }

  Map<String, int> _parseTotalScores(dynamic rawPlayers) {
    final totals = <String, int>{};
    if (rawPlayers is! List) {
      return totals;
    }

    for (final item in rawPlayers.whereType<Map>()) {
      final map = item.cast<String, dynamic>();
      final id = map['id']?.toString() ?? map['player_id']?.toString();
      final score = (map['score_total'] as num?)?.toDouble();
      if (id != null && score != null) {
        totals[id] = score.round();
      }
    }
    return totals;
  }

  List<RoundScoreModel> _parseRoundScores(dynamic rawPlayers) {
    if (rawPlayers is! List) {
      return const [];
    }

    return rawPlayers.whereType<Map>().map((dynamic raw) {
      final map = raw.cast<String, dynamic>();
      final id = map['id']?.toString() ?? map['player_id']?.toString() ?? '';
      final name =
          map['name']?.toString() ??
          map['player_name']?.toString() ??
          'Jugador';
      final scoreRound = (map['score_round'] as num?)?.toDouble() ?? 0;

      return RoundScoreModel(
        playerId: id,
        playerName: name,
        combination: 'Ronda',
        basePoints: scoreRound.round(),
        bonusPoints: 0,
      );
    }).toList();
  }

  GameTurnPhase _mapServerPhaseToTurn(String? rawPhase) {
    switch (rawPhase) {
      case 'RollingDice':
        return GameTurnPhase.rolling;
      case 'Prediction':
        return GameTurnPhase.predicting;
      case 'Presentation1':
      case 'Presentation2':
      case 'Presentation3':
        return GameTurnPhase.selecting;
      case 'RoundSummary':
        return GameTurnPhase.roundResults;
      case 'GameOver':
        return GameTurnPhase.finalResults;
      case 'WaitingPlayers':
      default:
        return GameTurnPhase.waiting;
    }
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
    isSpectator = false;
    errorMessage = null;
    supportErrorCode = null;
    _socket.sendMessage({'type': 'create_room', 'player_name': name});
    _appendActivity('Solicitud para crear sala enviada.');
    notifyListeners();
  }

  void joinRoom(String name, String code) {
    playerName = name;
    roomCode = code;
    isSpectator = false;
    errorMessage = null;
    supportErrorCode = null;
    _socket.sendMessage({
      'type': 'join_room',
      'player_name': name,
      'room_code': code,
    });
    _appendActivity('Intentando unirse a sala $code.');
    notifyListeners();
  }

  void joinAsSpectator(String name, String code) {
    playerName = name;
    roomCode = code;
    isHost = false;
    isSpectator = true;
    errorMessage = null;
    supportErrorCode = null;

    _socket.sendMessage({
      'type': 'join_as_spectator',
      'spectator_name': name,
      'room_code': code,
    });

    _appendActivity('Intentando unirse como espectador a sala $code.');
    notifyListeners();
  }

  void setReady() {
    if (isSpectator) {
      infoMessage = 'Modo espectador: esta opcion no esta disponible.';
      notifyListeners();
      return;
    }

    players = players
        .map((p) => p.id == playerId ? p.copyWith(isReady: true) : p)
        .toList();
    _appendActivity('Marcado como listo.');
    notifyListeners();
  }

  void startGame() {
    if (isSpectator) {
      infoMessage = 'Modo espectador: no puedes iniciar la partida.';
      notifyListeners();
      return;
    }

    _socket.sendMessage({
      'type': 'start_game',
      'room_code': roomCode,
      'player_id': playerId,
    });
    _appendActivity('Partida iniciada por host.');
  }

  void rollDice() {
    if (isSpectator) {
      infoMessage = 'Modo espectador: no puedes lanzar dados.';
      notifyListeners();
      return;
    }

    if (!canRollDice) {
      return;
    }
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
    if (isSpectator) {
      errorMessage = 'Modo espectador: no puedes enviar combinaciones.';
      supportErrorCode = 'SPEC-SUBMIT';
      notifyListeners();
      return;
    }

    if (!canPresentHand) {
      errorMessage = 'Aun no puedes presentar combinacion en esta fase.';
      supportErrorCode = 'PHASE-SUBMIT';
      notifyListeners();
      return;
    }

    selectedCombination = combination;

    final selectedIds = _pickDiceIdsForSelection(selectedDice);
    if (selectedIds.length != 3) {
      errorMessage = 'No se pudieron mapear 3 dados validos para enviar.';
      supportErrorCode = 'DICE-MAP';
      notifyListeners();
      return;
    }

    gameTurnPhase = GameTurnPhase.predicting;
    _socket.sendMessage({
      'type': 'submit_combination',
      'room_code': roomCode,
      'player_id': playerId,
      'dice_ids': selectedIds,
    });
    _appendActivity('Combinacion enviada: $combination.');
    notifyListeners();
  }

  List<String> _pickDiceIdsForSelection(List<int> selectedDice) {
    final ids = <String>[];
    final usedLocalIds = <String>{};

    for (final value in selectedDice) {
      _DieSnapshot? found;
      for (final die in _myDice) {
        if (die.used) {
          continue;
        }
        if (die.value == value && !usedLocalIds.contains(die.id)) {
          found = die;
          break;
        }
      }

      if (found != null) {
        ids.add(found.id);
        usedLocalIds.add(found.id);
      }
    }

    if (ids.length == 3) {
      return ids;
    }

    final fallback = _myDice
        .where((d) => !d.used)
        .take(3)
        .map((d) => d.id)
        .toList();
    return fallback;
  }

  void submitPrediction(String card) {
    if (isSpectator) {
      infoMessage = 'Modo espectador: no puedes enviar predicciones.';
      notifyListeners();
      return;
    }

    if (!canOpenPrediction || predictionSubmitted) {
      return;
    }
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
    });
    _appendActivity('Prediccion enviada: $card.');

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
    _appendActivity('Continuando luego de resumen de ronda.');
    notifyListeners();
  }

  void cancelRoom() {
    _appendActivity('Salida local de sala.');
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
    isSpectator = false;
    phase = RoomPhase.initial;
    players = [];
    spectators = [];
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
    _myDice = [];
    _lastServerPhase = null;
    _myHasRolled = false;
    _mySubmittedCount = 0;
    _currentPresentationStep = 0;
    notifyListeners();
  }

  void seedDemoDataForPreview() {
    playerName = 'Sebastian';
    playerId = 'p1';
    roomCode = 'A1B2C3';
    phase = RoomPhase.playing;
    isSpectator = false;
    players = const [
      PlayerModel(id: 'p1', name: 'Sebastian', isReady: true, isHost: true),
      PlayerModel(id: 'p2', name: 'Luis', isReady: true),
      PlayerModel(id: 'p3', name: 'Samiel', isReady: true),
    ];
    spectators = const ['Observador 1', 'Observador 2'];
    visibleDice = [1, 3, 5, 2, 6];
    hiddenDice = [4, 2, 6];
    _myDice = const [
      _DieSnapshot(id: 'w1', value: 1, hidden: false, used: false),
      _DieSnapshot(id: 'w2', value: 3, hidden: false, used: false),
      _DieSnapshot(id: 'w3', value: 5, hidden: false, used: false),
      _DieSnapshot(id: 'r1', value: 4, hidden: true, used: false),
      _DieSnapshot(id: 'b1', value: 2, hidden: true, used: false),
    ];
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

class _DieSnapshot {
  final String id;
  final int value;
  final bool hidden;
  final bool used;

  const _DieSnapshot({
    required this.id,
    required this.value,
    required this.hidden,
    required this.used,
  });
}