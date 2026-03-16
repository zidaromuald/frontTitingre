import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/messagerie/conversation_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';
import 'package:gestauth_clean/messagerie/conversation_detail_page.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage>
    with WidgetsBindingObserver {
  static const Color primaryBlue = Color(0xFF1E4A8C);
  static const Color darkGray = Color(0xFF8D8D8D);

  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  int? _myId;
  String? _myType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadConversations();
    }
  }

  Future<void> _loadUserInfo() async {
    final userData = await AuthBaseService.getUserData();
    final userType = await AuthBaseService.getUserType();
    if (userData != null && mounted) {
      setState(() {
        _myId = userData['id'];
        _myType = userType == 'user' ? 'User' : 'Societe';
      });
    }
    await _loadConversations();
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final conversations = await ConversationService.getMyConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes}m';
    } else {
      return "À l'instant";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          'Messagerie',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadConversations,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vos messages privés apparaîtront ici',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                        itemBuilder: (context, index) {
                          return _buildConversationTile(_conversations[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    final other = (_myId != null && _myType != null)
        ? conversation.getOtherParticipant(_myId!, _myType!)
        : (conversation.participants.isNotEmpty ? conversation.participants.first : null);

    final otherName = other?.getDisplayName() ?? 'Conversation';
    final otherPhoto = other?.photoUrl;
    final lastMsg = conversation.lastMessage;
    final unread = conversation.unreadCount;
    final time = lastMsg?.createdAt ?? conversation.updatedAt;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: primaryBlue,
            backgroundImage: otherPhoto != null ? NetworkImage(otherPhoto) : null,
            child: otherPhoto == null
                ? Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  )
                : null,
          ),
          if (unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        otherName,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
          fontSize: 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: lastMsg != null
          ? Text(
              lastMsg.contenu,
              style: TextStyle(
                fontSize: 13,
                color: unread > 0 ? Colors.black87 : darkGray,
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text('Aucun message', style: TextStyle(fontSize: 13, color: Colors.grey[400], fontStyle: FontStyle.italic)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(time),
            style: TextStyle(fontSize: 11, color: unread > 0 ? primaryBlue : darkGray),
          ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationDetailPage(
              conversationId: conversation.id,
              participantName: otherName,
            ),
          ),
        );
        // Refresh after returning to update unread counts
        _loadConversations();
      },
    );
  }
}
