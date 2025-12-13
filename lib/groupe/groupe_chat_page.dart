import 'package:flutter/material.dart';
import '../services/groupe/groupe_chat_service.dart';
import '../services/AuthUS/user_auth_service.dart';
import '../services/AuthUS/societe_auth_service.dart';
import 'dart:async';

/// Page de chat en temps réel pour un groupe
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
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  int? _currentUserId;
  String? _currentUserType;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Charger l'utilisateur actuel
  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await UserAuthService.getMyProfile();
      setState(() {
        _currentUserId = currentUser.id;
        _currentUserType = 'User';
      });
    } catch (e) {
      try {
        final currentSociete = await SocieteAuthService.getMyProfile();
        setState(() {
          _currentUserId = currentSociete.id;
          _currentUserType = 'Societe';
        });
      } catch (e) {
        // Non connecté
      }
    }
  }

  /// Démarrer le rafraîchissement automatique toutes les 5 secondes
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  /// Charger les messages du groupe
  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final messages = await GroupeChatService.getRecentMessages(widget.groupeId);

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Scroll vers le bas après chargement
        if (!silent) {
          _scrollToBottom();
        }

        // Marquer les messages comme lus
        await GroupeChatService.markAllMessagesAsRead(widget.groupeId);
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Envoyer un message
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();

    if (content.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final dto = SendGroupeMessageDto(contenu: content);
      await GroupeChatService.sendMessage(widget.groupeId, dto);

      _messageController.clear();

      // Recharger les messages
      await _loadMessages(silent: true);

      // Scroll vers le bas
      _scrollToBottom();

      if (mounted) {
        setState(() => _isSending = false);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Supprimer un message
  Future<void> _deleteMessage(int messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GroupeChatService.deleteMessage(widget.groupeId, messageId);
      await _loadMessages(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message supprimé'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Scroll vers le bas de la liste
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.groupeName,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Chat de groupe',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMessages(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: _buildMessagesList(cs),
          ),

          // Champ de saisie
          _buildMessageInput(cs),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ColorScheme cs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMessages,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à envoyer un message !',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    // Grouper les messages par date
    final groupedMessages = GroupeChatService.groupMessagesByDate(_messages);
    final sortedDates = groupedMessages.keys.toList()..sort();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final messagesForDate = groupedMessages[date]!;

        return Column(
          children: [
            // Séparateur de date
            _buildDateSeparator(date, cs),
            const SizedBox(height: 12),

            // Messages de cette date
            ...messagesForDate.map((message) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMessageBubble(message, cs),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        GroupeChatService.formatMessageDate(date),
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(GroupeMessageModel message, ColorScheme cs) {
    final isMine = _currentUserId != null &&
        _currentUserType != null &&
        message.isSentByMe(_currentUserId!, _currentUserType!);

    final avatarColorIndex = message.getAvatarColorIndex();
    final avatarColor = Color(GroupeChatService.getAvatarColors()[avatarColorIndex]);

    return Row(
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMine) ...[
          // Avatar de l'expéditeur
          CircleAvatar(
            radius: 18,
            backgroundColor: avatarColor.withOpacity(0.2),
            child: Icon(
              message.senderType == 'Societe' ? Icons.business : Icons.person,
              size: 18,
              color: avatarColor,
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Bulle de message
        Flexible(
          child: GestureDetector(
            onLongPress: isMine
                ? () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Supprimer'),
                              onTap: () {
                                Navigator.pop(context);
                                _deleteMessage(message.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? cs.primary
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMine
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de l'expéditeur (seulement si pas moi)
                  if (!isMine) ...[
                    Text(
                      message.getSenderName(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: avatarColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Contenu du message
                  Text(
                    message.contenu,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? cs.onPrimary : cs.onSurface,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Heure
                  Text(
                    GroupeChatService.formatMessageTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? cs.onPrimary.withOpacity(0.7)
                          : cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isMine) const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageInput(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Envoyer un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: cs.primary,
            child: _isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.send, color: cs.onPrimary, size: 20),
                    onPressed: _sendMessage,
                    tooltip: 'Envoyer',
                  ),
          ),
        ],
      ),
    );
  }
}
