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
  String _statusMessage = '';

  final List<Map<String, String>> _packs = [
    {'id': 'math', 'name': 'Mathematics', 'icon': '📐'},
    {'id': 'science', 'name': 'Science', 'icon': '🔬'},
    {'id': 'english', 'name': 'English', 'icon': '📖'},
    {'id': 'history', 'name': 'History', 'icon': '🏛️'},
  ];

  @override
  void initState() {
    super.initState();
    _checkCachedPacks();
  }

  void _checkCachedPacks() {
    for (final pack in _packs) {
      final isCached = ContentCacheService.isPackCached(pack['id']!);
      _downloadStatus[pack['id']!] = isCached;
      if (isCached) {
        _downloadProgress[pack['id']!] = 1.0;
      }
    }
    setState(() {});
  }

  Future<void> _downloadPack(String subjectId) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress[subjectId] = 0.0;
      _statusMessage = 'Downloading ${_getPackName(subjectId)}...';
    });

    final result = await DownloadService.downloadPack(
      subjectId: subjectId,
      onProgress: (progress) {
        setState(() {
          _downloadProgress[subjectId] = progress;
        });
      },
    );

    setState(() {
      _downloadStatus[subjectId] = result != null;
      _isDownloading = false;
      _statusMessage = result != null
          ? '✅ ${_getPackName(subjectId)} downloaded!'
          : '❌ Failed to download ${_getPackName(subjectId)}';
    });

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

  Future<void> _downloadAll() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _statusMessage = 'Downloading all packs...';
    });

    for (final pack in _packs) {
      if (!(_downloadStatus[pack['id']] ?? false)) {
        await _downloadPack(pack['id']!);
      }
    }

    setState(() {
      _isDownloading = false;
      _statusMessage = '✅ All available packs downloaded!';
    });

    if (mounted) {
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

  Future<void> _deletePack(String subjectId) async {
    await ContentCacheService.deletePack(subjectId);
    setState(() {
      _downloadStatus[subjectId] = false;
      _downloadProgress[subjectId] = 0.0;
      _statusMessage = '${_getPackName(subjectId)} deleted';
    });
  }

  String _getPackName(String id) {
    return _packs.firstWhere((p) => p['id'] == id)['name']!;
  }

  @override
  Widget build(BuildContext context) {
    final allDownloaded = _downloadStatus.values.every((s) => s);
    final downloadedCount = _downloadStatus.values.where((s) => s).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Lessons'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: _statusMessage.contains('✅')
                  ? Colors.green.shade50
                  : _statusMessage.contains('❌')
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _statusMessage.contains('✅')
                      ? Colors.green.shade700
                      : _statusMessage.contains('❌')
                      ? Colors.red.shade700
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
                final subjectId = pack['id']!;
                final isDownloaded = _downloadStatus[subjectId] ?? false;
                final progress = _downloadProgress[subjectId] ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDownloaded
                        ? BorderSide(color: Colors.green.shade300, width: 2)
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
                                color: isDownloaded
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  pack['icon']!,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Pack info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pack['name']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        isDownloaded
                                            ? Icons.check_circle
                                            : Icons.cloud_download,
                                        size: 16,
                                        color: isDownloaded
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isDownloaded
                                            ? 'Downloaded'
                                            : 'Not downloaded',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDownloaded
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Action button
                            if (isDownloaded)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePack(subjectId),
                                tooltip: 'Delete to free space',
                              )
                            else
                              ElevatedButton(
                                onPressed: _isDownloading
                                    ? null
                                    : () => _downloadPack(subjectId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: Text(
                                  _isDownloading && progress > 0 && progress < 1
                                      ? '${(progress * 100).toInt()}%'
                                      : 'Download',
                                ),
                              ),
                          ],
                        ),

                        // Progress bar
                        if (progress > 0 && progress < 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
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
                      onPressed: (_isDownloading || allDownloaded)
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
                          : const Icon(Icons.download),
                      label: Text(
                        allDownloaded ? 'All Downloaded' : 'Download All',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: allDownloaded
                            ? Colors.green
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
