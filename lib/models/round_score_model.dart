class RoundScoreModel {
  final String playerId;
  final String playerName;
  final String combination;
  final int basePoints;
  final int bonusPoints;

  const RoundScoreModel({
    required this.playerId,
    required this.playerName,
    required this.combination,
    required this.basePoints,
    required this.bonusPoints,
  });

  int get totalPoints => basePoints + bonusPoints;

  factory RoundScoreModel.fromJson(Map<String, dynamic> json) {
    return RoundScoreModel(
      playerId: json['player_id']?.toString() ?? '',
      playerName: json['player_name']?.toString() ?? 'Jugador',
      combination: json['combination']?.toString() ?? 'Sencillo',
      basePoints: (json['base_points'] as num?)?.toInt() ?? 0,
      bonusPoints: (json['bonus_points'] as num?)?.toInt() ?? 0,
    );
  }
}
