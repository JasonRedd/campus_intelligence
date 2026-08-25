class TaskItem {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'schedule', 'deadline', 'change'
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    this.isCompleted = false,
  });
}