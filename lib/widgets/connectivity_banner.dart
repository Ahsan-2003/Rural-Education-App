import 'package:flutter/material.dart';

class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final int unsyncedCount;
  final VoidCallback? onSyncTap;

  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    required this.unsyncedCount,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    // Offline
    if (!isOnline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        color: Colors.red.shade100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            const Text(
              'You are offline - App works fully offline! 📴',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Online with unsynced data
    if (unsyncedCount > 0) {
      return GestureDetector(
        onTap: onSyncTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: Colors.orange.shade100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '$unsyncedCount items pending - Tap to sync 🔄',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Online and synced
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.green.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_done, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 6),
          Text(
            'Online - All synced ✅',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
