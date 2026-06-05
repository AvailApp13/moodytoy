import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

enum Mood { coffeeBreak, gamer, dating, walk, sport }

enum Gender { male, female, other }

enum LookingFor { male, female, all }

extension MoodExtension on Mood {
  String get label {
    switch (this) {
      case Mood.coffeeBreak: return 'Кофе-брейк';
      case Mood.gamer:       return 'Игрок';
      case Mood.dating:      return 'Знакомство';
      case Mood.walk:        return 'Прогулка';
      case Mood.sport:       return 'Спорт/активность';
    }
  }

  String get value {
    switch (this) {
      case Mood.coffeeBreak: return 'coffee_break';
      case Mood.gamer:       return 'gamer';
      case Mood.dating:      return 'dating';
      case Mood.walk:        return 'walk';
      case Mood.sport:       return 'sport';
    }
  }

  Color get color {
    switch (this) {
      case Mood.coffeeBreak: return const Color(0xFF6F4E37);
      case Mood.gamer:       return const Color(0xFF4CAF50);
      case Mood.dating:      return const Color(0xFFFF6B6B);
      case Mood.walk:        return const Color(0xFF4A90E2);
      case Mood.sport:       return const Color(0xFFFF9800);
    }
  }

  IconData get icon {
    switch (this) {
      case Mood.coffeeBreak: return Icons.local_cafe;
      case Mood.gamer:       return Icons.sports_esports;
      case Mood.dating:      return Icons.favorite;
      case Mood.walk:        return Icons.directions_walk;
      case Mood.sport:       return Icons.fitness_center;
    }
  }

  static Mood fromString(String? value) {
    switch (value) {
      case 'coffee_break': return Mood.coffeeBreak;
      case 'gamer':        return Mood.gamer;
      case 'dating':       return Mood.dating;
      case 'walk':         return Mood.walk;
      case 'sport':        return Mood.sport;
      default:             return Mood.coffeeBreak;
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String name;
  final int? age;
  final String? gender;
  final String? lookingFor;
  final String? bio;
  final String? city;
  final int? height;
  final List<String> tags;
  final List<String> photos;
  final bool faceVerified;
  final String? keyfobMac;
  final Mood? mood;
  final bool locationEnabled;
  final double? lat;
  final double? lng;
  final DateTime? locationUpdatedAt;
  final String? pushToken;
  final bool profilePrivate;
  final int? batteryLevel;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  // Computed — расстояние до текущего пользователя (не из БД)
  double? distanceMeters;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.name,
    this.age,
    this.gender,
    this.lookingFor,
    this.bio,
    this.city,
    this.height,
    this.tags = const [],
    this.photos = const [],
    this.faceVerified = false,
    this.keyfobMac,
    this.mood,
    this.locationEnabled = false,
    this.lat,
    this.lng,
    this.locationUpdatedAt,
    this.pushToken,
    this.profilePrivate = false,
    this.batteryLevel,
    this.createdAt,
    this.lastSeenAt,
    this.distanceMeters,
  });

  String? get mainPhoto => photos.isNotEmpty ? photos.first : null;

  bool get hasKeyfob => keyfobMac != null;

  bool get isOnMap => locationEnabled && lat != null && lng != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      name: json['name'] as String? ?? '',
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      lookingFor: json['looking_for'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      height: json['height'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      faceVerified: json['face_verified'] as bool? ?? false,
      keyfobMac: json['keyfob_mac'] as String?,
      mood: MoodExtension.fromString(json['mood'] as String?),
      locationEnabled: json['location_enabled'] as bool? ?? false,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      locationUpdatedAt: json['location_updated_at'] != null
          ? DateTime.tryParse(json['location_updated_at'])
          : null,
      pushToken: json['push_token'] as String?,
      profilePrivate: json['profile_private'] as bool? ?? false,
      batteryLevel: json['battery_level'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (phone != null) 'phone': phone,
        'name': name,
        if (age != null) 'age': age,
        if (gender != null) 'gender': gender,
        if (lookingFor != null) 'looking_for': lookingFor,
        if (bio != null) 'bio': bio,
        if (city != null) 'city': city,
        if (height != null) 'height': height,
        'tags': tags,
        'photos': photos,
        'face_verified': faceVerified,
        if (keyfobMac != null) 'keyfob_mac': keyfobMac,
        if (mood != null) 'mood': mood!.value,
        'location_enabled': locationEnabled,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (pushToken != null) 'push_token': pushToken,
        'profile_private': profilePrivate,
        if (batteryLevel != null) 'battery_level': batteryLevel,
      };

  UserModel copyWith({
    String? name,
    String? bio,
    String? city,
    int? height,
    int? age,
    List<String>? tags,
    List<String>? photos,
    String? keyfobMac,
    Mood? mood,
    bool? locationEnabled,
    double? lat,
    double? lng,
    bool? profilePrivate,
    int? batteryLevel,
    String? pushToken,
    double? distanceMeters,
  }) {
    return UserModel(
      id: id,
      email: email,
      phone: phone,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender,
      lookingFor: lookingFor,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      height: height ?? this.height,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      faceVerified: faceVerified,
      keyfobMac: keyfobMac ?? this.keyfobMac,
      mood: mood ?? this.mood,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationUpdatedAt: locationUpdatedAt,
      pushToken: pushToken ?? this.pushToken,
      profilePrivate: profilePrivate ?? this.profilePrivate,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }
}
