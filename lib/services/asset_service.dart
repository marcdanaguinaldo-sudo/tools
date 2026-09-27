import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tool_model.dart';

/// Phase 5: Asset Service
/// Responsible for:
/// 1. Managing the list of kitchen tools (built-in offline fallback + optional cloud sync)
/// 2. Downloading & caching 3D model assets locally using dio & path_provider
class AssetService {
  static final AssetService _instance = AssetService._internal();
  factory AssetService() => _instance;
  AssetService._internal();

  final Dio _dio = Dio();
  List<ToolModel> _tools = List.from(kBuiltInTools);

  List<ToolModel> get tools => List.unmodifiable(_tools);

  /// Synchronize tool definitions with Cloud Firestore if available,
  /// gracefully falling back to kBuiltInTools if offline or Firebase not configured.
  Future<void> syncToolsFromCloud() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('kitchen_tools')
          .get(const GetOptions(source: Source.serverAndCache));

      if (snapshot.docs.isNotEmpty) {
        final cloudTools = snapshot.docs.map((doc) {
          final data = doc.data();
          final rawSteps = data['steps'] as List<dynamic>? ?? [];
          final steps = rawSteps
              .map((s) => ToolStep(
                    stepNumber: s['stepNumber'] ?? 1,
                    title: s['title'] ?? '',
                    instruction: s['instruction'] ?? '',
                    gripTip: s['gripTip'] ?? '',
                    targetAngle: s['targetAngle'] ?? '',
                  ))
              .toList();

          return ToolModel(
            id: doc.id,
            name: data['name'] ?? '',
            localName: data['localName'] ?? '',
            category: data['category'] ?? 'Cutting & Prep',
            difficulty: data['difficulty'] ?? 'Beginner',
            description: data['description'] ?? '',
            safetyTip: data['safetyTip'] ?? '',
            classId: data['classId'] is int ? data['classId'] : null,
            minutes: (data['minutes'] as num?)?.toInt() ?? 3,
            warnings: List<String>.from(data['warnings'] ?? []),
            steps: steps,
          );
        }).toList();

        _tools = cloudTools;
      }
    } catch (e) {
      // Offline fallback: keep built-in tools list
      _tools = List.from(kBuiltInTools);
    }
  }

  /// Downloads a 3D model file from remote URL and caches it in the local documents directory.
  /// Skips downloading if the file already exists on device.
  Future<File?> getOrDownloadModelFile(String toolId, String remoteUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }

      final localFile = File('${modelsDir.path}/$toolId.glb');
      if (await localFile.exists()) {
        return localFile;
      }

      // Download file with dio
      final response = await _dio.download(
        remoteUrl,
        localFile.path,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && await localFile.exists()) {
        return localFile;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if 3D model is cached locally
  Future<bool> isModelCached(String toolId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final localFile = File('${dir.path}/models/$toolId.glb');
      return await localFile.exists();
    } catch (_) {
      return false;
    }
  }
}
