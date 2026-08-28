import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum TaskStatus { todo, inProgress, completed }

enum TaskPriority { high, medium, low }

class AssignmentTask {
  final String id;
  final String title;
  final String details;
  final TaskPriority priority;
  TaskStatus status;

  AssignmentTask({
    required this.id,
    required this.title,
    required this.details,
    required this.priority,
    this.status = TaskStatus.todo,
  });
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<AssignmentTask> _tasks = [
    AssignmentTask(
      id: 'dbms',
      title: 'DBMS Assignment',
      details: 'Due Sep 5 • Lab 3',
      priority: TaskPriority.high,
    ),
    AssignmentTask(
      id: 'python',
      title: 'Python Record',
      details: 'Due Sep 8',
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
    ),
    AssignmentTask(
      id: 'reading',
      title: 'Read networking chapter',
      details: 'Chapter 4',
      priority: TaskPriority.low,
      status: TaskStatus.completed,
    ),
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
  }

  Future<void> _loadTasks() async {
    final snapshot = await _tasksCollection.orderBy('createdAt').get();
    if (!mounted) return;
    if (snapshot.docs.isNotEmpty) {
      _tasks
        ..clear()
        ..addAll(snapshot.docs.map(_taskFromDocument));
    } else {
      for (final task in _tasks) {
        await _saveTask(task);
      }
    }
    setState(() => _isLoading = false);
  }

  AssignmentTask _taskFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return AssignmentTask(
      id: document.id,
      title: data['title'] as String,
      details: data['details'] as String,
      priority: TaskPriority.values[data['priority'] as int],
      status: TaskStatus.values[data['status'] as int],
    );
  }

  Future<void> _saveTask(AssignmentTask task) {
    return _tasksCollection.doc(task.id).set({
      'title': task.title,
      'details': task.details,
      'priority': task.priority.index,
      'status': task.status.index,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteStoredTask(String id) {
    return _tasksCollection.doc(id).delete();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'To Do'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Progress command center',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _buildProgressSummary(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: TaskStatus.values.map(_taskList).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressSummary() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daily progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            _ProgressBar(
              label: 'All tasks',
              tasks: _tasks,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            for (final priority in TaskPriority.values) ...[
              _ProgressBar(
                label: '${_priorityLabel(priority)} priority',
                tasks: _tasks
                    .where((task) => task.priority == priority)
                    .toList(),
                color: _priorityColor(priority),
              ),
              if (priority != TaskPriority.low) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.green,
    };
  }

  Widget _taskList(TaskStatus status) {
    final tasks = _tasks.where((task) => task.status == status).toList();
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          status == TaskStatus.completed
              ? 'No completed tasks yet.'
              : 'Nothing here. Add a task to get started.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          onDismissed: (_) {
            setState(() => _tasks.removeWhere((item) => item.id == task.id));
            _deleteStoredTask(task.id);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('${task.title} deleted')));
          },
          child: _TaskCard(
            task: task,
            onChanged: (checked) {
              setState(() {
                task.status = checked ? TaskStatus.completed : TaskStatus.todo;
              });
              _saveTask(task);
            },
            onStatusChanged: (newStatus) {
              setState(() => task.status = newStatus);
              _saveTask(task);
              _tabController.animateTo(newStatus.index);
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddTaskSheet() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    var priority = TaskPriority.medium;

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
              Text('Add task', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Due date or notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                initialValue: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_priorityLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setSheetState(() => priority = value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  setState(() {
                    final task = AssignmentTask(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: title,
                      details: detailsController.text.trim().isEmpty
                          ? 'No notes added'
                          : detailsController.text.trim(),
                      priority: priority,
                    );
                    _tasks.add(task);
                    _saveTask(task);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add task'),
              ),
            ],
          ),
        ),
      ),
    );
    titleController.dispose();
    detailsController.dispose();
  }
}

class _TaskCard extends StatelessWidget {
  final AssignmentTask task;
  final ValueChanged<bool> onChanged;
  final ValueChanged<TaskStatus> onStatusChanged;

  const _TaskCard({
    required this.task,
    required this.onChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final completed = task.status == TaskStatus.completed;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Checkbox(
            value: completed,
            onChanged: (value) => onChanged(value ?? false),
            visualDensity: VisualDensity.compact,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(task.details),
        ),
        trailing: PopupMenuButton<TaskStatus>(
          tooltip: 'Change status',
          onSelected: onStatusChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: TaskStatus.todo, child: Text('To Do')),
            PopupMenuItem(
              value: TaskStatus.inProgress,
              child: Text('In Progress'),
            ),
            PopupMenuItem(
              value: TaskStatus.completed,
              child: Text('Completed'),
            ),
          ],
          child: _PriorityBadge(priority: task.priority),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.green,
    };
    return Chip(
      label: Text(
        _priorityLabel(priority),
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withAlpha(30),
      side: BorderSide(color: color.withAlpha(100)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final List<AssignmentTask> tasks;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.tasks,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final completed = tasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              tasks.isEmpty
                  ? 'No tasks'
                  : '$completed of ${tasks.length} • ${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: color,
            backgroundColor: color.withAlpha(35),
          ),
        ),
      ],
    );
  }
}

String _priorityLabel(TaskPriority priority) {
  return switch (priority) {
    TaskPriority.high => 'High',
    TaskPriority.medium => 'Medium',
    TaskPriority.low => 'Low',
  };
}
