import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/task_item.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/schedule_screen.dart';
import 'services/storage_service.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Schedule Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (e.g. OS Lab)',
              ),
            ),
            TextField(
              controller: subtitleController,
              decoration: const InputDecoration(
                labelText: 'Details (e.g. Room 101 • 11:00 AM)',
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
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _scheduleItems.add(
                    TaskItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text,
                      subtitle: subtitleController.text.isEmpty
                          ? 'Scheduled'
                          : subtitleController.text,
                      category: 'schedule',
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Intelligence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
                            builder: (context) => const AssistantScreen(),
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
