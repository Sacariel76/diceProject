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
  static const String _codeConnInit = 'CONN-INIT';
  static const String _codeConnClosed = 'CONN-CLOSED';
  static const String _codeConnStream = 'CONN-STREAM';
  static const String _codeConnCritical = 'CONN-CRITICAL';
  static const String _codeWsError = 'WS-ERROR';
  static const int maxRoomPlayers = 5;

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
  List<PlayerVisibleDice> tableVisibleDice = [];
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
  Map<String, int> playerPresentationCounts = {};
  bool isInitializationComplete = false;
  bool isRoundPaused = false;
  String? supportErrorCode;
  List<String> activityFeed = [];

  String _lastCapacityCheckedRoomCode = '';
  int? _lastCapacityCheckedPlayers;
  bool _isCheckingRoomCapacity = false;
  Timer? _roomCapacityTimeout;
  bool _awaitingPlayerJoinValidation = false;
  String _pendingPlayerJoinCode = '';

  List<_DieSnapshot> _myDice = [];
  String? _lastServerPhase;
  bool _myHasRolled = false;
  int _mySubmittedCount = 0;
  int _currentPresentationStep = 0;

  bool get isConnected => _socket.isConnected;
  bool get allPlayersReady => players.length >= 2;
  bool get isCheckingRoomCapacity => _isCheckingRoomCapacity;
  int get currentPresentationStep => _currentPresentationStep;
  bool get shouldUseSpectatorViews {
    if (isSpectator) {
      return true;
    }

    if (playerId.isEmpty || players.isEmpty) {
      return false;
    }

    return !players.any((p) => p.id == playerId);
  }

  int? roomPlayerCountForCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || normalized != _lastCapacityCheckedRoomCode) {
      return null;
    }
    return _lastCapacityCheckedPlayers;
  }

  bool isRoomFullForCode(String code) {
    final count = roomPlayerCountForCode(code);
    if (count == null) {
      return false;
    }
    return count >= maxRoomPlayers;
  }

  bool canJoinTableForCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != 6) {
      return false;
    }
    return !isRoomFullForCode(normalized);
  }

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

  bool get isReadOnlyViewer => shouldUseSpectatorViews;

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

  String getDieColorByIndex(int index) {
  if (index < 0 || index >= _myDice.length) {
    return 'white';
  }

  final die = _myDice[index];

  if (die.hidden) {
    // ocultos: rojo y azul
    if (die.id.startsWith('r')) return 'red';
    if (die.id.startsWith('b')) return 'blue';
  }

  return 'white';
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
      supportErrorCode = _codeConnInit;
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
    if (phase == RoomPhase.playing) {
      connectionStatus = ConnectionStatus.critical;
      errorMessage =
          'La conexion se cerro durante la partida activa. Reintenta o sal de forma segura.';
      supportErrorCode = _codeConnCritical;
      isRoundPaused = true;
      _appendActivity('Desconexion critica detectada en partida activa.');
    } else {
      connectionStatus = ConnectionStatus.disconnected;
      errorMessage = 'Conexion cerrada por el servidor.';
      supportErrorCode = _codeConnClosed;
    }
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
        playerPresentationCounts = {};
        errorMessage = null;
        supportErrorCode = null;
        _appendActivity('Sala creada: $roomCode');
        break;

      case 'room_joined':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['player_id']?.toString() ?? playerId;
        isHost = false;
        isSpectator = false;
        phase = RoomPhase.initial;
        _isCheckingRoomCapacity = false;
        _roomCapacityTimeout?.cancel();
        _roomCapacityTimeout = null;
        _lastCapacityCheckedRoomCode = roomCode.trim().toUpperCase();
        _pendingPlayerJoinCode = _lastCapacityCheckedRoomCode;
        _awaitingPlayerJoinValidation = true;
        playerPresentationCounts = {};
        errorMessage = null;
        supportErrorCode = null;
        _appendActivity('Ingreso recibido en sala: $roomCode. Validando cupo...');
        break;

      case 'spectator_joined':
        roomCode = data['room_code']?.toString() ?? roomCode;
        playerId = data['spectator_id']?.toString() ?? playerId;
        isHost = false;
        isSpectator = true;
        phase = RoomPhase.guestWaiting;
        _awaitingPlayerJoinValidation = false;
        _pendingPlayerJoinCode = '';
        _isCheckingRoomCapacity = false;
        _roomCapacityTimeout?.cancel();
        _roomCapacityTimeout = null;
        _lastCapacityCheckedRoomCode = roomCode.trim().toUpperCase();
        playerPresentationCounts = {};
        errorMessage = null;
        supportErrorCode = null;
        _appendActivity('Ingreso como espectador a sala: $roomCode');
        _appendActivity('Modo espectador activado');
        break;

      case 'join_failed':
        _awaitingPlayerJoinValidation = false;
        _pendingPlayerJoinCode = '';
        errorMessage =
            data['message']?.toString() ?? 'No fue posible unirse a la sala.';
        supportErrorCode = _extractSupportCode(data);
        _syncRoomCapacitySnapshot(data);
        if (supportErrorCode == 'ROOM-FULL' &&
            _lastCapacityCheckedPlayers == null) {
          _lastCapacityCheckedPlayers = maxRoomPlayers;
          final failedCode =
              data['room_code']?.toString().trim().toUpperCase() ??
              roomCode.trim().toUpperCase();
          if (failedCode.isNotEmpty) {
            _lastCapacityCheckedRoomCode = failedCode;
          }
        }
        _appendActivity(errorMessage ?? 'No fue posible unirse a la sala.');
        break;

      case 'room_status':
      case 'room_info':
      case 'room_snapshot':
        final rawState = data['state'];
        if (rawState is Map) {
          _syncRoomCapacitySnapshot(rawState.cast<String, dynamic>());
        } else {
          _syncRoomCapacitySnapshot(data);
        }
        break;

      case 'state_update':
        final rawState = data['state'];
        if (rawState is Map) {
          _handleServerState(rawState.cast<String, dynamic>());
        }
        break;

      case 'error':
        errorMessage = data['message']?.toString() ?? 'Error desconocido.';
        supportErrorCode = _extractSupportCode(data);
        if (_isCheckingRoomCapacity) {
          _syncRoomCapacitySnapshot(data);
          if (supportErrorCode == 'ROOM-FULL' &&
              _lastCapacityCheckedPlayers == null) {
            _lastCapacityCheckedPlayers = maxRoomPlayers;
          }
        }
        if (_isCriticalServerError(data)) {
          connectionStatus = ConnectionStatus.critical;
          isRoundPaused = true;
        }
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
    tableVisibleDice = _parseTableVisibleDice(rawPlayers);

    _syncRoomCapacitySnapshot(state, stopChecking: false);

    final normalizedStateRoom = roomCode.trim().toUpperCase();
    if (_awaitingPlayerJoinValidation && !isSpectator) {
      final samePendingRoom =
          _pendingPlayerJoinCode.isEmpty ||
          _pendingPlayerJoinCode == normalizedStateRoom;
      if (samePendingRoom) {
        if (players.length > maxRoomPlayers) {
          _rejectJoinBecauseRoomIsFull(normalizedStateRoom, players.length);
          return;
        }
        _awaitingPlayerJoinValidation = false;
        _pendingPlayerJoinCode = '';
        _appendActivity('Ingreso validado: cupo disponible en sala $roomCode.');
      }
    }

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

    final rawPhase = _extractRawPhase(state);
    gameTurnPhase = _mapServerPhaseToTurn(rawPhase);
    _currentPresentationStep = _presentationStep(rawPhase, state);
    playerPresentationCounts = _parseSubmittedCombinationsByPlayer(rawPlayers);
    _applyTurnFromServerState(state, rawPhase);

    if (_lastServerPhase != rawPhase) {
      _appendActivity('Fase: ${rawPhase ?? 'desconocida'}');
      _lastServerPhase = rawPhase;
    }

    final lastResult = state['last_result'];
    totalScores = _parseTotalScores(rawPlayers);
    roundScores = _parseRoundScores(rawPlayers, lastResult);

    tieDetected = false;
    tieMessage = null;
    if (lastResult is Map) {
      tieDetected = lastResult['tie'] as bool? ?? false;
      if (tieDetected) {
        tieMessage =
            lastResult['tie_message']?.toString() ??
            lastResult['tie_reason']?.toString() ??
            'Empate tecnico detectado en presentacion actual.';
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
    final normalized = _normalizePhaseToken(rawPhase);
    if (!normalized.startsWith('presentation')) {
      currentTurnPlayerId = '';
      return;
    }

    final order =
        (state['turn_order'] as List?)
            ?.map((e) => e.toString())
            .toList(growable: false) ??
        const <String>[];
    final turnIndex = (state['turn_index'] as num?)?.toInt();
    if (turnIndex != null && turnIndex >= 0 && turnIndex < order.length) {
      currentTurnPlayerId = order[turnIndex];
      return;
    }

    final directTurnPlayerId =
        state['current_turn_player_id']?.toString() ??
        state['current_player_id']?.toString() ??
        '';
    if (directTurnPlayerId.isNotEmpty) {
      currentTurnPlayerId = directTurnPlayerId;
      return;
    }

    currentTurnPlayerId = '';
  }

  String? _extractRawPhase(Map<String, dynamic> state) {
    final raw =
        state['current_phase'] ??
        state['phase'] ??
        state['turn_phase'] ??
        state['game_phase'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String _normalizePhaseToken(String? rawPhase) {
    if (rawPhase == null) {
      return '';
    }

    return rawPhase
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  Map<String, int> _parseSubmittedCombinationsByPlayer(dynamic rawPlayers) {
    if (rawPlayers is! List) {
      return const <String, int>{};
    }

    final counts = <String, int>{};
    for (final item in rawPlayers.whereType<Map>()) {
      final map = item.cast<String, dynamic>();
      final id = map['id']?.toString() ?? map['player_id']?.toString() ?? '';
      if (id.isEmpty) {
        continue;
      }

      final raw = map['combinations_submitted'];
      if (raw is List) {
        counts[id] = raw.length;
      } else {
        counts[id] = 0;
      }
    }
    return counts;
  }

  int _presentationStep(String? rawPhase, Map<String, dynamic> state) {
    final normalized = _normalizePhaseToken(rawPhase);

    if (normalized == 'presentation1') {
      return 1;
    }
    if (normalized == 'presentation2') {
      return 2;
    }
    if (normalized == 'presentation3') {
      return 3;
    }
    if (normalized == 'presentation') {
      final turnIndex = (state['turn_index'] as num?)?.toInt();
      if (turnIndex == null) {
        return 1;
      }
      final step = turnIndex + 1;
      if (step < 1) {
        return 1;
      }
      if (step > 3) {
        return 3;
      }
      return step;
    }

    final fallbackMatch = RegExp(r'^presentation(\d+)$').firstMatch(normalized);
    if (fallbackMatch != null) {
      final parsed = int.tryParse(fallbackMatch.group(1)!);
      if (parsed == null) {
        return 0;
      }
      if (parsed < 1) {
        return 1;
      }
      if (parsed > 3) {
        return 3;
      }
      return parsed;
    }

    return 0;
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

  List<PlayerVisibleDice> _parseTableVisibleDice(dynamic rawPlayers) {
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

    final rawDice = map['dice'];
    final whiteDice = <int>[];

    if (rawDice is List) {
      for (final item in rawDice.whereType<Map>()) {
        final die = item.cast<String, dynamic>();
        final color = die['color']?.toString() ?? '';
        final hidden = die['hidden'] as bool? ?? false;
        final value = (die['value'] as num?)?.toInt() ?? 0;

        if (color == 'white' && !hidden && value > 0) {
          whiteDice.add(value);
        }
      }
    }

    return PlayerVisibleDice(
      playerId: id,
      playerName: name,
      whiteDice: whiteDice,
    );
  }).toList();
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

  List<RoundScoreModel> _parseRoundScores(
    dynamic rawPlayers,
    dynamic lastResult,
  ) {
    final fromLastResult = _parseRoundScoresFromLastResult(lastResult);
    if (fromLastResult.isNotEmpty) {
      return fromLastResult;
    }

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

  List<RoundScoreModel> _parseRoundScoresFromLastResult(dynamic lastResult) {
    if (lastResult is! Map) {
      return const [];
    }

    final map = lastResult.cast<String, dynamic>();
    final candidates = [
      map['round_scores'],
      map['scores'],
      map['results'],
      map['player_results'],
    ];

    for (final candidate in candidates) {
      if (candidate is! List) {
        continue;
      }

      final parsed = candidate
          .whereType<Map>()
          .map((dynamic raw) {
            final row = raw.cast<String, dynamic>();
            final id =
                row['player_id']?.toString() ?? row['id']?.toString() ?? '';
            final name =
                row['player_name']?.toString() ??
                row['name']?.toString() ??
                'Jugador';
            final combination =
                row['combination']?.toString() ??
                row['hand']?.toString() ??
                row['rank']?.toString() ??
                'Ronda';

            final base =
                (row['base_points'] as num?)?.toInt() ??
                (row['score_base'] as num?)?.toInt() ??
                (row['score_round'] as num?)?.toInt() ??
                0;
            final bonus =
                (row['bonus_points'] as num?)?.toInt() ??
                (row['prediction_bonus'] as num?)?.toInt() ??
                0;
            final total =
                (row['total_points'] as num?)?.toInt() ??
                (row['score_total'] as num?)?.toInt();

            final normalizedBase = total != null ? total - bonus : base;

            return RoundScoreModel(
              playerId: id,
              playerName: name,
              combination: combination,
              basePoints: normalizedBase,
              bonusPoints: bonus,
            );
          })
          .toList(growable: false);

      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    return const [];
  }

  GameTurnPhase _mapServerPhaseToTurn(String? rawPhase) {
    final normalized = _normalizePhaseToken(rawPhase);

    switch (normalized) {
      case 'rollingdice':
        return GameTurnPhase.rolling;
      case 'prediction':
        return GameTurnPhase.predicting;
      case 'presentation':
      case 'presentation1':
      case 'presentation2':
      case 'presentation3':
        return GameTurnPhase.selecting;
      case 'roundsummary':
        return GameTurnPhase.roundResults;
      case 'gameover':
        return GameTurnPhase.finalResults;
      case 'waitingplayers':
      default:
        if (normalized.startsWith('presentation')) {
          return GameTurnPhase.selecting;
        }
        return GameTurnPhase.waiting;
    }
  }

  void _handleError(dynamic error) {
    if (phase == RoomPhase.playing) {
      connectionStatus = ConnectionStatus.critical;
      errorMessage = 'Error de conexion en partida activa: $error';
      supportErrorCode = _codeConnCritical;
      isRoundPaused = true;
      _appendActivity('Error critico de conexion en partida activa.');
    } else {
      connectionStatus = ConnectionStatus.disconnected;
      errorMessage = 'Error de conexion: $error';
      supportErrorCode = _codeConnStream;
      _appendActivity('Error de conexion detectado.');
    }
    notifyListeners();
  }

  bool _isCriticalServerError(Map<String, dynamic> data) {
    final criticalFlag = data['critical'] as bool? ?? false;
    if (criticalFlag) {
      return true;
    }

    final code =
        data['code']?.toString().trim().toUpperCase() ??
        data['error_code']?.toString().trim().toUpperCase() ??
        '';
    if (code.startsWith('CRITICAL') ||
        code == 'SESSION-LOST' ||
        code == 'ROOM-CLOSED') {
      return true;
    }

    final msg = (data['message']?.toString() ?? '').toLowerCase();
    return msg.contains('session lost') ||
        msg.contains('sesion perdida') ||
        msg.contains('room closed') ||
        msg.contains('sala cerrada');
  }

  String _extractSupportCode(Map<String, dynamic> data) {
    final directCode =
        data['code']?.toString().trim().toUpperCase() ??
        data['error_code']?.toString().trim().toUpperCase() ??
        '';
    if (directCode.isNotEmpty) {
      return directCode;
    }

    final msg = (data['message']?.toString() ?? '').toLowerCase();
    if ((msg.contains('unknown variant') && msg.contains('room_status')) ||
        (msg.contains('expected one of') && msg.contains('join_room'))) {
      return 'ROOM-CHECK-UNSUPPORTED';
    }
    if ((msg.contains('room') && msg.contains('full')) ||
        msg.contains('sala llena') ||
        msg.contains('cupo lleno') ||
        msg.contains('aforo completo') ||
        (msg.contains('maximo') && msg.contains('jugador')) ||
        msg.contains('capacity')) {
      return 'ROOM-FULL';
    }
    if (msg.contains('room') &&
        (msg.contains('invalid') ||
            msg.contains('invalido') ||
            msg.contains('not found') ||
            msg.contains('no existe'))) {
      return 'ROOM-NOT-FOUND';
    }
    if (msg.contains('prediction') || msg.contains('predic')) {
      return 'PREDICTION-INVALID';
    }
    if (msg.contains('combination') || msg.contains('combinacion')) {
      return 'COMBINATION-INVALID';
    }
    if (msg.contains('dice') || msg.contains('dado')) {
      return 'DICE-INVALID';
    }
    if (msg.contains('turn') || msg.contains('turno')) {
      return 'TURN-NOT-ALLOWED';
    }
    if (msg.contains('phase') || msg.contains('fase')) {
      return 'PHASE-INVALID';
    }
    return _codeWsError;
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
    _awaitingPlayerJoinValidation = false;
    _pendingPlayerJoinCode = '';
    errorMessage = null;
    supportErrorCode = null;
    _socket.sendMessage({'type': 'create_room', 'player_name': name});
    _appendActivity('Solicitud para crear sala enviada.');
    notifyListeners();
  }

  void checkRoomCapacity(String code) {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.length != 6) {
      resetRoomCapacityProbe();
      return;
    }

    _lastCapacityCheckedRoomCode = normalizedCode;
    _isCheckingRoomCapacity = false;
    _roomCapacityTimeout?.cancel();
    _roomCapacityTimeout = null;
  }

  void resetRoomCapacityProbe() {
    final hadValue =
        _isCheckingRoomCapacity || _lastCapacityCheckedPlayers != null;
    _isCheckingRoomCapacity = false;
    _lastCapacityCheckedPlayers = null;
    _roomCapacityTimeout?.cancel();
    _roomCapacityTimeout = null;
    if (hadValue) {
      notifyListeners();
    }
  }

  void joinRoom(String name, String code) {
    final normalizedCode = code.trim().toUpperCase();
    playerName = name;
    roomCode = normalizedCode;
    isSpectator = false;
    _awaitingPlayerJoinValidation = true;
    _pendingPlayerJoinCode = normalizedCode;
    _isCheckingRoomCapacity = false;
    _roomCapacityTimeout?.cancel();
    _roomCapacityTimeout = null;
    errorMessage = null;
    supportErrorCode = null;
    _socket.sendMessage({
      'type': 'join_room',
      'player_name': name,
      'room_code': normalizedCode,
    });
    _appendActivity('Intentando unirse a sala $normalizedCode.');
    notifyListeners();
  }

  void joinAsSpectator(String name, String code) {
    final normalizedCode = code.trim().toUpperCase();
    playerName = name;
    roomCode = normalizedCode;
    isHost = false;
    isSpectator = true;
    _awaitingPlayerJoinValidation = false;
    _pendingPlayerJoinCode = '';
    _isCheckingRoomCapacity = false;
    _roomCapacityTimeout?.cancel();
    _roomCapacityTimeout = null;
    errorMessage = null;
    supportErrorCode = null;

    _socket.sendMessage({
      'type': 'join_as_spectator',
      'spectator_name': name,
      'room_code': normalizedCode,
    });

    _appendActivity('Intentando unirse como espectador a sala $normalizedCode.');
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

    final normalizedCard = card.trim().toUpperCase();

    selectedPrediction = normalizedCard;
    predictionSubmitted = true;

    if (expectedPredictions == 0 && players.isNotEmpty) {
      expectedPredictions = players.length;
    }

    _socket.sendMessage({
      'type': 'select_prediction',
      'room_code': roomCode,
      'player_id': playerId,
      'prediction': normalizedCard,
    });
    _appendActivity('Prediccion enviada: $normalizedCard.');

    notifyListeners();
  }

  void setPredictionDraft(String card) {
    selectedPrediction = card.trim().toUpperCase();
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
    playerPresentationCounts = {};
    isRoundPaused = false;
    supportErrorCode = null;
    activityFeed = [];
    _lastCapacityCheckedRoomCode = '';
    _lastCapacityCheckedPlayers = null;
    _isCheckingRoomCapacity = false;
    _roomCapacityTimeout?.cancel();
    _roomCapacityTimeout = null;
    _awaitingPlayerJoinValidation = false;
    _pendingPlayerJoinCode = '';
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
    _currentPresentationStep = 2;
    totalScores = {'p1': 12, 'p2': 9, 'p3': 7};
    playerPresentationCounts = {'p1': 1, 'p2': 1, 'p3': 0};
    selectedCombination = 'Escalera';
    selectedPrediction = 'MORE';
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
      'Prediccion enviada: MORE.',
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

  void seedCriticalDisconnectPreview() {
    phase = RoomPhase.playing;
    connectionStatus = ConnectionStatus.critical;
    errorMessage =
        'Desconexion critica simulada: la sesion activa no se puede mantener sin reintento.';
    supportErrorCode = _codeConnCritical;
    isRoundPaused = true;
    infoMessage = 'Se activo un escenario de desconexion critica para QA.';
    _appendActivity('Escenario QA: desconexion critica simulada.');
    notifyListeners();
  }

  @override
  void dispose() {
    _roomCapacityTimeout?.cancel();
    _socketSub?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  void _syncRoomCapacitySnapshot(
    Map<String, dynamic> payload, {
    bool stopChecking = true,
  }) {
    final snapshotCode = payload['room_code']?.toString().trim().toUpperCase();
    if (snapshotCode != null && snapshotCode.isNotEmpty) {
      _lastCapacityCheckedRoomCode = snapshotCode;
    }

    final rawPlayers = payload['players'];
    int? playersCount;
    if (rawPlayers is List) {
      playersCount = rawPlayers.whereType<Map>().length;
    }

    playersCount ??= (payload['players_count'] as num?)?.toInt();
    playersCount ??= (payload['player_count'] as num?)?.toInt();
    playersCount ??= (payload['current_players'] as num?)?.toInt();

    if (playersCount != null) {
      _lastCapacityCheckedPlayers = playersCount;
    }

    if (stopChecking) {
      _isCheckingRoomCapacity = false;
      _roomCapacityTimeout?.cancel();
      _roomCapacityTimeout = null;
    }
  }

  void _rejectJoinBecauseRoomIsFull(String normalizedRoomCode, int playersCount) {
    _awaitingPlayerJoinValidation = false;
    _pendingPlayerJoinCode = '';
    _lastCapacityCheckedRoomCode = normalizedRoomCode;
    _lastCapacityCheckedPlayers = playersCount;

    roomCode = normalizedRoomCode;
    playerId = '';
    isHost = false;
    isSpectator = false;
    phase = RoomPhase.initial;
    players = const [];
    spectators = const [];
    errorMessage =
        'La sala ya alcanzo su limite de $maxRoomPlayers jugadores (incluyendo host). Entra en modo espectador.';
    supportErrorCode = 'ROOM-FULL';
    _appendActivity('Ingreso bloqueado: sala $normalizedRoomCode llena ($playersCount/$maxRoomPlayers).');

    // Reinicia la sesion de socket para no mantener una afiliacion invalida de sala.
    _socketSub?.cancel();
    _socket.disconnect();
    _connectSocket();
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

class PlayerVisibleDice {
  final String playerId;
  final String playerName;
  final List<int> whiteDice;

  const PlayerVisibleDice({
    required this.playerId,
    required this.playerName,
    required this.whiteDice,
  });
}