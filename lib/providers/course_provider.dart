import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

class CourseProvider with ChangeNotifier {
  List<Course> _courses = [
    Course(
      name: 'Math 101',
      semester: 1,
      schedule: {
        1: TimeRange(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 10, minute: 0)), // Monday
        2: TimeRange(
            startTime: const TimeOfDay(hour: 12, minute: 30),
            endTime: const TimeOfDay(hour: 14, minute: 0)), // Tuesday
        3: TimeRange(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 10, minute: 0)), // Wednesday
        5: TimeRange(
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 10, minute: 0)), // Friday
      },
      roomNumber: 'Room A1',
      teacherName: 'Prof. John Doe',
      creditHour: 1,
    ),
    Course(
      name: 'Physics 101',
      semester: 2,
      schedule: {
        2: TimeRange(
            startTime: const TimeOfDay(hour: 16, minute: 00),
            endTime: const TimeOfDay(hour: 17, minute: 30)), // Tuesday
        4: TimeRange(
            startTime: const TimeOfDay(hour: 14, minute: 0),
            endTime: const TimeOfDay(hour: 15, minute: 30)), // Thursday
      },
      roomNumber: 'Room B1',
      teacherName: 'Dr. Jane Smith',
      creditHour: 3,
    ),
  ];

  List<Course> _selectedCourses = [];
  Map<String, String> _courseStatuses = {};
  String _routineType = 'ongoing'; // 'ongoing' or 'semester'

  List<Course> get courses => _courses;
  List<Course> get selectedCourses => _selectedCourses;
  String get routineType => _routineType;

  CourseProvider() {
    _loadSelectedCourses();
    _loadCourseStatuses();
    _loadRoutineType();
  }

  void setRoutineType(String type) async {
    _routineType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('routineType', type);
    notifyListeners();
  }

  Future<void> _loadRoutineType() async {
    final prefs = await SharedPreferences.getInstance();
    _routineType = prefs.getString('routineType') ?? 'ongoing';
    notifyListeners();
  }

  void updateCourses(List<Course> newCourses) {
    _courses = newCourses;
    notifyListeners();
  }

  List<Course> getCoursesBySemester(int semester) {
    return _courses.where((course) => course.semester == semester).toList();
  }

  List<Course> getOngoingCourses() {
    return _selectedCourses.where((course) {
      return _courseStatuses[course.name] == 'on-going';
    }).toList();
  }

  void addCourse(Course course) {
    _courses.add(course);
    notifyListeners();
  }

  void toggleSelectedCourse(Course course) async {
    if (_selectedCourses.contains(course)) {
      _selectedCourses.remove(course);
    } else {
      _selectedCourses.add(course);
    }
    await _saveSelectedCourses();
    notifyListeners();
  }

  Future<void> _saveSelectedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCourseNames =
        _selectedCourses.map((course) => course.name).toList();
    await prefs.setStringList('selectedCourses', selectedCourseNames);
    notifyListeners();
  }

  Future<void> _loadSelectedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedCourseNames = prefs.getStringList('selectedCourses') ?? [];
    _selectedCourses = _courses
        .where((course) => selectedCourseNames.contains(course.name))
        .toList();
    notifyListeners();
  }

  Future<void> _loadCourseStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final statusData = prefs.getStringList('courseStatuses') ?? [];
    final statusMap = <String, String>{};
    for (var item in statusData) {
      final parts = item.split(':');
      if (parts.length == 2) {
        statusMap[parts[0]] = parts[1];
      }
    }
    _courseStatuses = statusMap;
    notifyListeners();
  }

  bool isCourseOverlapping(Course course, DateTime day) {
    final selectedDaySchedule = course.schedule[day.weekday];
    if (selectedDaySchedule == null) return false;
    return _courses.any((otherCourse) {
      if (otherCourse == course) return false;
      final otherSchedule = otherCourse.schedule[day.weekday];
      if (otherSchedule == null) return false;
      return selectedDaySchedule.startTime.hour < otherSchedule.endTime.hour ||
          (selectedDaySchedule.startTime.hour == otherSchedule.endTime.hour &&
              selectedDaySchedule.startTime.minute <
                  otherSchedule.endTime.minute) ||
          selectedDaySchedule.endTime.hour > otherSchedule.startTime.hour ||
          (selectedDaySchedule.endTime.hour == otherSchedule.startTime.hour &&
              selectedDaySchedule.endTime.minute >
                  otherSchedule.startTime.minute);
    });
  }

  void updateCourseStatus(String courseId, String status) async {
    _courseStatuses[courseId] = status;
    final prefs = await SharedPreferences.getInstance();
    final statusStrings =
        _courseStatuses.map((key, value) => MapEntry(key, value));
    final statusData = statusStrings.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await prefs.setStringList('courseStatuses', statusData);
    notifyListeners();
  }
}
