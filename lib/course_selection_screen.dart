import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/course_provider.dart';
import '../services/local_storage.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _CourseSelectionScreenState createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  List<String> selectedCourseIds = [];
  Map<String, String> courseStatuses = {}; // courseId -> status
  String searchQuery = '';
  bool showOnlySelected = false;
  String sortBy = 'code'; // Default sort by code
  String filterStatus =
      'all'; // Options: 'all', 'completed', 'on-going', 'remaining'
  @override
  void initState() {
    super.initState();
    _loadSelectedCourses();
    _loadCourseStatuses();
  }

  Future<void> _loadSelectedCourses() async {
    try {
      selectedCourseIds = await LocalStorage.getSelectedCourses();
    } catch (error) {
      if (kDebugMode) {
        print('Error loading selected courses: $error');
      }
    }
    setState(() {});
  }

  Future<void> _loadCourseStatuses() async {
    try {
      courseStatuses = await LocalStorage.getCourseStatuses();
    } catch (error) {
      if (kDebugMode) {
        print('Error loading course statuses: $error');
      }
    }
    setState(() {});
  }

  void _toggleCourseSelection(String courseId) {
    setState(() {
      if (selectedCourseIds.contains(courseId)) {
        selectedCourseIds.remove(courseId);
      } else {
        selectedCourseIds.add(courseId);
      }
    });
    LocalStorage.saveSelectedCourses(selectedCourseIds);
    _updateCalendarScreen();
  }

  void _updateCalendarScreen() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    courseProvider.notifyListeners(); // Trigger a rebuild of the calendar view
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  // ignore: unused_element
  double _getTotalCreditHoursForSelectedCourses() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    double total = 0.0;
    for (var courseId in selectedCourseIds) {
      final course = courseProvider.courses
          .firstWhere((course) => course.name == courseId);
      total += course.creditHour;
    }
    return total;
  }

  void _toggleShowOnlySelected() {
    setState(() {
      showOnlySelected = !showOnlySelected;
    });
    _buildTotalCreditHoursWidget(_getTotalCreditHours());
  }

  void _updateSortBy(String value) {
    setState(() {
      sortBy = value;
    });
  }

  void _updateFilterStatus(String status) {
    setState(() {
      filterStatus = status;
    });
  }

  List<Course> _getFilteredAndSortedCourses() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    var courses = courseProvider.courses.where((course) {
      final courseLower = course.name.toLowerCase();
      final searchLower = searchQuery.toLowerCase();
      final matchesSearch = courseLower.contains(searchLower) ||
          course.roomNumber.toLowerCase().contains(searchLower);
      final matchesSelection =
          !showOnlySelected || selectedCourseIds.contains(course.name);
      final matchesStatus = filterStatus == 'all' ||
          (filterStatus == 'completed' &&
              courseStatuses[course.name] == 'completed') ||
          (filterStatus == 'on-going' &&
              courseStatuses[course.name] == 'on-going') ||
          (filterStatus == 'remaining' &&
              courseStatuses[course.name] != 'completed' &&
              courseStatuses[course.name] != 'on-going');
      return matchesSearch && matchesSelection && matchesStatus;
    }).toList();
    courses.sort((a, b) {
      switch (sortBy) {
        case 'title':
          return a.name.compareTo(b.name);
        case 'semester':
          return a.semester.compareTo(b.semester);
        case 'code':
        default:
          return a.name.compareTo(b.name);
      }
    });
    return courses;
  }

  double _getTotalCreditHours() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    double total = 0.0;
    for (var course in courseProvider.courses) {
      final courseStatus = courseStatuses[course.name] ?? '';
      if (filterStatus == 'remaining' &&
          courseStatus != 'completed' &&
          courseStatus != 'on-going') {
        total += course.creditHour;
      } else if (filterStatus == 'all' || courseStatus == filterStatus) {
        total += course.creditHour;
      }
    }
    return total;
  }

  void _updateCourseStatus(String courseId, String status) {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    setState(() {
      courseStatuses[courseId] = status;
    });
    LocalStorage.saveCourseStatuses(courseStatuses);
    courseProvider.updateCourseStatus(courseId, status);
  }

  void _markAllOnGoingAsCompleted() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    for (var course in courseProvider.courses) {
      if (courseStatuses[course.name] == 'on-going') {
        _updateCourseStatus(course.name, 'completed');
      }
    }
  }

  void _showStatusPopup(String courseId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                if (filterStatus == 'on-going')
                  ListTile(
                    title: const Text('Mark All Completed'),
                    onTap: () {
                      _markAllOnGoingAsCompleted();
                      Navigator.of(context).pop();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Completed'),
                  onTap: () {
                    _updateCourseStatus(courseId, 'completed');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.hourglass_full, color: Colors.orange),
                  title: const Text('On-going'),
                  onTap: () {
                    _updateCourseStatus(courseId, 'on-going');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear, color: Colors.red),
                  title: const Text('Remove Status'),
                  onTap: () {
                    _updateCourseStatus(courseId, '');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortIndicator() {
    IconData icon;
    switch (sortBy) {
      case 'title':
        icon = Icons.sort_by_alpha;
        break;
      case 'semester':
        icon = Icons.date_range;
        break;
      case 'code':
      default:
        icon = Icons.format_list_numbered;
    }
    return Icon(icon, color: Colors.white);
  }

  Widget _buildFilterIndicator() {
    IconData icon;
    switch (filterStatus) {
      case 'completed':
        icon = Icons.check_circle;
        break;
      case 'on-going':
        icon = Icons.hourglass_full;
        break;
      case 'remaining':
        icon = Icons.clear;
        break;
      case 'all':
      default:
        icon = Icons.filter_list;
    }
    return Icon(icon, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final filteredCourses = _getFilteredAndSortedCourses();
    final totalCreditHours = _getTotalCreditHours();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Courses'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CourseSearchDelegate(
                    Provider.of<CourseProvider>(context, listen: false).courses,
                    _toggleCourseSelection),
              );
            },
          ),
          IconButton(
            icon: Icon(showOnlySelected
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            onPressed: _toggleShowOnlySelected,
          ),
          PopupMenuButton<String>(
            onSelected: _updateSortBy,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'code',
                  child: Row(
                    children: [
                      const Text('Sort by Code'),
                      if (sortBy == 'code')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'title',
                  child: Row(
                    children: [
                      const Text('Sort by Title'),
                      if (sortBy == 'title')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'semester',
                  child: Row(
                    children: [
                      const Text('Sort by Semester'),
                      if (sortBy == 'semester')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
              ];
            },
            child: _buildSortIndicator(),
          ),
          PopupMenuButton<String>(
            onSelected: _updateFilterStatus,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      const Text('Show All'),
                      if (filterStatus == 'all')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      const Text('Completed'),
                      if (filterStatus == 'completed')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'on-going',
                  child: Row(
                    children: [
                      const Text('On-going'),
                      if (filterStatus == 'on-going')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remaining',
                  child: Row(
                    children: [
                      const Text('Remaining'),
                      if (filterStatus == 'remaining')
                        const Icon(Icons.check, color: Colors.blueGrey),
                    ],
                  ),
                ),
              ];
            },
            child: _buildFilterIndicator(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                final isSelected = selectedCourseIds.contains(course.name);
                final courseStatus = courseStatuses[course.name] ?? '';

                return ListTile(
                  title: Text(course.name),
                  subtitle:
                      Text('${course.roomNumber} - ${course.teacherName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          courseStatus == 'completed'
                              ? Icons.check_circle
                              : courseStatus == 'on-going'
                                  ? Icons.hourglass_full
                                  : Icons.circle_outlined,
                          color: courseStatus == 'completed'
                              ? Colors.green
                              : courseStatus == 'on-going'
                                  ? Colors.orange
                                  : Colors.grey,
                        ),
                        onPressed: () => _showStatusPopup(course.name),
                      ),
                      IconButton(
                        icon: Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        onPressed: () => _toggleCourseSelection(course.name),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          _buildTotalCreditHoursWidget(totalCreditHours),
        ],
      ),
    );
  }

  Widget _buildTotalCreditHoursWidget(double totalCreditHours) {
    return Container(
      color: Colors.blueGrey,
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Total Credit Hours: $totalCreditHours',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

class CourseSearchDelegate extends SearchDelegate {
  final List<Course> courses;
  final Function(String) onCourseSelected;

  CourseSearchDelegate(this.courses, this.onCourseSelected);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildCourseList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildCourseList();
  }

  Widget _buildCourseList() {
    final filteredCourses = courses.where((course) {
      return course.name.toLowerCase().contains(query.toLowerCase()) ||
          course.roomNumber.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredCourses.length,
      itemBuilder: (context, index) {
        final course = filteredCourses[index];
        return ListTile(
          title: Text(course.name),
          subtitle: Text('${course.roomNumber} - ${course.teacherName}'),
          onTap: () {
            onCourseSelected(course.name);
            close(context, null);
          },
        );
      },
    );
  }
}
