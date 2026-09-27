import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../services/learning_store.dart';
import '../widgets/tool_artwork.dart';
import 'tutorial_screen.dart';

class ToolDetailScreen extends StatelessWidget {
  final ToolModel tool;
  const ToolDetailScreen({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    final store = LearningScope.of(context);
    final completed = store.isComplete(tool.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Explore a tool'), actions: [
        IconButton(
            tooltip: store.isFavorite(tool.id)
                ? 'Remove from favorites'
                : 'Save to favorites',
            onPressed: () => store.toggleFavorite(tool.id),
            icon: Icon(store.isFavorite(tool.id)
                ? Icons.bookmark
                : Icons.bookmark_border)),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              onPressed: () {
                store.visit(tool);
                if (completed) store.restart(tool);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TutorialScreen(tool: tool)));
              },
              icon: Icon(completed ? Icons.replay : Icons.play_arrow_rounded),
              label: Text(completed
                  ? 'Practice again'
                  : store.hasStarted(tool.id)
                      ? 'Continue lesson'
                      : 'Start guided lesson'),
            )),
      ),
      body: SafeArea(
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ToolArtwork(tool: tool, height: 240),
                const SizedBox(height: 24),
                Text(tool.category.toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF8AD4B0),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(tool.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(tool.localName,
                    style: const TextStyle(color: Color(0xFF9BB0BD))),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  Chip(label: Text(tool.difficulty)),
                  Chip(label: Text('${tool.steps.length} guided steps')),
                  if (completed)
                    const Chip(
                        avatar: Icon(Icons.check_circle_outline, size: 18),
                        label: Text('Completed')),
                ]),
                const SizedBox(height: 16),
                Text(tool.description,
                    style: const TextStyle(
                        fontSize: 16, height: 1.6, color: Color(0xFFB8C7D0))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF30291D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6B5431))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.shield_outlined, color: Color(0xFFFFC66D)),
                          SizedBox(width: 10),
                          Text('Before you begin',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFC66D))),
                        ]),
                        const SizedBox(height: 12),
                        Text(tool.safetyTip,
                            style: const TextStyle(height: 1.5)),
                        for (final warning in tool.warnings)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('•  ',
                                        style: TextStyle(
                                            color: Color(0xFFFFC66D))),
                                    Expanded(
                                        child: Text(warning,
                                            style: const TextStyle(
                                                color: Color(0xFFD0C8B9),
                                                height: 1.5))),
                                  ])),
                      ]),
                ),
                const SizedBox(height: 28),
                Text('What you’ll learn',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (var i = 0; i < tool.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF253C37),
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF8AD4B0)))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text(
                                      tool.steps[i].title.replaceFirst(
                                          RegExp(r'^\d+\.\s*'), ''),
                                      style: const TextStyle(height: 1.4)))),
                        ]),
                  ),
              ]),
        )),
      ),
    );
  }
}
