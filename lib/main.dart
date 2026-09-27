import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'screens/dashboard_screen.dart';
import 'services/learning_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['TensorFlow SSD MobileNet V1 model'],
      await rootBundle.loadString('assets/models/LICENSE-2.0.txt'),
    );
  });
  await LearningStore.instance.load();

  // Enforce portrait orientation for optimal camera alignment
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const KitchenToolScannerApp());
}

class KitchenToolScannerApp extends StatelessWidget {
  final LearningStore? store;
  const KitchenToolScannerApp({super.key, this.store});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFC66D),
      brightness: Brightness.dark,
      surface: const Color(0xFF14232D),
    );

    return LearningScope(
        store: store ?? LearningStore.instance,
        child: MaterialApp(
          title: 'Kusina',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0C1922),
            fontFamily: 'Roboto',
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0C1922),
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFC66D),
                foregroundColor: const Color(0xFF241D12),
                minimumSize: const Size(48, 52),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF11212C),
              indicatorColor: const Color(0xFF354536),
              labelTextStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF192C38),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(16),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF142630),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              margin: EdgeInsets.zero,
            ),
            chipTheme: const ChipThemeData(
              backgroundColor: Color(0xFF1E293B),
              selectedColor: Color(0xFF425238),
              side: BorderSide(color: Color(0xFF334155)),
              labelStyle: TextStyle(color: Colors.white70),
              secondaryLabelStyle: TextStyle(color: Color(0xFFFFE3B5)),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          home: const DashboardScreen(),
        ));
  }
}
