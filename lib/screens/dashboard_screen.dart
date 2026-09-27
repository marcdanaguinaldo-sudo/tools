import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../services/detector.dart';
import '../services/learning_store.dart';
import '../services/tool_catalog.dart';
import '../widgets/tool_artwork.dart';
import 'onboarding_screen.dart';
import 'scanner_screen.dart';
import 'tool_detail_screen.dart';
import 'tutorial_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  String _category = 'All';
  String _query = '';
  bool _favoritesOnly = false;
  bool _checkedOnboarding = false;
  final _search = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedOnboarding) return;
    _checkedOnboarding = true;
    final store = LearningScope.of(context);
    if (!store.onboardingComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        store.finishOnboarding();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openTool(ToolModel tool) {
    LearningScope.of(context).visit(tool);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ToolDetailScreen(tool: tool)));
  }

  @override
  Widget build(BuildContext context) {
    final store = LearningScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFC66D),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.restaurant_rounded,
                  size: 22, color: Color(0xFF14212A))),
          const SizedBox(width: 12),
          const Text('Kusina',
              style:
                  TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.5)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Open scanner',
              icon: const Icon(Icons.document_scanner_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScannerScreen()))),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Library'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
      body: SafeArea(
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _tab == 0
              ? _home(store)
              : _tab == 1
                  ? _library(store)
                  : _settings(store),
        )),
      ),
    );
  }

  Widget _home(LearningStore store) {
    final resume = store.continueTool;
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const Text('A LITTLE PRACTICE. MORE CONFIDENCE.',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: Color(0xFF8AD4B0),
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Know your tools.\nEnjoy your kitchen.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -.8)),
          const SizedBox(height: 12),
          const Text(
              'Simple lessons for safer prep, better technique, and everyday cooking.',
              style: TextStyle(
                  color: Color(0xFFB8C7D0), fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF294438), Color(0xFF1A3029)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF3D5B4C))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.center_focus_strong,
                  color: Color(0xFFFFC66D), size: 32),
              const SizedBox(height: 16),
              Text('Meet your kitchen tools',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                  'Open the scanner or choose a tool to start a guided lesson.',
                  style: TextStyle(color: Color(0xFFD1DFD7), height: 1.5)),
              const SizedBox(height: 18),
              Wrap(spacing: 12, runSpacing: 8, children: [
                FilledButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ScannerScreen())),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Scan a tool')),
                TextButton(
                    onPressed: () => setState(() => _tab = 1),
                    child: const Text('Browse library')),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF152630),
                borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.school_outlined, color: Color(0xFF8AD4B0)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${store.completedCount} of ${kBuiltInTools.length} lessons complete',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                        value: store.completedCount / kBuiltInTools.length,
                        semanticsLabel: 'Completed lessons',
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4)),
                  ])),
            ]),
          ),
          if (store.storageError != null)
            Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(store.storageError!,
                    style: const TextStyle(color: Colors.amber))),
          if (resume != null) ...[
            _section('Continue learning'),
            _toolCard(resume, store, resume: true),
          ],
          _section(store.recentTools.isEmpty
              ? 'Start with the essentials'
              : 'Recently viewed'),
          ...((store.recentTools.isEmpty
                  ? kBuiltInTools.take(3)
                  : store.recentTools.take(3))
              .map((tool) => _toolCard(tool, store))),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.offline_bolt_outlined,
                size: 18, color: Color(0xFF8AD4B0)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    'All ${kBuiltInTools.length} lessons work offline. No account needed.',
                    style: const TextStyle(
                        color: Color(0xFF9BB0BD), fontSize: 12))),
          ]),
        ]);
  }

  Widget _library(LearningStore store) {
    final tools = ToolCatalog.filterTools(kBuiltInTools,
            category: _category, search: _query)
        .where((tool) => !_favoritesOnly || store.isFavorite(tool.id))
        .toList();
    return CustomScrollView(key: const PageStorageKey('library'), slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Your tool library',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Find a tool. Build a skill.',
                    style: TextStyle(color: Color(0xFFB8C7D0))),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search tools or local names',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            }),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      FilterChip(
                          label: const Text('Favorites'),
                          avatar: const Icon(Icons.bookmark_outline, size: 18),
                          selected: _favoritesOnly,
                          onSelected: (value) =>
                              setState(() => _favoritesOnly = value)),
                      const SizedBox(width: 8),
                      for (final category in ToolCatalog.categories)
                        Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                                label: Text(category),
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category))),
                    ])),
                const SizedBox(height: 16),
                Text('${tools.length} ${tools.length == 1 ? 'tool' : 'tools'}',
                    style: const TextStyle(color: Color(0xFF9BB0BD))),
                const SizedBox(height: 12),
              ]))),
      if (tools.isEmpty)
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Icon(Icons.search_off, size: 48, color: Color(0xFF8AD4B0)),
            const SizedBox(height: 16),
            const Text('No tools found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Try a different search, or save tools with the bookmark button.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () {
                  _search.clear();
                  setState(() {
                    _query = '';
                    _category = 'All';
                    _favoritesOnly = false;
                  });
                },
                child: const Text('Reset filters')),
          ]),
        ))
      else
        SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.builder(
                itemCount: tools.length,
                itemBuilder: (_, index) => _toolCard(tools[index], store))),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }

  Widget _toolCard(ToolModel tool, LearningStore store, {bool resume = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (resume) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TutorialScreen(tool: tool)));
            } else {
              _openTool(tool);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              SizedBox(width: 82, child: ToolArtwork(tool: tool, height: 90)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(tool.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Text(
                        resume
                            ? 'Resume at step ${store.stepFor(tool) + 1}'
                            : store.isComplete(tool.id)
                                ? 'Lesson completed'
                                : '${tool.difficulty} · ${tool.steps.length} steps',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: store.isComplete(tool.id)
                                ? const Color(0xFF8AD4B0)
                                : const Color(0xFFB8C7D0))),
                    const SizedBox(height: 4),
                    Text(tool.localName,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9BB0BD))),
                  ])),
              IconButton(
                  tooltip: store.isFavorite(tool.id)
                      ? 'Remove ${tool.name} from favorites'
                      : 'Save ${tool.name}',
                  onPressed: () => store.toggleFavorite(tool.id),
                  icon: Icon(
                      store.isFavorite(tool.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: const Color(0xFFFFC66D))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 14),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge));

  Widget _settings(LearningStore store) =>
      ListView(padding: const EdgeInsets.all(20), children: [
        Text('Make yourself at home',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Your preferences and learning, on this device.',
            style: TextStyle(color: Color(0xFFB8C7D0))),
        _section('Experience'),
        Card(
            child: SwitchListTile(
                title: const Text('Reduce motion'),
                subtitle: const Text(
                    'Hold the 3D demonstration still in guided lessons.'),
                value: store.reduceMotion,
                onChanged: store.setReduceMotion)),
        const SizedBox(height: 12),
        Card(
            child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('How to use Kusina'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OnboardingScreen())))),
        _section('Your learning'),
        Card(
            child: ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reset learning progress'),
                subtitle: const Text('Keep favorites and preferences.'),
                onTap: () async {
                  final reset = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: const Text('Reset your learning?'),
                            content: const Text(
                                'This clears lesson progress, completions, and recently viewed tools on this device.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Keep progress')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Reset progress')),
                            ],
                          ));
                  if (reset == true) store.clearLearning();
                })),
        _section('About Kusina'),
        Card(
            child: ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Open-source licenses'),
          subtitle: const Text('Includes the TensorFlow recognition model.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
              context: context,
              applicationName: 'Kusina',
              applicationVersion: '1.0.0'),
        )),
        const SizedBox(height: 12),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Small skills. Everyday confidence.',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                          '${kBuiltInTools.length} offline kitchen lessons with animated 3D technique guides and safety reminders.',
                          style: const TextStyle(
                              color: Color(0xFFB8C7D0), height: 1.5)),
                      const SizedBox(height: 16),
                      const Text('Privacy',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      const Text(
                          'Favorites and progress stay on your device. The scanner processes frames locally and does not save or upload camera images.',
                          style:
                              TextStyle(color: Color(0xFFB8C7D0), height: 1.5)),
                      const SizedBox(height: 16),
                      const Text('Recognition availability',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      // Derived from the detector so this notice can never drift
                      // away from what the bundled model can actually name.
                      Text(ToolDetector.recognitionScopeNotice,
                          style: const TextStyle(
                              color: Color(0xFFB8C7D0), height: 1.5)),
                      const SizedBox(height: 6),
                      const Text(
                          'Always check the result before starting a lesson.',
                          style:
                              TextStyle(color: Color(0xFFB8C7D0), height: 1.5)),
                      const SizedBox(height: 16),
                      const Text('Kusina · Version 1.0.0',
                          style: TextStyle(
                              color: Color(0xFF9BB0BD), fontSize: 12)),
                    ]))),
      ]);
}
