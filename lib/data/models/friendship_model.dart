import 'user_model.dart';

enum FriendshipStatus { pending, accepted, declined }

extension FriendshipStatusExtension on FriendshipStatus {
  String get value {
    switch (this) {
      case FriendshipStatus.pending:  return 'pending';
      case FriendshipStatus.accepted: return 'accepted';
      case FriendshipStatus.declined: return 'declined';
    }
  }

  static FriendshipStatus fromString(String? value) {
    switch (value) {
      case 'accepted': return FriendshipStatus.accepted;
      case 'declined': return FriendshipStatus.declined;
      default:         return FriendshipStatus.pending;
    }
  }
}

class FriendshipModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Populated joins
  final UserModel? requester;
  final UserModel? receiver;

  FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.requester,
    this.receiver,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      receiverId: json['receiver_id'] as String,
      status: FriendshipStatusExtension.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      requester: json['requester'] != null
          ? UserModel.fromJson(json['requester'] as Map<String, dynamic>)
          : null,
      receiver: json['receiver'] != null
          ? UserModel.fromJson(json['receiver'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'requester_id': requesterId,
        'receiver_id': receiverId,
        'status': status.value,
        'created_at': createdAt.toIso8601String(),
      };
}
