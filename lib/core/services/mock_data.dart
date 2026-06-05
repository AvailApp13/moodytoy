import '../../data/models/user_model.dart';

class MockData {
  // Мок-пользователи для тестирования
  static final List<UserModel> nearbyUsers = [
    UserModel(
      id: 'user_1',
      name: 'Алексей',
      birthDate: DateTime(1996, 3, 15),
      bio: 'Люблю кофе и хорошие разговоры',
      city: 'Москва',
      avatarEmoji: '🧑',
      mood: Mood.coffee,
      locationEnabled: true,
      distanceMeters: 80,
    ),
    UserModel(
      id: 'user_2',
      name: 'Мария',
      birthDate: DateTime(2000, 7, 22),
      bio: 'Ищу компанию для прогулок',
      city: 'Москва',
      avatarEmoji: '👱‍♀️',
      mood: Mood.walk,
      locationEnabled: true,
      distanceMeters: 230,
    ),
    UserModel(
      id: 'user_3',
      name: 'Дмитрий',
      birthDate: DateTime(1993, 11, 8),
      bio: 'Заядлый геймер, ищу тиммейтов',
      city: 'Москва',
      avatarEmoji: '🧔',
      mood: Mood.gamer,
      locationEnabled: true,
      distanceMeters: 410,
    ),
    UserModel(
      id: 'user_4',
      name: 'Анна',
      birthDate: DateTime(1998, 5, 30),
      bio: 'Хочу познакомиться с интересными людьми',
      city: 'Москва',
      avatarEmoji: '👩',
      mood: Mood.dating,
      locationEnabled: true,
      distanceMeters: 560,
    ),
    UserModel(
      id: 'user_5',
      name: 'Иван',
      birthDate: DateTime(1995, 9, 12),
      bio: 'Бегаю каждое утро, ищу партнёра',
      city: 'Москва',
      avatarEmoji: '🏃',
      mood: Mood.sport,
      locationEnabled: true,
      distanceMeters: 1200,
    ),
    UserModel(
      id: 'user_6',
      name: 'Юля',
      birthDate: DateTime(2002, 1, 18),
      bio: 'Кофеман со стажем ☕',
      city: 'Москва',
      avatarEmoji: '👩‍🦰',
      mood: Mood.coffee,
      locationEnabled: true,
      distanceMeters: 1800,
    ),
    UserModel(
      id: 'user_7',
      name: 'Максим',
      birthDate: DateTime(1989, 4, 25),
      bio: 'Pro gamer, stream on weekends',
      city: 'Москва',
      avatarEmoji: '🎮',
      mood: Mood.gamer,
      locationEnabled: true,
      distanceMeters: 2400,
    ),
    UserModel(
      id: 'user_8',
      name: 'Ольга',
      birthDate: DateTime(1997, 12, 3),
      bio: 'Романтик ищет своего человека',
      city: 'Москва',
      avatarEmoji: '🌸',
      mood: Mood.dating,
      locationEnabled: true,
      distanceMeters: 3100,
    ),
  ];

  static UserModel getUserById(String id) {
    return nearbyUsers.firstWhere(
      (u) => u.id == id,
      orElse: () => UserModel(id: id, name: 'Пользователь', avatarEmoji: '👤'),
    );
  }

  // Дефолтный текущий пользователь
  static UserModel defaultCurrentUser() => UserModel(
    id: 'me',
    name: 'Артём',
    birthDate: DateTime(1997, 6, 15),
    bio: 'Люблю путешествия и кофе',
    city: 'Москва',
    avatarEmoji: '😊',
    mood: Mood.coffee,
    locationEnabled: true,
  );
}
