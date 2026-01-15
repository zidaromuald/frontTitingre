import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/groupe/groupe_message_service.dart';
import 'package:gestauth_clean/services/voice_message_service.dart';
import 'package:gestauth_clean/widgets/voice_recorder_widget.dart';

/// Page de chat d'un groupe avec support des messages vocaux
class GroupeChatPage extends StatefulWidget {
  final int groupeId;
  final String groupeName;

  const GroupeChatPage({
    super.key,
    required this.groupeId,
    required this.groupeName,
  });

  @override
  State<GroupeChatPage> createState() => _GroupeChatPageState();
}

class _GroupeChatPageState extends State<GroupeChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<GroupeMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _showVoiceRecorder = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Charger les messages du groupe
  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await GroupeMessageService.getRecentMessages(
        widget.groupeId,
        limit: 50,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur de chargement des messages: $e');
    }
  }

  /// Envoyer un message texte
  Future<void> _sendTextMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final message = await GroupeMessageService.sendSimpleMessage(
        widget.groupeId,
        content,
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      _showError('Erreur d\'envoi: $e');
    }
  }

  /// Envoyer un message vocal
  Future<void> _sendVoiceMessage(File audioFile, Duration duration) async {
    setState(() {
      _isSending = true;
      _showVoiceRecorder = false;
    });

    try {
      // Valider le fichier audio
      await VoiceMessageService.validateAudioFile(audioFile);

      // Envoyer le vocal avec progression
      final message = await VoiceMessageService.sendVoiceToGroupe(
        groupeId: widget.groupeId,
        audioFile: audioFile,
        duration: duration,
        onProgress: (progress) {
          // Optionnel: afficher la progression
          debugPrint('Upload: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      setState(() {
        _messages.add(message);
        _isSending = false;
      });

      _scrollToBottom();

      // Nettoyer le fichier temporaire
      await VoiceMessageService.cleanupTempFile(audioFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vocal envoyé avec succès')),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      _showError('Erreur d\'envoi du vocal: $e');
    }
  }

  /// Afficher une erreur
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Faire défiler vers le bas
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// Construire un message texte
  Widget _buildTextMessage(GroupeMessageModel message) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        message.contenu,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  /// Construire un message vocal
  Widget _buildVoiceMessage(GroupeMessageModel message) {
    final audioUrl = VoiceMessageService.extractAudioUrl(message.contenu);

    if (audioUrl == null) {
      return const Text('Message vocal invalide');
    }

    return VoiceMessagePlayer(audioUrl: audioUrl);
  }

  /// Construire un item de message
  Widget _buildMessageItem(GroupeMessageModel message) {
    final isVoice = VoiceMessageService.isVoiceMessage(message.contenu);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom de l'expéditeur
          Text(
            message.getSenderName(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),

          // Contenu du message (texte ou vocal)
          isVoice
              ? _buildVoiceMessage(message)
              : _buildTextMessage(message),

          // Heure
          const SizedBox(height: 4),
          Text(
            GroupeMessageService.formatMessageTime(message.createdAt),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Aucun message'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageItem(_messages[index]);
                        },
                      ),
          ),

          // Widget d'enregistrement vocal
          if (_showVoiceRecorder)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: VoiceRecorderWidget(
                onRecordingComplete: _sendVoiceMessage,
              ),
            ),

          // Barre de saisie
          if (!_showVoiceRecorder)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  // Bouton vocal
                  IconButton(
                    icon: const Icon(Icons.mic),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      setState(() {
                        _showVoiceRecorder = !_showVoiceRecorder;
                      });
                    },
                  ),

                  // Champ de texte
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Écrivez un message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      enabled: !_isSending,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Bouton envoyer
                  _isSending
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          color: Theme.of(context).primaryColor,
                          onPressed: _sendTextMessage,
                        ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
