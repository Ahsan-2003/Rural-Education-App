import 'package:flutter/material.dart';
import 'package:rural_education_app/services/download_service.dart';
import 'package:rural_education_app/services/content_cache_service.dart';

class DownloadScreen extends StatefulWidget {
  final VoidCallback? onDownloadsComplete;

  const DownloadScreen({super.key, this.onDownloadsComplete});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final Map<String, bool> _downloadStatus = {};
  final Map<String, double> _downloadProgress = {};
  bool _isDownloading = false;
  bool _isCheckingUpdates = true;
  String _statusMessage = '';
  final List<Map<String, dynamic>> _packs = [];

  @override
  void initState() {
    super.initState();
    _loadPackInfo();
  }

  // ==========================================
  // LOAD PACK INFO WITH VERSIONS
  // ==========================================
  Future<void> _loadPackInfo() async {
    setState(() {
      _isCheckingUpdates = true;
      _statusMessage = '🔍 Checking for updates...';
    });

    // Check for updates first
    await DownloadService.checkForUpdates();

    final subjects = [
      {'id': 'math', 'name': 'Mathematics', 'icon': '📐'},
      {'id': 'science', 'name': 'Science', 'icon': '🔬'},
      {'id': 'english', 'name': 'English', 'icon': '📖'},
      {'id': 'history', 'name': 'History', 'icon': '🏛️'},
    ];

    _packs.clear();
    _downloadStatus.clear();
    _downloadProgress.clear();

    for (final s in subjects) {
      final subjectId = s['id'] as String;
      final isCached = ContentCacheService.isPackCached(subjectId);
      final cachedVersion = ContentCacheService.getCachedVersion(subjectId);
      final serverVersion = ContentCacheService.getServerVersion(subjectId);
      final needsUpdate = ContentCacheService.isUpdateAvailable(subjectId);

      _packs.add({
        ...s,
        'isCached': isCached,
        'cachedVersion': cachedVersion,
        'serverVersion': serverVersion,
        'needsUpdate': needsUpdate,
      });

      _downloadStatus[subjectId] = isCached;
      if (isCached) {
        _downloadProgress[subjectId] = 1.0;
      }
    }

    // Count updates available
    final updateCount = _packs.where((p) => p['needsUpdate'] == true).length;
    final notDownloadedCount = _packs
        .where((p) => p['isCached'] == false)
        .length;

    setState(() {
      _isCheckingUpdates = false;
      if (updateCount > 0 && notDownloadedCount == 0) {
        _statusMessage = '🔄 $updateCount pack(s) have updates available!';
      } else if (notDownloadedCount > 0) {
        _statusMessage = '📥 $notDownloadedCount pack(s) need to be downloaded';
      } else {
        _statusMessage = '✅ All packs are up to date!';
      }
    });

    print(
      '📊 Packs loaded: ${_packs.length} total, $updateCount updates, $notDownloadedCount not downloaded',
    );
  }

  // ==========================================
  // DOWNLOAD SINGLE PACK
  // ==========================================
  Future<void> _downloadPack(String subjectId) async {
    if (_isDownloading) return;

    final pack = _packs.firstWhere((p) => p['id'] == subjectId);
    final isUpdate = pack['needsUpdate'] == true;

    setState(() {
      _isDownloading = true;
      _downloadProgress[subjectId] = 0.0;
      _statusMessage = isUpdate
          ? '🔄 Updating ${_getPackName(subjectId)}...'
          : '📥 Downloading ${_getPackName(subjectId)}...';
    });

    final result = await DownloadService.downloadPack(
      subjectId: subjectId,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress[subjectId] = progress;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _downloadStatus[subjectId] = result != null;
      _isDownloading = false;
      _statusMessage = result != null
          ? '✅ ${_getPackName(subjectId)} ${isUpdate ? 'updated' : 'downloaded'}!'
          : '❌ Failed to download ${_getPackName(subjectId)}';
    });

    // Refresh pack info after download
    await _refreshSinglePack(subjectId);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onDownloadsComplete?.call();
    }
  }

  // ==========================================
  // REFRESH SINGLE PACK INFO
  // ==========================================
  Future<void> _refreshSinglePack(String subjectId) async {
    final isCached = ContentCacheService.isPackCached(subjectId);
    final cachedVersion = ContentCacheService.getCachedVersion(subjectId);
    final serverVersion = ContentCacheService.getServerVersion(subjectId);
    final needsUpdate = ContentCacheService.isUpdateAvailable(subjectId);

    final index = _packs.indexWhere((p) => p['id'] == subjectId);
    if (index >= 0) {
      _packs[index]['isCached'] = isCached;
      _packs[index]['cachedVersion'] = cachedVersion;
      _packs[index]['serverVersion'] = serverVersion;
      _packs[index]['needsUpdate'] = needsUpdate;
    }

    _downloadStatus[subjectId] = isCached;
    if (isCached) {
      _downloadProgress[subjectId] = 1.0;
    }

    setState(() {});
  }

  // ==========================================
  // DOWNLOAD ALL (only needed ones)
  // ==========================================
  Future<void> _downloadAll() async {
    if (_isDownloading) return;

    // Get packs that need downloading (not cached OR need update)
    final toDownload = _packs
        .where((p) => p['isCached'] == false || p['needsUpdate'] == true)
        .toList();

    if (toDownload.isEmpty) {
      setState(() => _statusMessage = '✅ All packs are already up to date!');
      return;
    }

    setState(() {
      _isDownloading = true;
      _statusMessage = '📥 Downloading ${toDownload.length} pack(s)...';
    });

    int downloaded = 0;
    for (final pack in toDownload) {
      final subjectId = pack['id'] as String;
      final isUpdate = pack['needsUpdate'] == true;

      setState(() {
        _downloadProgress[subjectId] = 0.0;
        _statusMessage = isUpdate
            ? '🔄 Updating ${_getPackName(subjectId)}... (${downloaded + 1}/${toDownload.length})'
            : '📥 Downloading ${_getPackName(subjectId)}... (${downloaded + 1}/${toDownload.length})';
      });

      final result = await DownloadService.downloadPack(
        subjectId: subjectId,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[subjectId] = progress;
            });
          }
        },
      );

      if (result != null) {
        _downloadStatus[subjectId] = true;
        downloaded++;
      }

      await _refreshSinglePack(subjectId);
    }

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
      _statusMessage = downloaded == toDownload.length
          ? '✅ All packs downloaded successfully!'
          : '⚠️ Downloaded $downloaded of ${toDownload.length} packs';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusMessage),
          backgroundColor: downloaded == toDownload.length
              ? Colors.green
              : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onDownloadsComplete?.call();
    }
  }

  // ==========================================
  // DELETE PACK
  // ==========================================
  Future<void> _deletePack(String subjectId) async {
    await ContentCacheService.deletePack(subjectId);
    await _refreshSinglePack(subjectId);
    setState(() {
      _statusMessage = '🗑️ ${_getPackName(subjectId)} deleted';
    });
  }

  String _getPackName(String id) {
    try {
      return _packs.firstWhere((p) => p['id'] == id)['name'] as String;
    } catch (e) {
      return id;
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final allDownloaded = _downloadStatus.values.every((s) => s);
    final downloadedCount = _downloadStatus.values.where((s) => s).length;
    final updateCount = _packs.where((p) => p['needsUpdate'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Lessons'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isDownloading ? null : _loadPackInfo,
            tooltip: 'Check for updates',
          ),
        ],
      ),
      body: _isCheckingUpdates
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking for updates...'),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.cloud_download,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Download Manager',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (updateCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$updateCount update${updateCount > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$downloadedCount of ${_packs.length} packs downloaded',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cache size: ${ContentCacheService.getFormattedCacheSize()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status message
                if (_statusMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: _statusMessage.contains('✅')
                        ? Colors.green.shade50
                        : _statusMessage.contains('❌')
                        ? Colors.red.shade50
                        : _statusMessage.contains('🔄')
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusMessage.contains('✅')
                            ? Colors.green.shade700
                            : _statusMessage.contains('❌')
                            ? Colors.red.shade700
                            : _statusMessage.contains('🔄')
                            ? Colors.orange.shade700
                            : Colors.blue.shade700,
                      ),
                    ),
                  ),

                // Pack list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _packs.length,
                    itemBuilder: (context, index) {
                      final pack = _packs[index];
                      final subjectId = pack['id'] as String;
                      final isCached = pack['isCached'] as bool;
                      final needsUpdate = pack['needsUpdate'] as bool;
                      final cachedVersion = pack['cachedVersion'] as int;
                      final serverVersion = pack['serverVersion'] as int;
                      final progress = _downloadProgress[subjectId] ?? 0.0;
                      final isCurrentlyDownloading =
                          _isDownloading && progress > 0 && progress < 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: needsUpdate ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: needsUpdate
                              ? BorderSide(
                                  color: Colors.orange.shade300,
                                  width: 2,
                                )
                              : isCached
                              ? BorderSide(
                                  color: Colors.green.shade300,
                                  width: 1,
                                )
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Subject icon
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: needsUpdate
                                          ? Colors.orange.shade50
                                          : isCached
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        pack['icon'] as String,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Pack info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pack['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        // Version info
                                        Row(
                                          children: [
                                            Icon(
                                              isCached
                                                  ? Icons.check_circle
                                                  : Icons.cloud_download,
                                              size: 16,
                                              color: isCached
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            if (isCached) ...[
                                              Text(
                                                'v$cachedVersion',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (needsUpdate) ...[
                                                const SizedBox(width: 6),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  size: 12,
                                                  color: Colors.orange.shade700,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'v$serverVersion available',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        Colors.orange.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ] else
                                              Text(
                                                serverVersion > 0
                                                    ? 'v$serverVersion available'
                                                    : 'Not downloaded',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action button
                                  if (isCached && !needsUpdate)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 22,
                                      ),
                                      onPressed: () => _deletePack(subjectId),
                                      tooltip: 'Delete to free space',
                                      visualDensity: VisualDensity.compact,
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed: _isDownloading
                                          ? null
                                          : () => _downloadPack(subjectId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: needsUpdate
                                            ? Colors.orange
                                            : Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isCurrentlyDownloading
                                            ? '${(progress * 100).toInt()}%'
                                            : needsUpdate
                                            ? 'Update'
                                            : 'Download',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),

                              // Progress bar
                              if (isCurrentlyDownloading)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        needsUpdate
                                            ? Colors.orange
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isDownloading
                                ? null
                                : () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Back'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed:
                                (_isDownloading ||
                                    (allDownloaded && updateCount == 0))
                                ? null
                                : _downloadAll,
                            icon: _isDownloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    updateCount > 0
                                        ? Icons.update
                                        : Icons.download,
                                  ),
                            label: Text(
                              allDownloaded && updateCount == 0
                                  ? 'All Up to Date ✅'
                                  : updateCount > 0
                                  ? 'Update All ($updateCount)'
                                  : 'Download All',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allDownloaded && updateCount == 0
                                  ? Colors.green
                                  : updateCount > 0
                                  ? Colors.orange
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
