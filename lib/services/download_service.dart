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

  // ==========================================
  // NEW: CHECK FOR UPDATES
  // ==========================================

  // Check server version without downloading full content
  static Future<int> checkServerVersion(String subjectId) async {
    try {
      final url = getPackUrl(subjectId);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final version = data['version'] as int? ?? 1;
        final lessonCount = (data['lessons'] as List?)?.length ?? 0;

        // Save metadata for future checks
        await ContentCacheService.saveMetadata(subjectId, {
          'version': version,
          'lessonCount': lessonCount,
          'sizeBytes': response.body.length,
        });

        print(
          '🔍 Server version for $subjectId: v$version ($lessonCount lessons)',
        );
        return version;
      }
      return 0;
    } catch (e) {
      print('❌ Failed to check version: $e');
      return 0;
    }
  }

  // Check all packs for updates
  static Future<Map<String, bool>> checkForUpdates() async {
    final subjects = ['math', 'science', 'english', 'history'];
    final updates = <String, bool>{};

    print('🔍 Checking for updates...');

    for (final subjectId in subjects) {
      await checkServerVersion(subjectId);
      updates[subjectId] = ContentCacheService.isUpdateAvailable(subjectId);
    }

    final updateCount = updates.values.where((v) => v).length;
    print('📊 Update check complete: $updateCount packs need updating');

    return updates;
  }

  // ==========================================
  // DELTA DOWNLOAD
  // ==========================================

  // Download only if newer version available
  static Future<Map<String, dynamic>?> downloadPackIfNeeded({
    required String subjectId,
    Function(double progress)? onProgress,
  }) async {
    // Check if update is available
    final isCached = ContentCacheService.isPackCached(subjectId);

    if (isCached) {
      await checkServerVersion(subjectId);
      final needsUpdate = ContentCacheService.isUpdateAvailable(subjectId);

      if (!needsUpdate) {
        print('✅ $subjectId already up to date');
        onProgress?.call(1.0);
        return ContentCacheService.getCachedPack(subjectId)?['data'];
      }

      print('🔄 Update available for $subjectId');
    }

    // Download full pack (or delta if we had previous version)
    return await downloadPack(subjectId: subjectId, onProgress: onProgress);
  }

  // Download a lesson pack
  static Future<Map<String, dynamic>?> downloadPack({
    required String subjectId,
    Function(double progress)? onProgress,
  }) async {
    try {
      final url = getPackUrl(subjectId);
      print('📥 Downloading: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final packData = jsonDecode(response.body) as Map<String, dynamic>;

        if (packData['lessons'] == null || packData['subjectId'] == null) {
          print('❌ Invalid pack data');
          return null;
        }

        // Save metadata
        await ContentCacheService.saveMetadata(subjectId, {
          'version': packData['version'] ?? 1,
          'lessonCount': (packData['lessons'] as List).length,
          'sizeBytes': response.body.length,
        });

        // Cache the pack
        await ContentCacheService.savePack(subjectId, packData);

        final version = packData['version'] ?? 1;
        print(
          '✅ Downloaded $subjectId v$version (${response.body.length} bytes)',
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

  // Download only packs that need updates
  static Future<Map<String, int>> updateAllPacks({
    Function(String subjectId, double progress)? onProgress,
  }) async {
    print('🔄 Checking for updates before download...');

    // First, check all versions
    await checkForUpdates();

    final results = <String, int>{};
    final subjects = ['math', 'science', 'english', 'history'];
    final needsUpdate = ContentCacheService.getPacksNeedingUpdate();
    final notCached = subjects
        .where((s) => !ContentCacheService.isPackCached(s))
        .toList();
    final toDownload = {...needsUpdate, ...notCached}.toList();

    if (toDownload.isEmpty) {
      print('✅ All packs are up to date!');
      return {'updated': 0, 'skipped': subjects.length};
    }

    print('📥 Downloading ${toDownload.length} packs...');
    int updated = 0;
    int skipped = 0;

    for (final subjectId in subjects) {
      if (toDownload.contains(subjectId)) {
        onProgress?.call(subjectId, 0.0);
        final result = await downloadPack(
          subjectId: subjectId,
          onProgress: (p) => onProgress?.call(subjectId, p),
        );
        if (result != null) {
          updated++;
        }
      } else {
        print('⏭️ Skipping $subjectId (already latest)');
        skipped++;
      }
    }

    print('✅ Update complete: $updated downloaded, $skipped skipped');
    return {'updated': updated, 'skipped': skipped};
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
