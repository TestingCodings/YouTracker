import 'package:hive/hive.dart';

part 'interaction.g.dart';

@HiveType(typeId: 1)
enum InteractionType {
  @HiveField(0)
  like,

  @HiveField(1)
  reply,

  @HiveField(2)
  mention,

  @HiveField(3)
  heart,
}

@HiveType(typeId: 2)
class Interaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String commentId;

  @HiveField(2)
  final InteractionType type;

  @HiveField(3)
  final String? fromUserId;

  @HiveField(4)
  final String? fromUserName;

  @HiveField(5)
  final String? fromUserProfileImageUrl;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final String? replyText;

  @HiveField(8)
  final bool isRead;

  Interaction({
    required this.id,
    required this.commentId,
    required this.type,
    this.fromUserId,
    this.fromUserName,
    this.fromUserProfileImageUrl,
    required this.timestamp,
    this.replyText,
    this.isRead = false,
  });

  Interaction copyWith({
    String? id,
    String? commentId,
    InteractionType? type,
    String? fromUserId,
    String? fromUserName,
    String? fromUserProfileImageUrl,
    DateTime? timestamp,
    String? replyText,
    bool? isRead,
  }) {
    return Interaction(
      id: id ?? this.id,
      commentId: commentId ?? this.commentId,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserProfileImageUrl:
          fromUserProfileImageUrl ?? this.fromUserProfileImageUrl,
      timestamp: timestamp ?? this.timestamp,
      replyText: replyText ?? this.replyText,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commentId': commentId,
      'type': type.name,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserProfileImageUrl': fromUserProfileImageUrl,
      'timestamp': timestamp.toIso8601String(),
      'replyText': replyText,
      'isRead': isRead,
    };
  }

  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      id: json['id'] as String,
      commentId: json['commentId'] as String,
      type: InteractionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InteractionType.like,
      ),
      fromUserId: json['fromUserId'] as String?,
      fromUserName: json['fromUserName'] as String?,
      fromUserProfileImageUrl: json['fromUserProfileImageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      replyText: json['replyText'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  String get displayText {
    switch (type) {
      case InteractionType.like:
        return '$fromUserName liked your comment';
      case InteractionType.reply:
        return '$fromUserName replied to your comment';
      case InteractionType.mention:
        return '$fromUserName mentioned you';
      case InteractionType.heart:
        return 'The creator hearted your comment';
    }
  }

  @override
  String toString() {
    return 'Interaction(id: $id, type: $type, commentId: $commentId)';
  }
}
