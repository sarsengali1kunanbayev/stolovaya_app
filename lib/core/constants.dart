class AppConstants {
  static const List<String> categories = [
    "Все",
    "Горячее",
    "Салаты",
    "Напитки",
    "Выпечка",
    "Гарниры",
    "Десерты",
    "Основное",
  ];

  static const List<String> categoryIcons = [
    "🍽️",
    "🍲",
    "🥗",
    "🥤",
    "🥐",
    "🍚",
    "🍰",
    "🍛",
  ];

  // Иконка по названию категории
  static String iconFor(String category) {
    final map = {
      "Все": "🍽️",
      "Горячее": "🍲",
      "Салаты": "🥗",
      "Напитки": "🥤",
      "Выпечка": "🥐",
      "Гарниры": "🍚",
      "Десерты": "🍰",
      "Основное": "🍛",
    };
    return map[category] ?? "🍽️";
  }
}
