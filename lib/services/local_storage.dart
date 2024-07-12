// lib/services/local_storage.dart

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _selectedCoursesKey = 'selectedCourses';
  static const _courseStatusesKey = 'courseStatuses';

  static Future<void> saveSelectedCourses(List<String> courseIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedCoursesKey, courseIds);
  }

  static Future<List<String>> getSelectedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedCoursesKey) ?? [];
  }

  static Future<void> saveCourseStatuses(Map<String, String> statuses) async {
    final prefs = await SharedPreferences.getInstance();
    final statusStrings = statuses.map((key, value) => MapEntry(key, value));
    final statusData = statusStrings.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await prefs.setStringList(_courseStatusesKey, statusData);
  }

  static Future<Map<String, String>> getCourseStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final statusData = prefs.getStringList(_courseStatusesKey) ?? [];
    final statusMap = <String, String>{};
    for (var item in statusData) {
      final parts = item.split(':');
      if (parts.length == 2) {
        statusMap[parts[0]] = parts[1];
      }
    }
    return statusMap;
  }
}
