import 'package:flutter/material.dart';
import 'package:rural_education_app/models/lesson.dart';
import 'package:rural_education_app/models/subject.dart';
// import 'package:rural_education_app/models/lesson.dart';
import 'package:rural_education_app/screens/download_screen.dart';
import 'package:rural_education_app/screens/lesson_list_screen.dart';
import 'package:rural_education_app/services/content_cache_service.dart';
import 'package:rural_education_app/services/content_service.dart';

class SubjectScreen extends StatefulWidget {
  final String studentName;
  final String? classCode;
  final String studentId;
  final VoidCallback onLogout;

  const SubjectScreen({
    super.key,
    required this.studentName,
    required this.classCode,
    required this.studentId,
    required this.onLogout,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  late final ContentService _contentService;
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _contentService = ContentService();
    _subjects = _getSubjects();
  }

  List<Subject> _getSubjects() {
    return [
      Subject(
        id: 'math',
        name: 'Mathematics',
        icon: '📐',
        color: Colors.blue,
        gradientStart: Colors.blue.shade600,
        gradientEnd: Colors.blue.shade400,
        lessonCount: 3,
        description: ContentCacheService.isPackCached('math')
            ? '✅ Downloaded - Fractions & More'
            : 'Fractions, Addition & Daily Life',
      ),
      Subject(
        id: 'science',
        name: 'Science',
        icon: '🔬',
        color: Colors.green,
        gradientStart: Colors.green.shade600,
        gradientEnd: Colors.green.shade400,
        lessonCount: 3,
        description: ContentCacheService.isPackCached('science')
            ? '✅ Downloaded - Plants & Animals'
            : 'Plants, Animals & Human Body',
      ),
      Subject(
        id: 'english',
        name: 'English',
        icon: '📖',
        color: Colors.purple,
        gradientStart: Colors.purple.shade600,
        gradientEnd: Colors.purple.shade400,
        lessonCount: 3,
        description: ContentCacheService.isPackCached('english')
            ? '✅ Downloaded - Grammar Basics'
            : 'Nouns, Verbs & Sentences',
      ),
      Subject(
        id: 'history',
        name: 'History',
        icon: '🏛️',
        color: Colors.orange,
        gradientStart: Colors.orange.shade700,
        gradientEnd: Colors.orange.shade500,
        lessonCount: 3,
        description: ContentCacheService.isPackCached('history')
            ? '✅ Downloaded - Indian History'
            : 'Ancient India, Freedom & Heritage',
      ),
    ];
  }

  void _openSubject(Subject subject) {
    print('📖 Opening subject: ${subject.name} (${subject.id})');

    List<Lesson> lessons = [];
    bool fromCache = false;

    // First, try to get lessons from cache
    if (ContentCacheService.isPackCached(subject.id)) {
      print('📦 Found cached pack for ${subject.id}');
      final cachedPack = ContentCacheService.getCachedPack(subject.id);

      if (cachedPack != null) {
        final packData = cachedPack['data'];

        if (packData is Map<String, dynamic>) {
          final lessonsList = packData['lessons'];

          if (lessonsList is List && lessonsList.isNotEmpty) {
            try {
              lessons = lessonsList
                  .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
                  .toList();
              fromCache = true;
              print('✅ Loaded ${lessons.length} lessons from cache');

              // Debug: Print first lesson
              if (lessons.isNotEmpty) {
                print('  First lesson: ${lessons[0].title}');
              }
            } catch (e) {
              print('❌ Error parsing cached lessons: $e');
              lessons = [];
            }
          } else {
            print('⚠️ No lessons in cached data');
          }
        } else {
          print('⚠️ Invalid cache data format');
        }
      } else {
        print('⚠️ Cache returned null');
      }
    }

    // Fall back to hardcoded content if cache failed
    if (lessons.isEmpty) {
      print('📚 Using hardcoded lessons for ${subject.name}');
      lessons = _contentService.getLessonsForSubject(subject.id);
    }

    // Check if we have lessons
    if (lessons.isEmpty) {
      print('❌ No lessons available!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No lessons available for ${subject.name}. Please try downloading again.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Delete corrupted cache and retry
                ContentCacheService.deletePack(subject.id);
                _openSubject(subject);
              },
            ),
          ),
        );
      }
      return;
    }

    print(
      '📖 Navigating to lessons: ${lessons.length} lessons, fromCache: $fromCache',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonListScreen(
          studentName: widget.studentName,
          classCode: widget.classCode,
          studentId: widget.studentId,
          onLogout: widget.onLogout,
          lessons: lessons,
          subjectName: subject.name,
          subjectIcon: subject.icon,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.studentName}! 👋'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Download button
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DownloadScreen(
                    onDownloadsComplete: () {
                      // Refresh the subject screen after downloads
                      setState(() {});
                      print('🔄 Downloads complete, refreshing subjects');
                    },
                  ),
                ),
              );
            },
            tooltip: 'Download Lessons',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Switch Profile',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // HEADER
          // ==========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a Subject',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a subject to start learning',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 15,
                  ),
                ),
                if (widget.classCode != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Class ${widget.classCode}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ==========================================
          // SUBJECT CARDS
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Subjects (${_subjects.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final isDownloaded = ContentCacheService.isPackCached(
                  subject.id,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openSubject(subject),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [subject.gradientStart, subject.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Subject icon
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                subject.icon,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Subject info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subject.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // Download status icon
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isDownloaded
                                            ? Colors.green.withOpacity(0.8)
                                            : Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDownloaded
                                            ? Icons.cloud_done
                                            : Icons.cloud_download,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subject.description,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${subject.lessonCount} Lessons',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isDownloaded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 2),
                                            Text(
                                              'Downloaded',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Arrow
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
