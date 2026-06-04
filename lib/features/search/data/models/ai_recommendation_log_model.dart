import '../../../../core/models/model_converters.dart';

class AiRecommendationLogModel {
  const AiRecommendationLogModel({
    required this.id,
    required this.recommendationType,
    required this.recommendedIds,
    this.userId,
    this.sessionId,
    this.context = const {},
    this.clickedId,
    this.converted = false,
    this.modelVersion,
    this.score,
    this.createdAt,
  });

  final String id;
  final String? userId;
  final String? sessionId;
  final String recommendationType;
  final Map<String, dynamic> context;
  final List<String> recommendedIds;
  final String? clickedId;
  final bool converted;
  final String? modelVersion;
  final double? score;
  final DateTime? createdAt;

  factory AiRecommendationLogModel.fromJson(Map<String, dynamic> json) {
    return AiRecommendationLogModel(
      id: json['id'].toString(),
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String?,
      recommendationType: json['recommendation_type'].toString(),
      context: mapFromJson(json['context']),
      recommendedIds: stringListFromJson(json['recommended_ids']),
      clickedId: json['clicked_id'] as String?,
      converted: json['converted'] as bool? ?? false,
      modelVersion: json['model_version'] as String?,
      score: doubleFromJson(json['score']),
      createdAt: dateTimeFromJson(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'session_id': sessionId,
    'recommendation_type': recommendationType,
    'context': context,
    'recommended_ids': recommendedIds,
    'clicked_id': clickedId,
    'converted': converted,
    'model_version': modelVersion,
    'score': score,
    'created_at': dateTimeToJson(createdAt),
  };
}
