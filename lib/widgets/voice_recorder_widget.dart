import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    await _audioRecorder!.openRecorder();
    setState(() {
      _isRecorderInitialized = true;
    });
  }

  /// Démarrer l'enregistrement (AAC → fichier direct, fiable sur Android)
  Future<void> _startRecording() async {
    if (!_isRecorderInitialized || _audioRecorder == null) {
      await _initRecorder();
      if (!_isRecorderInitialized) return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioFilePath = '${tempDir.path}/voice_message_$timestamp.aac';

      await _audioRecorder!.startRecorder(
        toFile: _audioFilePath,
        codec: Codec.aacADTS,
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
      setState(() { _isRecording = false; });
    }
  }

  /// Arrêter et envoyer le vocal
  Future<void> _stopAndSend() async {
    await _stopRecording();

    if (_audioFilePath != null && _recordDuration.inSeconds > 0) {
      final audioFile = File(_audioFilePath!);
      if (await audioFile.exists()) {
        final size = await audioFile.length();
        debugPrint('[Record] Fichier prêt: $size octets');
        if (size > 200) {
          widget.onRecordingComplete(audioFile, _recordDuration);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enregistrement vide, veuillez réessayer')),
            );
          }
        }
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
            color: Colors.black.withValues(alpha: 0.1),
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
  late final AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _hasError = false;
  String _errorMessage = 'Erreur';
  bool _isLoading = false;
  String? _localFilePath; // cache du fichier téléchargé

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _setupListeners();
  }

  void _setupListeners() {
    _subs.add(_player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _totalDuration = d);
    }));

    _subs.add(_player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _currentPosition = p);
    }));

    _subs.add(_player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    }));

    _subs.add(_player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playerState = PlayerState.stopped;
        _currentPosition = Duration.zero;
      });
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    // Supprimer le fichier temporaire
    if (_localFilePath != null) {
      File(_localFilePath!).delete().catchError((e) => File(_localFilePath!));
    }
    super.dispose();
  }

  /// Télécharge le fichier audio avec le token Bearer, le sauvegarde localement
  Future<String?> _downloadAudio() async {
    try {
      debugPrint('[Audio] Téléchargement: ${widget.audioUrl}');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse(widget.audioUrl),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('[Audio] Réponse: HTTP ${response.statusCode}, Content-Type: ${response.headers['content-type']}, taille: ${response.bodyBytes.length} octets');

      if (response.statusCode != 200) {
        debugPrint('[Audio] Erreur HTTP ${response.statusCode}: ${response.body}');
        return null;
      }

      // Fichier trop petit = corrompu (WAV header seul = 44 octets, AAC vide < 200 octets)
      if (response.bodyBytes.length <= 200) {
        debugPrint('[Audio] Fichier audio vide sur le serveur (${response.bodyBytes.length} octets) - enregistrement corrompu');
        return null;
      }

      // Utiliser l'extension de l'URL d'origine pour le fichier temp
      final uri = Uri.parse(widget.audioUrl);
      final originalName = uri.pathSegments.last;
      final ext = originalName.contains('.') ? originalName.split('.').last : 'wav';

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/audio_cache_$timestamp.$ext');
      await file.writeAsBytes(response.bodyBytes);
      debugPrint('[Audio] Fichier sauvegardé: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[Audio] Erreur download: $e');
      return null;
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
        return;
      }
      if (_playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }

      // Première lecture : télécharger si pas encore en cache
      if (_localFilePath == null) {
        if (mounted) setState(() => _isLoading = true);
        _localFilePath = await _downloadAudio();
        if (mounted) setState(() => _isLoading = false);

        if (_localFilePath == null) {
          if (mounted) setState(() { _hasError = true; _errorMessage = 'Audio indisponible'; });
          return;
        }
      }

      setState(() => _hasError = false);
      await _player.play(DeviceFileSource(_localFilePath!));
    } catch (e) {
      debugPrint('Erreur lecture audio: $e');
      if (mounted) setState(() { _hasError = true; _isLoading = false; _errorMessage = 'Erreur lecture'; });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final color = Theme.of(context).primaryColor;

    final double sliderMax = _totalDuration.inMilliseconds > 0
        ? _totalDuration.inMilliseconds.toDouble()
        : 1.0;
    final double sliderValue =
        _currentPosition.inMilliseconds.toDouble().clamp(0.0, sliderMax);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isLoading
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              : IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: _hasError ? Colors.red : color,
                    size: 36,
                  ),
                ),
          Flexible(
            child: SizedBox(
              width: 120,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: sliderValue,
                  max: sliderMax,
                  activeColor: color,
                  onChanged: null,
                ),
              ),
            ),
          ),
          Text(
            _hasError
                ? _errorMessage
                : _totalDuration.inSeconds > 0
                    ? '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}'
                    : isPlaying
                        ? _formatDuration(_currentPosition)
                        : '--:--',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: _hasError ? Colors.red : null),
          ),
        ],
      ),
    );
  }
}
