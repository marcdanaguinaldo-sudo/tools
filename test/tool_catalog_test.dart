import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/models/tool_model.dart';
import 'package:kitchen_tool_scanner/services/tool_catalog.dart';

void main() {
  group('ToolCatalog', () {
    test('filters tools by category and query', () {
      final filtered = ToolCatalog.filterTools(
        kBuiltInTools,
        category: ToolCategories.mixing,
        search: 'whisk',
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, 'whisk');
    });

    test('every category resolves to its own tools', () {
      for (final category in ToolCategories.ordered) {
        final inCategory = ToolCatalog.filterTools(kBuiltInTools,
            category: category, search: '');
        expect(inCategory, isNotEmpty, reason: '$category is empty');
        for (final tool in inCategory) {
          expect(tool.category, category);
        }
      }
      expect(
          ToolCatalog.filterTools(kBuiltInTools,
                  category: ToolCatalog.all, search: '')
              .length,
          kBuiltInTools.length);
    });

    test('search reaches descriptions as well as names', () {
      // "dicing" appears only in a description, never in a tool's name.
      final filtered = ToolCatalog.filterTools(
        kBuiltInTools,
        category: ToolCatalog.all,
        search: 'DICING',
      );

      expect(filtered.map((tool) => tool.id), contains('knife'));
    });

    test('groups every tool under its category', () {
      final grouped = ToolCatalog.groupByCategory(kBuiltInTools);
      final total =
          grouped.values.fold<int>(0, (sum, tools) => sum + tools.length);
      expect(total, kBuiltInTools.length);
      for (final entry in grouped.entries) {
        expect(ToolCategories.ordered, contains(entry.key));
        expect(entry.value, isNotEmpty, reason: 'dead heading ${entry.key}');
      }
    });

    test('matches both English and local tool names case-insensitively', () {
      final filtered = ToolCatalog.filterTools(
        kBuiltInTools,
        category: 'All',
        search: 'KUTSILIO',
      );

      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.first.id, 'knife');
    });
  });
}
