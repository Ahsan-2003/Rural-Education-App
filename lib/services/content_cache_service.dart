import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class ContentCacheService {
  static late Box _cacheBox;
  static bool _initialized = false;

  // Initialize
  static Future<void> init() async {
    if (_initialized) return;
    _cacheBox = await Hive.openBox('content_cache');
    _initialized = true;
    print('✅ Content cache initialized');
  }

  // Save a lesson pack to local cache
  static Future<void> savePack(
    String subjectId,
    Map<String, dynamic> packData,
  ) async {
    print('💾 Saving pack: $subjectId');
    print('  Keys: ${packData.keys}');
    print('  Lessons count: ${(packData['lessons'] as List?)?.length ?? 0}');

    await _cacheBox.put('pack_$subjectId', {
      'data': jsonEncode(packData),
      'downloadedAt': DateTime.now().toIso8601String(),
      'version': packData['version'] ?? 1,
    });

    // Verify it was saved
    final saved = _cacheBox.get('pack_$subjectId');
    print('  Saved: ${saved != null}');
    print('✅ Cached pack: $subjectId');
  }

  // Get a cached lesson pack
  static Map<String, dynamic>? getCachedPack(String subjectId) {
    final cached = _cacheBox.get('pack_$subjectId');
    if (cached == null) return null;

    try {
      final data = Map<String, dynamic>.from(cached);
      data['data'] = jsonDecode(data['data']);
      return data;
    } catch (e) {
      print('❌ Failed to decode cached pack: $e');
      return null;
    }
  }

  // Check if a pack is cached
  static bool isPackCached(String subjectId) {
    return _cacheBox.containsKey('pack_$subjectId');
  }

  // Get all cached packs info
  static List<Map<String, dynamic>> getAllCachedPacks() {
    final packs = <Map<String, dynamic>>[];
    for (final key in _cacheBox.keys) {
      if (key.toString().startsWith('pack_')) {
        final cached = _cacheBox.get(key);
        if (cached != null) {
          final subjectId = key.toString().replaceFirst('pack_', '');
          packs.add({
            'subjectId': subjectId,
            'downloadedAt': cached['downloadedAt'],
            'version': cached['version'],
          });
        }
      }
    }
    return packs;
  }

  // Delete a cached pack (free up space)
  static Future<void> deletePack(String subjectId) async {
    await _cacheBox.delete('pack_$subjectId');
    print('🗑️ Deleted cached pack: $subjectId');
  }

  // Get total cache size (approximate)
  static int getCacheSize() {
    int size = 0;
    for (final key in _cacheBox.keys) {
      final value = _cacheBox.get(key);
      if (value != null) {
        size += value.toString().length;
      }
    }
    return size; // in bytes (approximate)
  }

  // Format size for display
  static String getFormattedCacheSize() {
    final bytes = getCacheSize();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    final keys = _cacheBox.keys
        .where((k) => k.toString().startsWith('pack_'))
        .toList();
    for (final key in keys) {
      await _cacheBox.delete(key);
    }
    print('🗑️ All cache cleared');
  }

  // ==========================================
  // NEW: VERSION TRACKING
  // ==========================================

  // Get cached version of a pack
  static int getCachedVersion(String subjectId) {
    final cached = _cacheBox.get('pack_$subjectId');
    if (cached == null) return 0;
    return cached['version'] ?? 0;
  }

  // Get server version (from cached metadata)
  static int getServerVersion(String subjectId) {
    final metadata = _cacheBox.get('metadata_$subjectId');
    if (metadata == null) return 0;
    return metadata['version'] ?? 0;
  }

  // Save pack metadata (from server, without full content)
  static Future<void> saveMetadata(
    String subjectId,
    Map<String, dynamic> metadata,
  ) async {
    await _cacheBox.put('metadata_$subjectId', {
      'version': metadata['version'] ?? 1,
      'lessonCount': metadata['lessonCount'] ?? 0,
      'sizeBytes': metadata['sizeBytes'] ?? 0,
      'checkedAt': DateTime.now().toIso8601String(),
    });
    print('📋 Metadata saved: $subjectId v${metadata['version']}');
  }

  // Check if update is available
  static bool isUpdateAvailable(String subjectId) {
    final cachedVersion = getCachedVersion(subjectId);
    final serverVersion = getServerVersion(subjectId);
    return serverVersion > cachedVersion;
  }

  // Get all packs that need updating
  static List<String> getPacksNeedingUpdate() {
    final needsUpdate = <String>[];
    final subjects = ['math', 'science', 'english', 'history'];

    for (final subjectId in subjects) {
      if (isUpdateAvailable(subjectId)) {
        needsUpdate.add(subjectId);
      }
    }
    return needsUpdate;
  }
}
