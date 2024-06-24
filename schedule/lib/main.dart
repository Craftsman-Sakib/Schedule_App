import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/course_provider.dart';
import 'course_selection_screen.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourseProvider(),
      child: MaterialApp(
        title: 'University Calendar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const CalendarScreen(),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  late List<Course> _coursesForSelectedDay;
  int _selectedSemester = 1;

  @override
  void initState() {
    super.initState();
    _coursesForSelectedDay = [];
    _updateCoursesForSelectedDay();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _updateCoursesForSelectedDay();
    });
  }

  void _updateCoursesForSelectedDay() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final selectedCourses = courseProvider.routineType == 'ongoing'
        ? courseProvider.getOngoingCourses()
        : courseProvider.getCoursesBySemester(_selectedSemester);
    setState(() {
      _coursesForSelectedDay = selectedCourses.where((course) {
        return course.schedule.containsKey(_selectedDay.weekday);
      }).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final courseProvider = Provider.of<CourseProvider>(context);
    courseProvider.addListener(_updateCoursesForSelectedDay);
  }

  @override
  void dispose() {
    super.dispose();
    final courseProvider = Provider.of<CourseProvider>(context);
    courseProvider.removeListener(_updateCoursesForSelectedDay);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('University Routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseSelectionScreen(),
                ),
              ).then((_) {
                _updateCoursesForSelectedDay();
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              courseProvider.setRoutineType(value);
              _updateCoursesForSelectedDay();
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'ongoing',
                  child: Text('Ongoing'),
                ),
                const PopupMenuItem<String>(
                  value: 'semester',
                  child: Text('Semester'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Routine Type: ${courseProvider.routineType == 'ongoing' ? 'Ongoing' : 'Semester'}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (courseProvider.routineType == 'semester')
                  DropdownButton<int>(
                    value: _selectedSemester,
                    onChanged: (int? newValue) {
                      setState(() {
                        _selectedSemester = newValue!;
                        _updateCoursesForSelectedDay();
                      });
                    },
                    items: List.generate(8, (index) => index + 1)
                        .map((semester) => DropdownMenuItem<int>(
                              value: semester,
                              child: Text('Semester $semester'),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDay,
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            availableGestures: AvailableGestures.all,
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio:
                    1.20, // Adjusted aspect ratio for more vertical space
              ),
              padding: const EdgeInsets.all(8.0),
              itemCount: _coursesForSelectedDay.length,
              itemBuilder: (context, index) {
                final course = _coursesForSelectedDay[index];
                return CourseCard(
                  course: course,
                  index: index,
                  selectedDay: _selectedDay,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final int index;
  final DateTime selectedDay;

  const CourseCard({
    required this.course,
    required this.index,
    required this.selectedDay,
    super.key,
  });

  bool _isCourseOngoing(TimeRange timeRange, TimeOfDay now) {
    final startMinutes =
        timeRange.startTime.hour * 60 + timeRange.startTime.minute;
    final endMinutes = timeRange.endTime.hour * 60 + timeRange.endTime.minute;
    final nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final daySchedule = course.schedule[selectedDay.weekday];
    final isOngoing = daySchedule != null && _isCourseOngoing(daySchedule, now);

    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final isOverlapping =
        courseProvider.isCourseOverlapping(course, selectedDay);

    return Card(
      color: isOngoing ? Colors.green.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 3.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOngoing ? Colors.green.shade900 : Colors.black,
                fontSize: 16,
              ),
            ),
            if (daySchedule != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${daySchedule.startTime.format(context)} - ${daySchedule.endTime.format(context)}',
                  style: TextStyle(
                    color: isOngoing
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                course.roomNumber,
                style: TextStyle(
                  color:
                      isOngoing ? Colors.green.shade700 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                course.teacherName,
                style: TextStyle(
                  color:
                      isOngoing ? Colors.green.shade700 : Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
            if (isOverlapping)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Overlapping',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
