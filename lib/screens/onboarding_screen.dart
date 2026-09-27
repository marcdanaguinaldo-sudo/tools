import 'package:flutter/material.dart';
import '../models/tool_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  // Not const: the copy interpolates the live catalogue size.
  static final _pages = [
    (
      icon: Icons.restaurant_rounded,
      title: 'A little practice.\nA better kitchen.',
      body:
          '${kBuiltInTools.length} everyday tools with clear, animated lessons. Start with a tool you already have.',
      label: 'WELCOME TO KUSINA'
    ),
    (
      icon: Icons.menu_book_rounded,
      title: 'Learn at\nyour own pace.',
      body:
          'Follow each step, pause or orbit the 3D demonstration, and pick up where you left off. Every lesson works offline.',
      label: 'SMALL STEPS, USEFUL SKILLS'
    ),
    (
      icon: Icons.shield_outlined,
      title: 'Build confidence.\nKeep safety first.',
      body:
          'Read the safety reminders before you begin. Save your favorite tools and return whenever you need a refresher.',
      label: 'READY WHEN YOU ARE'
    ),
  ];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: Column(children: [
          Align(
              alignment: Alignment.centerRight,
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip introduction')))),
          Expanded(
              child: PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Center(
                  child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color(0xFF355842),
                                  Color(0xFF1E352C)
                                ]),
                                borderRadius: BorderRadius.circular(36)),
                            child: Icon(page.icon,
                                size: 64, color: const Color(0xFFFFC66D))),
                        const SizedBox(height: 36),
                        Text(page.label,
                            style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.5,
                                color: Color(0xFF8AD4B0),
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Text(page.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w800, height: 1.2)),
                        const SizedBox(height: 20),
                        Text(page.body,
                            style: const TextStyle(
                                fontSize: 17,
                                height: 1.6,
                                color: Color(0xFFB8C7D0))),
                      ]),
                ),
              ));
            },
          )),
          Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
              child: Column(children: [
                Semantics(
                    label: 'Introduction page ${_page + 1} of 3',
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: i == _page ? 26 : 8,
                                decoration: BoxDecoration(
                                    color: i == _page
                                        ? const Color(0xFFFFC66D)
                                        : const Color(0xFF354955),
                                    borderRadius: BorderRadius.circular(8))),
                        ])),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (_page == 2) {
                          Navigator.pop(context);
                        } else {
                          _controller.nextPage(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 250),
                              curve: Curves.easeOut);
                        }
                      },
                      child:
                          Text(_page == 2 ? 'Explore the tools' : 'Continue'),
                    )),
              ])),
        ])),
      );
}
