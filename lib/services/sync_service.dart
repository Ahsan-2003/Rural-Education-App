import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  // Singleton
  SyncService._();
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;

  // Check if online using ConnectivityService singleton
  static bool isOnline() {
    return ConnectivityService().isOnline;
  }

  // Sync profile to Supabase
  static Future<bool> syncProfile(StudentProfile profile) async {
    try {
      await _supabase.from('students').upsert({
        'id': profile.id,
        'name': profile.name,
        'pin_hash': profile.pin,
        'class_code': profile.classCode,
        'created_at': profile.createdAt.toIso8601String(),
        'last_synced_at': DateTime.now().toIso8601String(),
      });
      print('✅ Profile synced: ${profile.name}');
      return true;
    } catch (e) {
      print('❌ Profile sync failed: $e');
      return false;
    }
  }

  // Sync all pending events
  static Future<int> syncPendingEvents() async {
    // Check if online first
    if (!isOnline()) {
      print('📴 Offline - skipping sync');
      return 0;
    }

    final unsyncedEvents = DatabaseService.getUnsyncedEvents();
    if (unsyncedEvents.isEmpty) {
      print('✅ No pending events to sync');
      return 0;
    }

    print('🔄 Syncing ${unsyncedEvents.length} events...');
    int syncedCount = 0;

    for (final event in unsyncedEvents) {
      try {
        await _supabase.from('progress_events').upsert({
          'id': event['id'],
          'student_id': event['studentId'],
          'event_type': event['type'],
          'lesson_id': event['lessonId'],
          'payload': event['payload'] ?? {},
          'client_created_at': event['createdAt'],
          'server_received_at': DateTime.now().toIso8601String(),
        });

        await DatabaseService.markEventAsSynced(event['id']);
        syncedCount++;
        print('  ✅ Synced: ${event['type']} - ${event['lessonId']}');
      } catch (e) {
        print('  ❌ Failed: ${event['id']}: $e');
        break;
      }
    }

    print('✅ Sync complete: $syncedCount/${unsyncedEvents.length}');
    return syncedCount;
  }

  // Full sync
  static Future<Map<String, dynamic>> syncAll(String? studentId) async {
    final result = {
      'profile_synced': false,
      'events_synced': 0,
      'error': null as String?,
    };

    try {
      if (!isOnline()) {
        result['error'] = 'You are offline';
        return result;
      }

      // Sync profile
      if (studentId != null) {
        final profile = DatabaseService.getProfile(studentId);
        if (profile != null) {
          result['profile_synced'] = await syncProfile(profile);
        }
      }

      // Sync events
      result['events_synced'] = await syncPendingEvents();
    } catch (e) {
      result['error'] = e.toString();
      print('❌ Sync failed: $e');
    }

    return result;
  }
}
