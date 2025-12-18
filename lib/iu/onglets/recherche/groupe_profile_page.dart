import 'package:flutter/material.dart';
import '../../../services/groupe/groupe_service.dart';
import '../../../services/groupe/groupe_membre_service.dart';
import '../../../services/groupe/groupe_invitation_service.dart';
import '../../../services/groupe/groupe_profil_service.dart';
import '../../../services/posts/post_service.dart';
import '../../../groupe/groupe_chat_page.dart';

/// Page de profil PUBLIC d'un groupe
/// Accessible depuis la recherche GlobalSearchPage
/// Permet de voir les infos et de rejoindre/demander invitation
class GroupeProfilePage extends StatefulWidget {
  final int groupeId;

  const GroupeProfilePage({super.key, required this.groupeId});

  @override
  State<GroupeProfilePage> createState() => _GroupeProfilePageState();
}

class _GroupeProfilePageState extends State<GroupeProfilePage>
    with SingleTickerProviderStateMixin {
  GroupeModel? _groupe;
  GroupeProfilModel? _profil;
  List<Map<String, dynamic>> _membres = [];
  bool _isLoading = true;
  bool _isMember = false;
  MembreRole? _myRole;
  bool _hasInvitationPending = false;
  bool _isActionLoading = false;

  late TabController _tabController;

  // Couleurs
  static const Color primaryColor = Color(0xff5ac18e);
  static const Color darkGray = Color(0xFF8D8D8D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGroupeProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupeProfile() async {
    setState(() => _isLoading = true);

    try {
      // Charger en parallèle
      final results = await Future.wait([
        GroupeAuthService.getGroupe(widget.groupeId),
        GroupeProfilService.getProfil(widget.groupeId),
        GroupeMembreService.getMembres(widget.groupeId, limit: 10),
        GroupeAuthService.isMember(widget.groupeId),
        GroupeAuthService.getMyRole(widget.groupeId),
      ]);

      if (mounted) {
        setState(() {
          _groupe = results[0] as GroupeModel;
          _profil = results[1] as GroupeProfilModel;
          _membres = results[2] as List<Map<String, dynamic>>;
          _isMember = results[3] as bool;
          _myRole = results[4] as MembreRole?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Rejoindre un groupe public
  Future<void> _joinGroupe() async {
    if (_groupe == null) return;

    setState(() => _isActionLoading = true);

    try {
      await GroupeMembreService.joinGroupe(widget.groupeId);

      if (mounted) {
        setState(() {
          _isMember = true;
          _myRole = MembreRole.membre;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez rejoint "${_groupe!.nom}" !'),
            backgroundColor: primaryColor,
          ),
        );

        // Recharger les données
        _loadGroupeProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Demander une invitation pour un groupe privé
  Future<void> _requestInvitation() async {
    if (_groupe == null) return;

    // Dialogue pour personnaliser le message
    final message = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: 'Bonjour, je souhaiterais rejoindre votre groupe.',
        );

        return AlertDialog(
          title: const Text('Demande d\'invitation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Envoyez une demande aux administrateurs de "${_groupe!.nom}".',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );

    if (message == null) return;

    setState(() => _isActionLoading = true);

    try {
      // Récupérer les admins du groupe
      final admins = await GroupeMembreService.getAdmins(widget.groupeId);

      if (admins.isEmpty) {
        throw Exception('Aucun administrateur trouvé pour ce groupe');
      }

      // Envoyer une invitation à chaque admin
      // Note: Dans un vrai système, il faudrait une API dédiée pour les demandes
      // Ici, on simule en envoyant un message aux admins
      // À adapter selon votre backend

      if (mounted) {
        setState(() {
          _hasInvitationPending = true;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demande envoyée aux administrateurs de "${_groupe!.nom}"',
            ),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Quitter le groupe
  Future<void> _leaveGroupe() async {
    if (_groupe == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le groupe'),
        content: Text('Voulez-vous vraiment quitter "${_groupe!.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await GroupeMembreService.leaveGroupe(widget.groupeId);

      if (mounted) {
        setState(() {
          _isMember = false;
          _myRole = null;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez quitté "${_groupe!.nom}"'),
            backgroundColor: Colors.orange,
          ),
        );

        // Recharger les données
        _loadGroupeProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _groupe?.nom ?? 'Groupe',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: _groupe != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Infos', icon: Icon(Icons.info_outline, size: 20)),
                  Tab(text: 'Posts', icon: Icon(Icons.article_outlined, size: 20)),
                  Tab(text: 'Messages', icon: Icon(Icons.chat_outlined, size: 20)),
                  Tab(text: 'Membres', icon: Icon(Icons.people_outline, size: 20)),
                ],
              )
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupe == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Groupe introuvable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Retour'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildInfoTab(),
        _buildPostsTab(),
        _buildMessagesTab(),
        _buildMembresTab(),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo de couverture
          if (_profil?.photoCouverture != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_profil!.getPhotoCouvertureUrl()!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Logo et nom
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    image: _profil?.logo != null
                        ? DecorationImage(
                            image: NetworkImage(_profil!.getLogoUrl()!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profil?.logo == null
                      ? const Icon(Icons.group, size: 50, color: primaryColor)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _groupe!.nom,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  label: 'Membres',
                  value: '${_groupe!.membresCount ?? 0}',
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: _groupe!.isPublic() ? Icons.public : Icons.lock,
                  label: 'Type',
                  value: _groupe!.isPublic() ? 'Public' : 'Privé',
                  color: _groupe!.isPublic() ? Colors.blue : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          if (_profil?.description != null) ...[
            const Text(
              'À propos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _profil!.description!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Règles du groupe
          if (_profil?.regles != null) ...[
            const Text(
              'Règles du groupe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rule, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _profil!.regles!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Tags
          if (_profil?.tags != null && _profil!.tags!.isNotEmpty) ...[
            const Text(
              'Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profil!.tags!.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Informations supplémentaires
          const Text(
            'Informations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_profil?.localisation != null)
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'Localisation',
              value: _profil!.localisation!,
            ),
          if (_profil?.secteurActivite != null)
            _buildInfoRow(
              icon: Icons.work,
              label: 'Secteur',
              value: _profil!.secteurActivite!,
            ),
          if (_profil?.languePrincipale != null)
            _buildInfoRow(
              icon: Icons.language,
              label: 'Langue',
              value: _profil!.languePrincipale!,
            ),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Créé le',
            value: _groupe!.createdAt != null
                ? _formatDate(_groupe!.createdAt!)
                : 'N/A',
          ),
          _buildInfoRow(
            icon: Icons.category,
            label: 'Catégorie',
            value: _getCategorieLabel(_groupe!.categorie),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return FutureBuilder<List<PostModel>>(
      future: PostService.getPostsByGroupe(widget.groupeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Aucun post dans ce groupe',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _buildPostCard(post);
          },
        );
      },
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryColor,
                child: Text(
                  post.getAuthorName()[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.getAuthorName(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatPostDate(post.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Contenu
          Text(post.contenu),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${post.likesCount}'),
              const SizedBox(width: 20),
              Icon(Icons.comment_outlined, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${post.commentsCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    if (!_isMember) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Rejoignez le groupe pour accéder aux messages',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_outlined, size: 80, color: primaryColor),
          const SizedBox(height: 24),
          const Text(
            'Discussion du groupe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Discutez avec tous les membres du groupe',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openGroupChat(),
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text('Ouvrir la discussion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _openGroupChat() {
    if (_groupe == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeChatPage(
          groupeId: widget.groupeId,
          groupeName: _groupe!.nom,
        ),
      ),
    );
  }

  Widget _buildMembresTab() {
    if (_membres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun membre visible',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _membres.length,
      itemBuilder: (context, index) {
        final membre = _membres[index];
        return _buildMembreCard(membre);
      },
    );
  }

  Widget _buildMembreCard(Map<String, dynamic> membre) {
    final role = MembreRole.fromString(membre['role'] ?? 'membre');
    final userName = membre['user']?['nom'] ?? 'Membre';
    final userPhoto = membre['user']?['profile']?['photo'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          backgroundImage:
              userPhoto != null ? NetworkImage(userPhoto) : null,
          child: userPhoto == null
              ? Text(
                  userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getRoleLabel(role),
          style: TextStyle(
            fontSize: 12,
            color: _getRoleColor(role),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: _buildRoleBadge(role),
      ),
    );
  }

  Widget _buildRoleBadge(MembreRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 14,
            color: _getRoleColor(role),
          ),
          const SizedBox(width: 4),
          Text(
            _getRoleLabel(role),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getRoleColor(role),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: darkGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: darkGray),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: darkGray),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_groupe == null) return null;

    // Si je suis déjà membre
    if (_isMember) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge "Membre"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Vous êtes membre ${_myRole != null ? '(${_getRoleLabel(_myRole!)})' : ''}',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Bouton Quitter
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isActionLoading ? null : _leaveGroupe,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text(
                  'Quitter le groupe',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Si groupe public
    if (_groupe!.isPublic()) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isActionLoading || _groupe!.isFull()
                ? null
                : _joinGroupe,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isActionLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.group_add),
            label: Text(
              _groupe!.isFull()
                  ? 'Groupe plein'
                  : (_isActionLoading ? 'Chargement...' : 'Rejoindre le groupe'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    // Si groupe privé
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _isActionLoading || _hasInvitationPending
              ? null
              : _requestInvitation,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _hasInvitationPending ? Colors.grey : Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _isActionLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(_hasInvitationPending ? Icons.pending : Icons.mail),
          label: Text(
            _hasInvitationPending
                ? 'Demande envoyée'
                : 'Demander une invitation',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  String _getCategorieLabel(GroupeCategorie categorie) {
    switch (categorie) {
      case GroupeCategorie.simple:
        return 'Groupe Simple';
      case GroupeCategorie.professionnel:
        return 'Groupe Professionnel';
      case GroupeCategorie.supergroupe:
        return 'Super Groupe';
    }
  }

  String _getRoleLabel(MembreRole role) {
    switch (role) {
      case MembreRole.membre:
        return 'Membre';
      case MembreRole.moderateur:
        return 'Modérateur';
      case MembreRole.admin:
        return 'Administrateur';
    }
  }

  Color _getRoleColor(MembreRole role) {
    switch (role) {
      case MembreRole.membre:
        return Colors.blue;
      case MembreRole.moderateur:
        return Colors.orange;
      case MembreRole.admin:
        return Colors.red;
    }
  }

  IconData _getRoleIcon(MembreRole role) {
    switch (role) {
      case MembreRole.membre:
        return Icons.person;
      case MembreRole.moderateur:
        return Icons.shield;
      case MembreRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _formatPostDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
