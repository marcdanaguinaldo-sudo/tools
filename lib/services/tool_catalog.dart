import '../models/tool_model.dart';

class ToolCatalog {
  static const String all = 'All';

  static List<String> get categories => [all, ...ToolCategories.ordered];

  static List<ToolModel> filterTools(
    List<ToolModel> tools, {
    required String category,
    required String search,
  }) {
    final query = search.trim().toLowerCase();

    return tools.where((tool) {
      final matchesCategory = category == all || tool.category == category;
      final searchText =
          '${tool.name} ${tool.localName} ${tool.id} ${tool.description}'
              .toLowerCase();
      final matchesSearch = query.isEmpty || searchText.contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Tools grouped by [ToolCategories.ordered], skipping empty categories so
  /// the manual picker never renders a dead heading.
  static Map<String, List<ToolModel>> groupByCategory(List<ToolModel> tools) {
    final grouped = <String, List<ToolModel>>{};
    for (final category in ToolCategories.ordered) {
      final matches =
          tools.where((tool) => tool.category == category).toList(growable: false);
      if (matches.isNotEmpty) grouped[category] = matches;
    }
    return grouped;
  }
}
