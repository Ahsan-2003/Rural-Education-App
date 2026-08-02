import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'content_cache_service.dart';

class DownloadService {
  static final _supabase = Supabase.instance.client;

  // Get public URL for a lesson pack
  static String getPackUrl(String subjectId) {
    final lesson_url = '${'lesson-packs/${subjectId}'}';
    return _supabase.storage
        .from(lesson_url)
        .getPublicUrl('${subjectId}_grade5.json');
  }

  // Download a lesson pack
  static Future<Map<String, dynamic>?> downloadPack({
    required String subjectId,
    Function(double progress)? onProgress,
  }) async {
    try {
      final url = getPackUrl(subjectId);
      print('📥 Downloading from: $url');

      // Download the JSON file
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final packData = jsonDecode(response.body) as Map<String, dynamic>;

        // Validate the data
        if (packData['lessons'] == null || packData['subjectId'] == null) {
          print('❌ Invalid pack data');
          return null;
        }

        // Cache locally
        await ContentCacheService.savePack(subjectId, packData);

        print(
          '✅ Downloaded and cached: $subjectId (${response.body.length} bytes)',
        );
        onProgress?.call(1.0);

        return packData;
      } else {
        print('❌ Download failed: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Download error: $e');
      return null;
    }
  }

  // Download multiple packs
  static Future<Map<String, bool>> downloadMultiplePacks({
    required List<String> subjectIds,
    Function(String subjectId, double progress)? onProgress,
  }) async {
    final results = <String, bool>{};

    for (final subjectId in subjectIds) {
      onProgress?.call(subjectId, 0.0);
      final pack = await downloadPack(
        subjectId: subjectId,
        onProgress: (progress) => onProgress?.call(subjectId, progress),
      );
      results[subjectId] = pack != null;
    }

    return results;
  }

  // Check if pack is available on server (HEAD request)
  static Future<bool> isPackAvailable(String subjectId) async {
    try {
      final url = getPackUrl(subjectId);
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get pack metadata without downloading full content
  static Future<Map<String, dynamic>?> getPackMetadata(String subjectId) async {
    try {
      final url = getPackUrl(subjectId);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'subjectId': data['subjectId'],
          'subjectName': data['subjectName'],
          'icon': data['icon'],
          'version': data['version'],
          'description': data['description'],
          'lessonCount': (data['lessons'] as List).length,
          'sizeBytes': response.body.length,
        };
      }
    } catch (e) {
      print('❌ Failed to get metadata: $e');
    }
    return null;
  }
}
