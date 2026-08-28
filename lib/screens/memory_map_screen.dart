import 'package:flutter/material.dart';

import '../models/campus_knowledge.dart';
import '../services/campus_knowledge_service.dart';

class MemoryMapScreen extends StatefulWidget {
  const MemoryMapScreen({super.key});

  @override
  State<MemoryMapScreen> createState() => _MemoryMapScreenState();
}

class _MemoryMapScreenState extends State<MemoryMapScreen> {
  final _searchController = TextEditingController();
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddKnowledge() async {
    final title = TextEditingController();
    final content = TextEditingController();
    final category = TextEditingController(text: 'General');
    final sources = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add campus knowledge',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: content, maxLines: 5, decoration: const InputDecoration(labelText: 'Knowledge or update')),
              TextField(controller: sources, decoration: const InputDecoration(labelText: 'Sources (comma separated)')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (title.text.trim().isEmpty || content.text.trim().isEmpty) return;
                  await CampusKnowledgeService.addKnowledge(
                    title: title.text.trim(),
                    content: content.text.trim(),
                    category: category.text.trim().isEmpty ? 'General' : category.text.trim(),
                    sources: sources.text.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
                    isPublic: true,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Publish to campus'),
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    content.dispose();
    category.dispose();
    sources.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('MemoryMap')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddKnowledge,
        icon: const Icon(Icons.add),
        label: const Text('Add knowledge'),
      ),
      body: StreamBuilder<List<CampusKnowledge>>(
        stream: CampusKnowledgeService.watchKnowledge(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final query = _searchController.text.toLowerCase();
          final categories = ['All', ...snapshot.data!.map((item) => item.category).toSet()];
          final items = snapshot.data!.where((item) =>
              (_category == 'All' || item.category == _category) &&
              (item.title.toLowerCase().contains(query) ||
                  item.content.toLowerCase().contains(query))).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Text('Trusted campus memory',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search campus knowledge...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((value) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value),
                      selected: _category == value,
                      onSelected: (_) => setState(() => _category = value),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty) const Text('No campus knowledge matches your search.'),
              ...items.map((item) => _KnowledgeCard(knowledge: item)),
            ],
          );
        },
      ),
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final CampusKnowledge knowledge;
  const _KnowledgeCard({required this.knowledge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = knowledge.verification != KnowledgeVerification.unverified;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.primary.withAlpha(70)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(knowledge.title),
            content: SingleChildScrollView(child: Text(knowledge.content)),
            actions: [
              TextButton(
                onPressed: () async {
                  await CampusKnowledgeService.verify(knowledge);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Verify'),
              ),
              TextButton(
                onPressed: () async {
                  await CampusKnowledgeService.report(knowledge);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Report conflict'),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(knowledge.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                  Icon(verified ? Icons.verified : Icons.pending_outlined,
                      color: verified ? theme.colorScheme.secondary : theme.colorScheme.tertiary),
                ],
              ),
              const SizedBox(height: 8),
              Text(knowledge.content, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(knowledge.category)),
                  Chip(label: Text('Trust ${(knowledge.trustScore * 100).round()}%')),
                  if (knowledge.hasConflict) const Chip(label: Text('Conflict flagged')),
                ],
              ),
              Text('By ${knowledge.authorName} • ${knowledge.sources.length} source(s)'),
            ],
          ),
        ),
      ),
    );
  }
}
