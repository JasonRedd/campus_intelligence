import 'package:flutter/material.dart';

import '../models/task_item.dart';

class CalendarScreen extends StatefulWidget {
  final List<TaskItem> scheduleItems;
  final List<TaskItem> deadlineItems;
  final ValueChanged<TaskItem> onAddItem;

  const CalendarScreen({
    super.key,
    required this.scheduleItems,
    required this.deadlineItems,
    required this.onAddItem,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  List<TaskItem> get _events => [
        ...widget.scheduleItems,
        ...widget.deadlineItems,
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
              onDateChanged: (date) => setState(() => _selectedDate = date),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _formatDate(_selectedDate),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_events.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No schedule items or deadlines yet.'),
              ),
            )
          else
            ..._events.map(_eventCard),
        ],
      ),
    );
  }

  Widget _eventCard(TaskItem item) {
    final isDeadline = item.category == 'deadline';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isDeadline ? Icons.assignment_late : Icons.class_),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Chip(label: Text(isDeadline ? 'Deadline' : 'Schedule')),
      ),
    );
  }

  Future<void> _showAddEventSheet() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    var category = 'schedule';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add to calendar',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'schedule', child: Text('Schedule')),
                  DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                ],
                onChanged: (value) {
                  if (value != null) setSheetState(() => category = value);
                },
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Room, time, due date, or notes',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  widget.onAddItem(TaskItem(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: title,
                    subtitle: detailsController.text.trim().isEmpty
                        ? 'No details specified'
                        : detailsController.text.trim(),
                    category: category,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Add event'),
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    detailsController.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
