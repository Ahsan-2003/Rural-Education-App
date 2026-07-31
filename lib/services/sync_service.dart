import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/student_profile.dart';
import 'database_service.dart';

class SyncService {
  static final _supabase = Supabase.instance.client;

  // Singleton
  SyncService._();
  static final SyncService _instance = SyncService._();
  factory SyncService() => _instance;

  // =============================================
  // CHECK CONNECTIVITY
  // =============================================
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // =============================================
  // SYNC PROFILE TO SUPABASE
  // =============================================
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

  // =============================================
  // SYNC ALL PENDING EVENTS
  // =============================================
  static Future<int> syncPendingEvents() async {
    // Check if online first
    final online = await isOnline();
    if (!online) {
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
        // Upsert event to Supabase (idempotent by event ID)
        await _supabase.from('progress_events').upsert({
          'id': event['id'],
          'student_id': event['studentId'],
          'event_type': event['type'],
          'lesson_id': event['lessonId'],
          'payload': event['payload'] ?? {},
          'client_created_at': event['createdAt'],
          'server_received_at': DateTime.now().toIso8601String(),
        });

        // Mark as synced locally
        await DatabaseService.markEventAsSynced(event['id']);
        syncedCount++;
        print('  ✅ Synced: ${event['type']} - ${event['lessonId']}');
      } catch (e) {
        print('  ❌ Failed to sync event ${event['id']}: $e');
        // Stop on first failure to maintain order
        break;
      }
    }

    print('✅ Sync complete: $syncedCount/${unsyncedEvents.length} events');
    return syncedCount;
  }

  // =============================================
  // FULL SYNC (Profile + Events)
  // =============================================
  static Future<Map<String, dynamic>> syncAll(String? studentId) async {
    final result = {
      'profile_synced': false,
      'events_synced': 0,
      'error': null as String?,
    };

    try {
      final online = await isOnline();
      if (!online) {
        result['error'] = 'No internet connection';
        return result;
      }

      // Sync profile if studentId provided
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

  // =============================================
  // GET STUDENT PROGRESS FROM SUPABASE
  // =============================================
  static Future<List<Map<String, dynamic>>> getStudentProgress(
    String studentId,
  ) async {
    try {
      final data = await _supabase
          .from('progress_events')
          .select()
          .eq('student_id', studentId)
          .order('client_created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Failed to get progress: $e');
      return [];
    }
  }

  // =============================================
  // GET STUDENT FROM SUPABASE
  // =============================================
  static Future<Map<String, dynamic>?> getStudentFromServer(
    String studentId,
  ) async {
    try {
      final data = await _supabase
          .from('students')
          .select()
          .eq('id', studentId)
          .maybeSingle();

      return data;
    } catch (e) {
      print('❌ Failed to get student: $e');
      return null;
    }
  }
}
