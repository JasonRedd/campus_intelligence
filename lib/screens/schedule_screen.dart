import 'package:flutter/material.dart';
import '../models/task_item.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<TaskItem> _allScheduleItems = [
    TaskItem(id: '1', title: 'DBMS Lab', subtitle: 'Lab 3 • 10:00 AM', category: 'class'),
    TaskItem(id: '2', title: 'Mathematics', subtitle: 'Room 204 • 02:00 PM', category: 'class'),
    TaskItem(id: '3', title: 'Operating Systems Midterm', subtitle: 'Hall A • Sep 10, 10:00 AM', category: 'exam'),
    TaskItem(id: '4', title: 'Python Programming Workshop', subtitle: 'Auditorium • Sep 12, 03:00 PM', category: 'workshop'),
    TaskItem(id: '5', title: 'Computer Networks Lecture', subtitle: 'Room 102 • 11:30 AM', category: 'class'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    
    // Filter items based on search query and category selection
    final filteredItems = _allScheduleItems.where((item) {
      final matchesQuery = item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' ||
          item.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVault Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search classes, exams, workshops...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Class', 'Exam', 'Workshop'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Filtered Schedule List
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching events found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(_getCategoryIcon(item.category)),
                            ),
                            title: Text(item.title),
                            subtitle: Text(item.subtitle),
                            trailing: Chip(
                              label: Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'class':
        return Icons.class_;
      case 'exam':
        return Icons.assignment;
      case 'workshop':
        return Icons.event;
      default:
        return Icons.schedule;
    }
  }
}