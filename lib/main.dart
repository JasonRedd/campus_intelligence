import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/task_item.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/storage_service.dart';
import 'services/campus_data_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException {
    firebaseReady = false;
  } on AssertionError {
    firebaseReady = false;
  }
  runApp(CampusIntelligenceApp(firebaseReady: firebaseReady));
}

class CampusIntelligenceApp extends StatefulWidget {
  final bool firebaseReady;

  const CampusIntelligenceApp({super.key, this.firebaseReady = false});

  @override
  State<CampusIntelligenceApp> createState() => _CampusIntelligenceAppState();
}

class _CampusIntelligenceAppState extends State<CampusIntelligenceApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final isDark = await StorageService.getDarkModePreference();
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme(bool isDark) async {
    await StorageService.saveDarkModePreference(isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Intelligence',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: CampusTheme.light(),
      darkTheme: CampusTheme.dark(),
      home: widget.firebaseReady
          ? StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasData) {
                  return HomeScreen(
                    isDarkMode: _themeMode == ThemeMode.dark,
                    onThemeChanged: _toggleTheme,
                  );
                }
                return const AuthScreen();
              },
            )
          : const FirebaseSetupScreen(),
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Campus Intelligence',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Firebase is not configured for this app. '
                'Run flutterfire configure, then restart the app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _assistantMemoryEnabled = true;
  Uint8List? _profileImage;

  final List<TaskItem> _scheduleItems = [
    TaskItem(
      id: '1',
      title: 'DBMS Lab',
      subtitle: 'Lab 3 • 10:00 AM',
      category: 'schedule',
    ),
    TaskItem(
      id: '2',
      title: 'Mathematics',
      subtitle: 'Room 204 • 02:00 PM',
      category: 'schedule',
    ),
  ];

  final List<TaskItem> _deadlineItems = [
    TaskItem(
      id: '3',
      title: 'DBMS Assignment',
      subtitle: 'Due: Sep 5 • Lab 3',
      category: 'deadline',
    ),
    TaskItem(
      id: '4',
      title: 'Python Record',
      subtitle: 'Due: Sep 8',
      category: 'deadline',
    ),
  ];

  final List<TaskItem> _recentChanges = [
    TaskItem(
      id: '5',
      title: 'CSE Lab OS Updated',
      subtitle: 'Windows → Ubuntu',
      category: 'change',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreference();
    _loadProfileImage();
    _loadCampusItems();
  }

  Future<void> _loadCampusItems() async {
    final items = await CampusDataService.loadItems();
    if (!mounted) return;
    if (items.isEmpty) {
      for (final item in [..._scheduleItems, ..._deadlineItems]) {
        await CampusDataService.saveItem(item);
      }
      return;
    }
    setState(() {
      _scheduleItems
        ..clear()
        ..addAll(items.where((item) => item.category == 'schedule'));
      _deadlineItems
        ..clear()
        ..addAll(items.where((item) => item.category == 'deadline'));
    });
  }

  Future<void> _loadProfileImage() async {
    final profile = await StorageService.getProfile();
    var encodedImage = profile['image'] ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('details')
          .get();
      encodedImage = snapshot.data()?['image'] as String? ?? encodedImage;
      if (encodedImage.isNotEmpty) {
        await StorageService.saveProfileImage(encodedImage);
      }
    }
    if (!mounted) return;
    setState(() {
      _profileImage = encodedImage.isEmpty ? null : base64Decode(encodedImage);
    });
  }

  Future<void> _loadPreference() async {
    final enabled = await StorageService.getAssistantPreference();
    setState(() {
      _assistantMemoryEnabled = enabled;
    });
  }

  Future<void> _togglePreference(bool value) async {
    await StorageService.saveAssistantPreference(value);
    setState(() {
      _assistantMemoryEnabled = value;
    });
  }

  void _toggleTask(TaskItem item) {
    setState(() {
      item.isCompleted = !item.isCompleted;
    });
  }

  void _deleteTask(List<TaskItem> list, TaskItem item) {
    setState(() {
      list.removeWhere((t) => t.id == item.id);
    });
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    var category = 'schedule';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'schedule', child: Text('Schedule')),
                  DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => category = value);
                },
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subtitleController,
                decoration: InputDecoration(
                  labelText: category == 'schedule'
                      ? 'Details (room and time)'
                      : 'Details (due date and notes)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                setState(() {
                  final item = TaskItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text.trim(),
                    subtitle: subtitleController.text.trim().isEmpty
                        ? category == 'schedule'
                              ? 'Scheduled'
                              : 'No due date specified'
                        : subtitleController.text.trim(),
                    category: category,
                  );
                  if (category == 'schedule') {
                    _scheduleItems.add(item);
                  } else {
                    _deadlineItems.add(item);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildProfileDrawer(context),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open profile menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Campus Intelligence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Open calendar',
            onPressed: _openCalendar,
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: widget.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
          ),
        ],
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        tooltip: 'Add Schedule Item',
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'What do you need today?',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildDashboardOverview(context),
            const SizedBox(height: 20),

            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.smart_toy, size: 32),
                      title: const Text(
                        'Ask Campus Assistant',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _assistantMemoryEnabled
                            ? 'Grounded in verified campus memory'
                            : 'Memory mode disabled',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AssistantScreen(
                              onLocalCommand: _handleAssistantCommand,
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text(
                        'Campus Memory Context',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: _assistantMemoryEnabled,
                      onChanged: _togglePreference,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: 'Today\'s Schedule'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ScheduleScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ItemListViewCard(
              items: _scheduleItems,
              icon: Icons.class_,
              iconColor: Colors.indigo,
              onToggle: _toggleTask,
              onDelete: (item) => _deleteTask(_scheduleItems, item),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Upcoming Deadlines'),
            const SizedBox(height: 8),
            ItemListViewCard(
              items: _deadlineItems,
              icon: Icons.priority_high,
              iconColor: Colors.red,
              onToggle: _toggleTask,
              onDelete: (item) => _deleteTask(_deadlineItems, item),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(title: 'Tasks & Assignments'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TasksScreen()),
                    );
                  },
                  child: const Text('Open tracker'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.task_alt),
                title: const Text('Organize your coursework'),
                subtitle: const Text(
                  'Track progress, priorities, and upcoming deadlines.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TasksScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text(
                  'Calendar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('View classes and deadlines together.'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _openCalendar,
              ),
            ),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Campus Changes'),
            const SizedBox(height: 8),
            ItemListViewCard(
              items: _recentChanges,
              icon: Icons.update,
              iconColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardOverview(BuildContext context) {
    final completedDeadlines =
        _deadlineItems.where((item) => item.isCompleted).length;
    final progress = _deadlineItems.isEmpty
        ? 0
        : ((completedDeadlines / _deadlineItems.length) * 100).round();
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final cards = [
          _OverviewCard(
            label: 'Classes today',
            value: '${_scheduleItems.length}',
            icon: Icons.calendar_today,
            color: const Color(0xFF28A9FF),
          ),
          _OverviewCard(
            label: 'Deadlines',
            value: '${_deadlineItems.length}',
            icon: Icons.assignment_late,
            color: const Color(0xFFFFB547),
          ),
          _OverviewCard(
            label: 'Completion',
            value: '$progress%',
            icon: Icons.trending_up,
            color: const Color(0xFF00D5D5),
          ),
        ];
        return GridView.count(
          crossAxisCount: compact ? 1 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: compact ? 4.2 : 1.55,
          children: cards,
        );
      },
    );
  }

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarScreen(
          scheduleItems: _scheduleItems,
          deadlineItems: _deadlineItems,
          onAddItem: (item) {
            setState(() {
              if (item.category == 'schedule') {
                _scheduleItems.add(item);
              } else {
                _deadlineItems.add(item);
              }
            });
            CampusDataService.saveItem(item);
          },
        ),
      ),
    );
  }

  Future<String?> _handleAssistantCommand(String prompt) async {
    final normalized = prompt.trim();
    final lower = normalized.toLowerCase();
    final isSchedule = lower.contains('schedule') || lower.contains('class');

    if (lower.startsWith('add schedule') || lower.startsWith('add class')) {
      final values = _commandValues(normalized);
      if (values.length < 4) {
        return 'To add a class, use: add schedule | subject | room | time | professor';
      }
      final item = TaskItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: values[0],
            subtitle: '${values[1]} • ${values[2]} • ${values[3]}',
            category: 'schedule',
          );
      setState(() {
        _scheduleItems.add(item);
      });
      await CampusDataService.saveItem(item);
      return 'Added ${values[0]} to your schedule.';
    }

    if (lower.startsWith('add deadline') ||
        lower.startsWith('add assignment')) {
      final values = _commandValues(normalized);
      if (values.length < 2) {
        return 'To add a deadline, use: add deadline | title | due date and notes';
      }
      final item = TaskItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: values[0],
            subtitle: values[1],
            category: 'deadline',
          );
      setState(() {
        _deadlineItems.add(item);
      });
      await CampusDataService.saveItem(item);
      return 'Added ${values[0]} to your deadlines.';
    }

    if (lower.startsWith('edit ') || lower.startsWith('update ')) {
      final values = _commandValues(normalized);
      final items = isSchedule ? _scheduleItems : _deadlineItems;
      if (values.length < 3) {
        return isSchedule
            ? 'To edit a class, use: edit schedule | old subject | new subject | room | time | professor'
            : 'To edit a deadline, use: edit deadline | old title | new title | due date and notes';
      }
      final index = _findItemIndex(items, values[0]);
      if (index == -1) return 'I could not find "${values[0]}".';
      setState(() {
        final current = items[index];
        items[index] = TaskItem(
          id: current.id,
          title: values[1],
          subtitle: isSchedule && values.length >= 5
              ? '${values[2]} • ${values[3]} • ${values[4]}'
              : values[2],
          category: current.category,
          isCompleted: current.isCompleted,
        );
      });
      await CampusDataService.saveItem(items[index]);
      return 'Updated ${values[1]}.';
    }

    if (lower.startsWith('delete ') || lower.startsWith('remove ')) {
      final items = isSchedule ? _scheduleItems : _deadlineItems;
      final search = normalized
          .replaceFirst(
            RegExp(r'^(delete|remove)\s+', caseSensitive: false),
            '',
          )
          .replaceFirst(
            RegExp(
              r'^(schedule|class|deadline|assignment)\s+',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
      final index = _findItemIndex(items, search);
      if (index == -1) return 'I could not find "$search".';
      final removed = items[index].title;
      final removedId = items[index].id;
      setState(() => items.removeAt(index));
      await CampusDataService.deleteItem(removedId);
      return 'Removed $removed.';
    }

    if (lower.startsWith('complete ') || lower.startsWith('mark done ')) {
      final items = _deadlineItems;
      final search = normalized
          .replaceFirst(
            RegExp(r'^(complete|mark done)\s+', caseSensitive: false),
            '',
          )
          .trim();
      final index = _findItemIndex(items, search);
      if (index == -1) return 'I could not find deadline "$search".';
      setState(() => items[index].isCompleted = true);
      await CampusDataService.saveItem(items[index]);
      return 'Marked ${items[index].title} as completed.';
    }

    return null;
  }

  List<String> _commandValues(String command) {
    return command
        .split('|')
        .skip(1)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  int _findItemIndex(List<TaskItem> items, String search) {
    final query = search.toLowerCase();
    return items.indexWhere(
      (item) =>
          item.title.toLowerCase() == query ||
          item.title.toLowerCase().contains(query),
    );
  }

  Widget _buildProfileDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Student Profile'),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              backgroundImage: _profileImage == null
                  ? null
                  : MemoryImage(_profileImage!),
              child: _profileImage == null
                  ? Text(
                      email.isNotEmpty ? email[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: Text(email),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(email: email)),
              );
              await _loadProfileImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('User ID'),
            subtitle: Text(user?.uid ?? 'Not logged in'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _OverviewCard extends StatelessWidget {
    final String label;
    final String value;
    final IconData icon;
    final Color color;

    const _OverviewCard({
      required this.label,
      required this.value,
      required this.icon,
      required this.color,
    });

    @override
    Widget build(BuildContext context) {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
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

class ItemListViewCard extends StatelessWidget {
  final List<TaskItem> items;
  final IconData icon;
  final Color iconColor;
  final Function(TaskItem)? onToggle;
  final Function(TaskItem)? onDelete;

  const ItemListViewCard({
    super.key,
    required this.items,
    required this.icon,
    required this.iconColor,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No items available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  icon,
                  color: item.isCompleted ? Colors.grey : iconColor,
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: item.isCompleted ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(item.subtitle),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onToggle != null)
                      Checkbox(
                        value: item.isCompleted,
                        onChanged: (_) => onToggle!(item),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                        onPressed: () => onDelete!(item),
                      ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}
