import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String text;
  final String label;

  const AudioPlayerWidget({
    super.key,
    required this.text,
    this.label = 'Read Aloud',
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isPlaying = false;
  bool _isPaused = false;
  double _speed = 1.0;

  List<String> _sentences = [];
  int _currentSentenceIndex = 0;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _initTts();
    _splitText();
  }

  // Initialize TTS
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(_speed);
    await _flutterTts.setVolume(1.0);

    // When current sentence finishes, play next
    _flutterTts.setCompletionHandler(() {
      if (_isPlaying && !_isPaused) {
        _playNextSentence();
      }
    });

    _flutterTts.setErrorHandler((message) {
      print('❌ TTS Error: $message');
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
    });
  }

  // Split text into sentences
  void _splitText() {
    // Clean text for better speech
    String cleanText = widget.text
        .replaceAll('#', ' ')
        .replaceAll('*', '')
        .replaceAll('`', '')
        .replaceAll('```', '')
        .replaceAll('|', '')
        .replaceAll('> ', '')
        .replaceAll('  ', ' ')
        .trim();

    // Split by sentence endings
    _sentences = cleanText
        .split(RegExp(r'(?<=[.!?\n])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    print('📝 Split into ${_sentences.length} sentences');
  }

  // Start playing from current position
  Future<void> _startPlaying() async {
    if (_sentences.isEmpty) return;

    setState(() {
      _isPlaying = true;
      _isPaused = false;
    });

    // If we were paused, continue from current sentence
    // If starting fresh, start from beginning
    if (_currentSentenceIndex >= _sentences.length) {
      _currentSentenceIndex = 0;
    }

    _currentText = _sentences[_currentSentenceIndex];
    print(
      '🔊 Playing sentence ${_currentSentenceIndex + 1}/${_sentences.length}: ${_currentText.substring(0, 30)}...',
    );

    await _flutterTts.speak(_currentText);
  }

  // Play next sentence
  Future<void> _playNextSentence() async {
    _currentSentenceIndex++;

    if (_currentSentenceIndex < _sentences.length) {
      _currentText = _sentences[_currentSentenceIndex];
      print(
        '🔊 Playing sentence ${_currentSentenceIndex + 1}/${_sentences.length}',
      );
      await _flutterTts.speak(_currentText);
    } else {
      // All sentences played
      print('✅ All sentences played');
      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _currentSentenceIndex = 0; // Reset for next time
      });
    }
  }

  // Toggle Play/Pause
  Future<void> _togglePlay() async {
    if (_isPlaying && !_isPaused) {
      // Pause
      await _flutterTts.stop();
      setState(() => _isPaused = true);
      print('⏸️ Paused at sentence ${_currentSentenceIndex + 1}');
    } else if (_isPaused) {
      // Resume from current sentence
      await _startPlaying();
    } else {
      // Start from beginning
      _currentSentenceIndex = 0;
      await _startPlaying();
    }
  }

  // Stop completely
  Future<void> _stop() async {
    await _flutterTts.stop();
    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _currentSentenceIndex = 0;
    });
    print('⏹️ Stopped');
  }

  // Skip to next sentence
  Future<void> _skipForward() async {
    await _flutterTts.stop();
    _currentSentenceIndex++;

    if (_currentSentenceIndex >= _sentences.length) {
      _currentSentenceIndex = 0;
    }

    if (_isPlaying) {
      await _startPlaying();
    }
    print('⏭️ Skipped to sentence ${_currentSentenceIndex + 1}');
  }

  // Go back to previous sentence
  Future<void> _skipBackward() async {
    await _flutterTts.stop();
    _currentSentenceIndex--;

    if (_currentSentenceIndex < 0) {
      _currentSentenceIndex = 0;
    }

    if (_isPlaying) {
      await _startPlaying();
    }
    print('⏮️ Back to sentence ${_currentSentenceIndex + 1}');
  }

  // Change speed
  Future<void> _changeSpeed() async {
    double newSpeed;
    if (_speed >= 1.5) {
      newSpeed = 0.5;
    } else if (_speed >= 1.0) {
      newSpeed = 1.5;
    } else {
      newSpeed = 1.0;
    }

    _speed = newSpeed;
    await _flutterTts.setSpeechRate(_speed);

    // If playing, restart current sentence with new speed
    if (_isPlaying && !_isPaused) {
      await _flutterTts.stop();
      await _flutterTts.speak(_currentText);
    }

    setState(() {});
    print('⚡ Speed: ${_speed}x');
  }

  @override
  Widget build(BuildContext context) {
    final progress = _sentences.isNotEmpty
        ? (_currentSentenceIndex + 1) / _sentences.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controls row
          Row(
            children: [
              // Skip backward
              IconButton(
                icon: const Icon(
                  Icons.replay_5,
                  color: Colors.indigo,
                  size: 24,
                ),
                onPressed: (_isPlaying || _isPaused) ? _skipBackward : null,
                tooltip: 'Previous',
                visualDensity: VisualDensity.compact,
              ),

              // Play/Pause button
              IconButton(
                icon: Icon(
                  _isPlaying && !_isPaused
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.indigo,
                  size: 40,
                ),
                onPressed: _togglePlay,
                tooltip: _isPlaying && !_isPaused
                    ? 'Pause'
                    : _isPaused
                    ? 'Resume'
                    : 'Play',
              ),

              // Skip forward
              IconButton(
                icon: const Icon(
                  Icons.forward_5,
                  color: Colors.indigo,
                  size: 24,
                ),
                onPressed: (_isPlaying || _isPaused) ? _skipForward : null,
                tooltip: 'Next',
                visualDensity: VisualDensity.compact,
              ),

              // Stop button
              if (_isPlaying || _isPaused)
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle,
                    color: Colors.red,
                    size: 36,
                  ),
                  onPressed: _stop,
                  tooltip: 'Stop',
                  visualDensity: VisualDensity.compact,
                ),

              const SizedBox(width: 8),

              // Label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPlaying && !_isPaused
                          ? '🔊 Reading...'
                          : _isPaused
                          ? '⏸️ Paused'
                          : '🔊 ${widget.label}',
                      style: TextStyle(
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (_sentences.isNotEmpty && (_isPlaying || _isPaused))
                      Text(
                        'Sentence ${_currentSentenceIndex + 1} of ${_sentences.length}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.indigo.shade400,
                        ),
                      ),
                  ],
                ),
              ),

              // Speed control
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: InkWell(
                  onTap: _changeSpeed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.speed, size: 16, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        '${_speed}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Progress bar
          if (_sentences.isNotEmpty && (_isPlaying || _isPaused))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.indigo.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.indigo,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
