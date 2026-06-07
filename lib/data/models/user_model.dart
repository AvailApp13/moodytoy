import 'package:get/get.dart';
import 'package:flutter/material.dart';

enum Mood { coffee, gamer, dating, walk, sport }

extension MoodExtension on Mood {
  String get label {
    switch (this) {
      case Mood.coffee: return 'mood_coffee'.tr;
      case Mood.gamer:  return 'mood_gamer'.tr;
      case Mood.dating: return 'mood_dating'.tr;
      case Mood.walk:   return 'mood_walk'.tr;
      case Mood.sport:  return 'mood_sport'.tr;
    }
  }

  String get value {
    switch (this) {
      case Mood.coffee: return 'coffee';
      case Mood.gamer:  return 'gamer';
      case Mood.dating: return 'dating';
      case Mood.walk:   return 'walk';
      case Mood.sport:  return 'sport';
    }
  }

  Color get color {
    switch (this) {
      case Mood.coffee: return const Color(0xFF6F4E37);
      case Mood.gamer:  return const Color(0xFF4CAF50);
      case Mood.dating: return const Color(0xFFFF6B6B);
      case Mood.walk:   return const Color(0xFF4A90E2);
      case Mood.sport:  return const Color(0xFFFF9800);
    }
  }

  String get emoji {
    switch (this) {
      case Mood.coffee: return '☕';
      case Mood.gamer:  return '🎮';
      case Mood.dating: return '💕';
      case Mood.walk:   return '🚶';
      case Mood.sport:  return '⚡';
    }
  }

  static Mood fromString(String? value) {
    switch (value) {
      case 'coffee': return Mood.coffee;
      case 'gamer':  return Mood.gamer;
      case 'dating': return Mood.dating;
      case 'walk':   return Mood.walk;
      case 'sport':  return Mood.sport;
      default:       return Mood.coffee;
    }
  }
}

class UserModel {
  final String id;
  final String? userId;
  final String name;
  final DateTime? birthDate;
  final String? bio;
  final String? city;
  final String? avatarUrl;
  final List<String> photos;
  final String? avatarEmoji;
  final Mood? mood;
  final bool locationEnabled;
  final double? lat;
  final double? lng;
  double? distanceMeters;

  UserModel({
    required this.id,
    this.userId,
    required this.name,
    this.birthDate,
    this.bio,
    this.city,
    this.avatarUrl,
    this.photos = const [],
    this.avatarEmoji,
    this.mood,
    this.locationEnabled = true,
    this.lat,
    this.lng,
    this.distanceMeters,
  });

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int a = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) a--;
    return a;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'birth_date': birthDate?.toIso8601String(),
    'bio': bio,
    'city': city,
    'avatar_url': avatarUrl,
    'photos': photos,
    'avatar_emoji': avatarEmoji,
    'mood': mood?.value,
    'location_enabled': locationEnabled,
    'lat': lat,
    'lng': lng,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    userId: json['user_id'],
    name: json['name'] ?? '',
    birthDate: json['birth_date'] != null
        ? DateTime.tryParse(json['birth_date'].toString())
        : (json['birthDate'] != null ? DateTime.tryParse(json['birthDate'].toString()) : null),
    bio: json['bio'],
    city: json['city'],
    avatarUrl: json['avatar_url'] ?? json['avatarUrl'],
    photos: List<String>.from(json['photos'] ?? []),
    avatarEmoji: json['avatar_emoji'] ?? json['avatarEmoji'] ?? '😊',
    mood: MoodExtension.fromString(json['mood']),
    locationEnabled: json['location_enabled'] ?? json['locationEnabled'] ?? true,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );

  UserModel copyWith({
    String? userId,
    String? name, DateTime? birthDate, String? bio, String? city,
    String? avatarUrl, List<String>? photos, String? avatarEmoji,
    Mood? mood, bool? locationEnabled, double? lat, double? lng,
    double? distanceMeters,
  }) => UserModel(
    id: id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    bio: bio ?? this.bio,
    city: city ?? this.city,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    photos: photos ?? this.photos,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    mood: mood ?? this.mood,
    locationEnabled: locationEnabled ?? this.locationEnabled,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    distanceMeters: distanceMeters ?? this.distanceMeters,
  );
}
