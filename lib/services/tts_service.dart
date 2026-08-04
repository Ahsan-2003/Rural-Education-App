import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isPlaying = false;
  static bool _isPaused = false;
  static double _speed = 1.0;

  // Callbacks
  static Function(String)? onWordHighlight;
  static Function(bool)? onPlayingChanged;

  // Initialize TTS
  static Future<void> init() async {
    if (_isInitialized) return;

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(_speed);
    await _flutterTts.setVolume(1.0);

    // Listen for completion
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _isPaused = false;
      onPlayingChanged?.call(false);
      print('🔊 TTS: Playback completed');
    });

    // Listen for errors
    _flutterTts.setErrorHandler((message) {
      _isPlaying = false;
      _isPaused = false;
      onPlayingChanged?.call(false);
      print('❌ TTS Error: $message');
    });

    _isInitialized = true;
    print('✅ TTS initialized');
  }

  // Check if playing
  static bool get isPlaying => _isPlaying;
  static bool get isPaused => _isPaused;
  static double get speed => _speed;

  // Speak text
  static Future<void> speak(String text) async {
    if (text.isEmpty) return;

    await _flutterTts.stop();
    _isPlaying = true;
    _isPaused = false;
    onPlayingChanged?.call(true);

    // Clean text for better speech
    final cleanText = text
        .replaceAll('#', '')
        .replaceAll('*', '')
        .replaceAll('`', '')
        .replaceAll('```', '')
        .replaceAll('|', '')
        .replaceAll('- ', '')
        .replaceAll('> ', '');

    await _flutterTts.speak(cleanText);
    print('🔊 Speaking: ${cleanText.substring(0, 50)}...');
  }

  // Pause
  static Future<void> pause() async {
    if (_isPlaying && !_isPaused) {
      await _flutterTts.pause();
      _isPaused = true;
      print('⏸️ TTS Paused');
    }
  }

  // Resume from pause
  static Future<void> resume() async {
    if (_isPaused) {
      await _flutterTts.speak(''); // Resume workaround
      // Or use: _flutterTts.setQueueMode(1);
      _isPaused = false;
      print('▶️ TTS Resumed');
    }
  }

  // Stop completely
  static Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    _isPaused = false;
    onPlayingChanged?.call(false);
    print('⏹️ TTS Stopped');
  }

  // Set speed
  static Future<void> setSpeed(double speed) async {
    _speed = speed;
    await _flutterTts.setSpeechRate(speed);
    print('⚡ TTS Speed: ${speed}x');
  }

  // Get available languages
  static Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  // Dispose
  static Future<void> dispose() async {
    await _flutterTts.stop();
    _isInitialized = false;
    _isPlaying = false;
    _isPaused = false;
  }
}
