class PlayerModel {
  final String id;
  final String name;
  final bool isReady;
  final bool isHost;
  final bool isConnected;

  const PlayerModel({
    required this.id,
    required this.name,
    this.isReady = false,
    this.isHost = false,
    this.isConnected = true,
  });

  PlayerModel copyWith({
    String? name,
    bool? isReady,
    bool? isHost,
    bool? isConnected,
  }) {
    return PlayerModel(
      id: id,
      name: name ?? this.name,
      isReady: isReady ?? this.isReady,
      isHost: isHost ?? this.isHost,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
