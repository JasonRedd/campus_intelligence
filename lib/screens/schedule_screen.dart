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
        title: const Text('Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your academic command center',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
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
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            Text(
              'Filter events',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
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
                        final categoryColor = _getCategoryColor(
                          context,
                          item.category,
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: categoryColor.withAlpha(35),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: categoryColor.withAlpha(110),
                                  ),
                                ),
                                child: Icon(
                                  _getCategoryIcon(item.category),
                                  color: categoryColor,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(item.subtitle),
                              ),
                              trailing: Chip(
                                label: Text(
                                  item.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                backgroundColor: categoryColor.withAlpha(35),
                                side: BorderSide(color: categoryColor),
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

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category.toLowerCase()) {
      case 'exam':
        return Theme.of(context).colorScheme.error;
      case 'workshop':
        return Theme.of(context).colorScheme.secondary;
      case 'class':
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }
}