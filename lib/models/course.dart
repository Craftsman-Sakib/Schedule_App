import 'package:flutter/material.dart';

class Course {
  final String name;
  final int semester;
  final Map<int, TimeRange>
      schedule; // Map representing the schedule for each day
  final String roomNumber;
  final String teacherName;
  final int creditHour;

  Course({
    required this.name,
    required this.semester,
    required this.schedule,
    required this.roomNumber,
    required this.teacherName,
    required this.creditHour,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class TimeRange {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  TimeRange({
    required this.startTime,
    required this.endTime,
  });
}
