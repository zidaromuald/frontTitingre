import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Widget pour enregistrer des messages vocaux
/// Utilisable uniquement dans les groupes et conversations privées avec sociétés
class VoiceRecorderWidget extends StatefulWidget {
  /// Callback appelé quand l'enregistrement est terminé
  final Function(File audioFile, Duration duration) onRecordingComplete;

  /// Texte du bouton d'annulation
  final String? cancelText;

  /// Texte du bouton d'envoi
  final String? sendText;

  /// Durée maximale d'enregistrement (défaut: 5 minutes)
  final Duration maxDuration;

  const VoiceRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.cancelText,
    this.sendText,
    this.maxDuration = const Duration(minutes: 5),
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  String? _audioFilePath;
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  @override
  void dispose() {
    _stopRecording();
    _audioRecorder?.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }

  /// Initialiser le recorder audio
  Future<void> _initRecorder() async {
    _audioRecorder = FlutterSoundRecorder();

    // Demander la permission microphone
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise pour enregistrer un vocal'),
          ),
        );
      }
      return;
    }

    // Ouvrir le recorder
    await _audioRecorder!.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  /// Démarrer l'enregistrement
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized || _audioRecorder == null) {
      await _initRecorder();
      if (!_isRecorderInitialized) return;
    }

    try {
      // Créer un fichier temporaire pour l'audio
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioFilePath = '${tempDir.path}/voice_message_$timestamp.wav';

      // Démarrer l'enregistrement en WAV (supporté Android/iOS + accepté par le serveur)
      await _audioRecorder!.startRecorder(
        toFile: _audioFilePath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
      });

      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur d\'enregistrement: $e')),
        );
      }
    }
  }

  /// Démarrer le timer pour suivre la durée
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration = Duration(seconds: timer.tick);
      });

      if (_recordDuration >= widget.maxDuration) {
        _stopAndSend();
      }
    });
  }

  /// Arrêter l'enregistrement
  Future<void> _stopRecording() async {
    if (!_isRecording || _audioRecorder == null) return;

    try {
      await _audioRecorder!.stopRecorder();
      _timer?.cancel();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Erreur arrêt enregistrement: $e');
    }
  }

  /// Arrêter et envoyer le vocal
  Future<void> _stopAndSend() async {
    await _stopRecording();

    if (_audioFilePath != null && _recordDuration.inSeconds > 0) {
      final audioFile = File(_audioFilePath!);
      if (await audioFile.exists()) {
        widget.onRecordingComplete(audioFile, _recordDuration);
      }
    }
  }

  /// Annuler l'enregistrement
  Future<void> _cancelRecording() async {
    await _stopRecording();

    if (_audioFilePath != null) {
      final audioFile = File(_audioFilePath!);
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }

    setState(() {
      _audioFilePath = null;
      _recordDuration = Duration.zero;
    });
  }

  /// Formater la durée en mm:ss
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRecorderInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.red,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(_recordDuration),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                ),
              ],
            ),

          if (_isRecording) const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_isRecording) ...[
                ElevatedButton.icon(
                  onPressed: _cancelRecording,
                  icon: const Icon(Icons.close),
                  label: Text(widget.cancelText ?? 'Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopAndSend,
                  icon: const Icon(Icons.send),
                  label: Text(widget.sendText ?? 'Envoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: const Icon(Icons.mic, size: 32),
                  label: const Text('Enregistrer un vocal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (!_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Appuyez pour commencer l\'enregistrement',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget pour lire un message vocal
class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final Duration? duration;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    this.duration,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  FlutterSoundPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isPlayerInitialized = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription<PlaybackDisposition>? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _audioPlayer?.closePlayer();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    _audioPlayer = FlutterSoundPlayer();
    await _audioPlayer!.openPlayer();

    // Activer les événements de progression toutes les 100ms
    await _audioPlayer!.setSubscriptionDuration(
      const Duration(milliseconds: 100),
    );

    // Abonnement unique sur toute la durée de vie du widget
    _progressSubscription = _audioPlayer!.onProgress!.listen((event) {
      if (!mounted) return;
      setState(() {
        _currentPosition = event.position;
        if (event.duration.inMilliseconds > 0) {
          _totalDuration = event.duration;
        }
      });
    });

    if (mounted) {
      setState(() {
        _isPlayerInitialized = true;
        _totalDuration = widget.duration ?? Duration.zero;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (!_isPlayerInitialized || _audioPlayer == null) return;

    if (_isPlaying) {
      await _audioPlayer!.pausePlayer();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer!.startPlayer(
        fromURI: widget.audioUrl,
        whenFinished: () {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _currentPosition = Duration.zero;
            });
          }
        },
      );
      setState(() => _isPlaying = true);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlayerInitialized) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final double sliderMax = _totalDuration.inMilliseconds > 0
        ? _totalDuration.inMilliseconds.toDouble()
        : 1.0;
    final double sliderValue = _currentPosition.inMilliseconds
        .toDouble()
        .clamp(0.0, sliderMax);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _togglePlayPause,
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).primaryColor,
            ),
          ),
          Flexible(
            child: SizedBox(
              width: 120,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: sliderValue,
                  max: sliderMax,
                  onChanged: null,
                ),
              ),
            ),
          ),
          Text(
            _totalDuration.inSeconds > 0
                ? '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}'
                : _isPlaying
                    ? _formatDuration(_currentPosition)
                    : '--:--',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
