import 'package:flutter/material.dart';

enum Mood { coffee, gamer, dating, walk, sport }

extension MoodExtension on Mood {
  String get label {
    switch (this) {
      case Mood.coffee: return 'Кофе-брейк';
      case Mood.gamer:  return 'Игрок';
      case Mood.dating: return 'Знакомство';
      case Mood.walk:   return 'Прогулка';
      case Mood.sport:  return 'Спорт/активность';
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
  final String name;
  final DateTime? birthDate;
  final String? bio;
  final String? city;
  final List<String> photos;
  final String? avatarEmoji;
  final Mood? mood;
  final bool locationEnabled;
  final double? lat;
  final double? lng;
  double? distanceMeters;

  UserModel({
    required this.id,
    required this.name,
    this.birthDate,
    this.bio,
    this.city,
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
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  bool get isOnMap => locationEnabled && lat != null && lng != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthDate': birthDate?.toIso8601String(),
    'bio': bio,
    'city': city,
    'photos': photos,
    'avatarEmoji': avatarEmoji,
    'mood': mood?.value,
    'locationEnabled': locationEnabled,
    'lat': lat,
    'lng': lng,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    birthDate: json['birthDate'] != null
        ? DateTime.tryParse(json['birthDate'])
        : null,
    bio: json['bio'],
    city: json['city'],
    photos: List<String>.from(json['photos'] ?? []),
    avatarEmoji: json['avatarEmoji'],
    mood: MoodExtension.fromString(json['mood']),
    locationEnabled: json['locationEnabled'] ?? true,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );

  UserModel copyWith({
    String? name,
    DateTime? birthDate,
    String? bio,
    String? city,
    List<String>? photos,
    String? avatarEmoji,
    Mood? mood,
    bool? locationEnabled,
    double? lat,
    double? lng,
    double? distanceMeters,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    bio: bio ?? this.bio,
    city: city ?? this.city,
    photos: photos ?? this.photos,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    mood: mood ?? this.mood,
    locationEnabled: locationEnabled ?? this.locationEnabled,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    distanceMeters: distanceMeters ?? this.distanceMeters,
  );
}
