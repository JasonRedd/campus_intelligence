import 'package:flutter/material.dart';
import 'models/task_item.dart';
import 'screens/assistant_screen.dart';
import 'screens/schedule_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const CampusIntelligenceApp());
}

class CampusIntelligenceApp extends StatelessWidget {
  const CampusIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _assistantMemoryEnabled = true;

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

  @override
  Widget build(BuildContext context) {
    final scheduleItems = [
      TaskItem(id: '1', title: 'DBMS Lab', subtitle: 'Lab 3 • 10:00 AM', category: 'schedule'),
      TaskItem(id: '2', title: 'Mathematics', subtitle: 'Room 204 • 02:00 PM', category: 'schedule'),
    ];

    final deadlineItems = [
      TaskItem(id: '3', title: 'DBMS Assignment', subtitle: 'Due: Sep 5 • Lab 3', category: 'deadline'),
      TaskItem(id: '4', title: 'Python Record', subtitle: 'Due: Sep 8', category: 'deadline'),
    ];

    final recentChanges = [
      TaskItem(id: '5', title: 'CSE Lab OS Updated', subtitle: 'Windows → Ubuntu', category: 'change'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Intelligence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
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

            // AI Assistant Banner Button with Memory Toggle
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
                      subtitle: Text(_assistantMemoryEnabled
                          ? 'Grounded in verified campus memory'
                          : 'Memory mode disabled'),
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
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

            // Today's Schedule Header + Navigation Button
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
            ItemListViewCard(items: scheduleItems, icon: Icons.class_, iconColor: Colors.indigo),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Upcoming Deadlines'),
            const SizedBox(height: 8),
            ItemListViewCard(items: deadlineItems, icon: Icons.priority_high, iconColor: Colors.red),

            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Campus Changes'),
            const SizedBox(height: 8),
            ItemListViewCard(items: recentChanges, icon: Icons.update, iconColor: Colors.blue),
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

  const ItemListViewCard({
    super.key,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: items.map((item) {
          final isLast = items.last == item;
          return Column(
            children: [
              ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}