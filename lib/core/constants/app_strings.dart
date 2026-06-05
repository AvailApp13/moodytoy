class AppStrings {
  AppStrings._();

  static const String appName = 'MoodyToy';

  // Tabs
  static const String tabPeople = 'Люди';
  static const String tabCollection = 'Коллекция';
  static const String tabChats = 'Чаты';
  static const String tabFriends = 'Друзья';
  static const String tabProfile = 'Я';

  // People
  static const String peopleNearby = 'рядом';
  static const String addFriend = '+ Друг';
  static const String requestSent = 'Запрос отправлен';
  static const String acceptRequest = 'Принять запрос';
  static const String friend = 'Друг';
  static const String writeMessage = 'Написать';

  // Moods
  static const String moodCoffee = 'Кофе-брейк';
  static const String moodGamer = 'Игрок';
  static const String moodDating = 'Знакомство';
  static const String moodWalk = 'Прогулка';
  static const String moodSport = 'Спорт/активность';

  // Profile
  static const String editProfile = 'Редактировать';
  static const String settings = 'Настройки';
  static const String showOnMap = 'Показывать меня на карте';

  // Keyfob
  static const String connectToy = 'Подключить игрушку';
  static const String keyfobSubtitle = 'nRF52832 · BLE 5.0 · OTA';

  // Errors
  static const String errorGeneral = 'Что-то пошло не так';
  static const String errorNetwork = 'Нет подключения к сети';

  // Utils
  static String distance(double meters) {
    if (meters < 1000) {
      final r = (meters / 10).round() * 10;
      return '~${r.toInt()}м';
    }
    return '~${(meters / 1000).toStringAsFixed(1)}км';
  }
}
