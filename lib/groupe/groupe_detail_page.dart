import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/groupe/groupe_service.dart';
import '../services/groupe/groupe_membre_service.dart';
import '../services/groupe/groupe_invitation_service.dart';
import '../services/AuthUS/user_auth_service.dart';
import '../services/suivre/suivre_auth_service.dart' as suivre;
import '../services/posts/post_service.dart';
import '../widgets/r2_network_image.dart';
import '../widgets/voice_recorder_widget.dart';
import '../iu/onglets/postInfo/post_details_page.dart';
import '../iu/onglets/postInfo/post.dart';
import 'groupe_chat_page.dart';

/// Page de détail d'un groupe
/// Affiche les informations, membres, et permet la gestion
class GroupeDetailPage extends StatefulWidget {
  final int groupeId;

  const GroupeDetailPage({super.key, required this.groupeId});

  @override
  State<GroupeDetailPage> createState() => _GroupeDetailPageState();
}

class _GroupeDetailPageState extends State<GroupeDetailPage>
    with SingleTickerProviderStateMixin {
  GroupeModel? _groupe;
  bool _isLoading = true;
  bool _isMember = false;
  MembreRole? _myRole;
  String? _errorMessage;

  late TabController _tabController;

  // Posts du groupe
  List<PostModel> _groupePosts = [];
  bool _isLoadingPosts = false;
  bool _postsLoaded = false; // Flag pour éviter les appels répétés
  String? _postsError;

  // Membres du groupe
  List<Map<String, dynamic>> _membres = [];
  bool _isLoadingMembres = false;
  bool _membresLoaded = false;
  String? _membresError;

  // Couleurs
  static const Color primaryColor = Color(0xff5ac18e);
  static const Color darkGray = Color(0xFF8D8D8D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGroupeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger le groupe d'abord (obligatoire)
      print('🔄 [GroupeDetailPage] Chargement du groupe ${widget.groupeId}...');
      final groupe = await GroupeAuthService.getGroupe(widget.groupeId);
      print('✅ [GroupeDetailPage] Groupe chargé: ${groupe.nom}');

      // Charger les infos de membre en parallèle (optionnels)
      bool isMember = false;
      MembreRole? myRole;

      try {
        final memberResults = await Future.wait([
          GroupeAuthService.isMember(widget.groupeId),
          GroupeAuthService.getMyRole(widget.groupeId),
        ]);
        isMember = memberResults[0] as bool;
        myRole = memberResults[1] as MembreRole?;
        print(
          '✅ [GroupeDetailPage] isMember: $isMember, myRole: ${myRole?.value}',
        );
      } catch (e) {
        print('⚠️ [GroupeDetailPage] Erreur chargement statut membre: $e');
        // Continuer sans ces infos
      }

      if (mounted) {
        setState(() {
          _groupe = groupe;
          _isMember = isMember;
          _myRole = myRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [GroupeDetailPage] Erreur chargement groupe: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Charger les posts du groupe
  Future<void> _loadGroupePosts() async {
    if (_isLoadingPosts) return;

    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });

    try {
      print('📤 [GroupeDetailPage] Chargement des posts du groupe ${widget.groupeId}');
      final posts = await PostService.getPostsByGroupe(widget.groupeId);
      print('✅ [GroupeDetailPage] ${posts.length} posts chargés');

      if (mounted) {
        setState(() {
          _groupePosts = posts;
          _isLoadingPosts = false;
          _postsLoaded = true; // Marquer comme chargé
        });
      }
    } catch (e) {
      print('❌ [GroupeDetailPage] Erreur chargement posts: $e');
      if (mounted) {
        setState(() {
          _postsError = e.toString();
          _isLoadingPosts = false;
          _postsLoaded = true; // Marquer comme chargé même en cas d'erreur
        });
      }
    }
  }

  Future<void> _joinGroupe() async {
    if (_groupe == null) return;

    // Vérifier si le groupe est plein
    if (_groupe!.isFull()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le groupe a atteint sa capacité maximale'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await GroupeMembreService.joinGroupe(widget.groupeId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez rejoint "${_groupe!.nom}"'),
            backgroundColor: primaryColor,
          ),
        );

        // Recharger les données
        _loadGroupeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

    try {
      await GroupeMembreService.leaveGroupe(widget.groupeId);

      if (mounted) {
        Navigator.pop(context); // Retour à la liste des groupes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez quitté "${_groupe!.nom}"'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroupe() async {
    if (_groupe == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${_groupe!.nom}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await GroupeAuthService.deleteGroupe(widget.groupeId);

      if (mounted) {
        Navigator.pop(context); // Retour à la liste des groupes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Groupe "${_groupe!.nom}" supprimé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Afficher le dialog de recherche et invitation d'utilisateurs
  Future<void> _showInviteUserDialog() async {
    final TextEditingController searchController = TextEditingController();
    List<UserModel> searchResults = [];
    List<UserModel> myFollowers = []; // Utilisateurs qui me suivent (pour groupes User)
    List<UserModel> myAbonnes = []; // Abonnés de la société (pour groupes Société)
    List<UserModel> followingUsers = []; // Utilisateurs que je suis
    bool isSearching = false;
    bool isLoading = true;
    int currentTab = 0; // 0 = Mes suivis, 1 = Mes abonnés/followers, 2 = Recherche

    // Déterminer si le groupe est créé par une Société
    final isGroupeFromSociete = _groupe?.isCreatedBySociete() ?? false;
    print('📦 [Invitation] Groupe créé par Société: $isGroupeFromSociete');

    // Charger les données initiales
    try {
      // Récupérer l'utilisateur/société courant pour obtenir son ID
      final currentUserResponse = await ApiService.get('/auth/me');
      int? currentUserId;
      if (currentUserResponse.statusCode == 200) {
        final userData = jsonDecode(currentUserResponse.body);
        currentUserId = userData['data']?['id'] ?? userData['id'];
        print('📦 [Invitation] Utilisateur courant ID: $currentUserId');
      }

      // Charger les utilisateurs que je suis (avec détails)
      final myFollowing = await suivre.SuivreAuthService.getMyFollowing(
        type: suivre.EntityType.user,
        includeDetails: true,
      );
      // Convertir SuivreModel en UserModel
      followingUsers = myFollowing
          .where((s) => s.followedUser != null)
          .map((s) => UserModel.fromJson(s.followedUser!))
          .toList();
      print('✅ ${followingUsers.length} utilisateurs suivis chargés');

      // Charger selon le type de créateur du groupe
      if (isGroupeFromSociete) {
        // Pour les groupes de Société: charger les ABONNÉS de la société
        print('📦 [Invitation] Chargement des abonnés de la société...');
        if (_groupe?.createdById != null) {
          try {
            final abonnesData = await suivre.SuivreAuthService.getFollowers(
              entityId: _groupe!.createdById,
              entityType: suivre.EntityType.societe,
            );
            myAbonnes = abonnesData
                .map((data) => UserModel.fromJson(data))
                .toList();
            print('✅ ${myAbonnes.length} abonnés de la société chargés');
          } catch (e) {
            print('⚠️ Erreur chargement abonnés société: $e');
          }
        }
      } else {
        // Pour les groupes d'User: charger les FOLLOWERS de l'utilisateur
        print('📦 [Invitation] Chargement des followers de l\'utilisateur...');
        if (currentUserId != null) {
          try {
            final followersData = await suivre.SuivreAuthService.getFollowers(
              entityId: currentUserId,
              entityType: suivre.EntityType.user,
            );
            myFollowers = followersData
                .map((data) => UserModel.fromJson(data))
                .toList();
            print('✅ ${myFollowers.length} followers chargés');
          } catch (e) {
            print('⚠️ Erreur chargement followers: $e');
          }
        }
      }

      isLoading = false;
    } catch (e) {
      print('❌ Erreur chargement données invitation: $e');
      isLoading = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inviter des membres'),
          content: SizedBox(
            width: double.maxFinite,
            height: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Onglets de sélection
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton(
                        label: 'Mes suivis',
                        icon: Icons.person_add,
                        count: followingUsers.length,
                        isSelected: currentTab == 0,
                        onTap: () => setDialogState(() => currentTab = 0),
                      ),
                      const SizedBox(width: 8),
                      // "Mes abonnés" uniquement pour groupes Société
                      if (isGroupeFromSociete && myAbonnes.isNotEmpty)
                        _buildTabButton(
                          label: 'Mes abonnés',
                          icon: Icons.people,
                          count: myAbonnes.length,
                          isSelected: currentTab == 1,
                          onTap: () => setDialogState(() => currentTab = 1),
                        ),
                      // "Mes followers" pour groupes User
                      if (!isGroupeFromSociete && myFollowers.isNotEmpty)
                        _buildTabButton(
                          label: 'Mes followers',
                          icon: Icons.people_outline,
                          count: myFollowers.length,
                          isSelected: currentTab == 1,
                          onTap: () => setDialogState(() => currentTab = 1),
                        ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        label: 'Recherche',
                        icon: Icons.search,
                        count: null,
                        isSelected: currentTab == 2,
                        onTap: () => setDialogState(() => currentTab = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu selon l'onglet sélectionné
                if (isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (currentTab == 0)
                  // Onglet "Mes suivis"
                  _buildUserList(
                    users: followingUsers,
                    emptyIcon: Icons.person_add_disabled,
                    emptyTitle: 'Aucun suivi',
                    emptySubtitle:
                        'Vous ne suivez aucun utilisateur pour le moment',
                    setDialogState: setDialogState,
                  )
                else if (currentTab == 1)
                  // Onglet "Mes abonnés" (Société) ou "Mes followers" (User)
                  _buildUserList(
                    users: isGroupeFromSociete ? myAbonnes : myFollowers,
                    emptyIcon: Icons.people_outline,
                    emptyTitle: isGroupeFromSociete ? 'Aucun abonné' : 'Aucun follower',
                    emptySubtitle: isGroupeFromSociete
                        ? 'Aucun utilisateur n\'est abonné à votre société'
                        : 'Aucun utilisateur ne vous suit pour le moment',
                    setDialogState: setDialogState,
                  )
                else if (currentTab == 2)
                  // Onglet "Recherche"
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher par nom ou email',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: isSearching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (value) async {
                            if (value.length < 2) {
                              setDialogState(() => searchResults = []);
                              return;
                            }

                            setDialogState(() => isSearching = true);

                            try {
                              final results = await UserAuthService.searchUsers(
                                query: value,
                                limit: 10,
                              );
                              setDialogState(() {
                                searchResults = results;
                                isSearching = false;
                              });
                            } catch (e) {
                              setDialogState(() => isSearching = false);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: searchResults.isNotEmpty
                              ? ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = searchResults[index];
                                    return _buildUserTile(user);
                                  },
                                )
                              : Center(
                                  child: Text(
                                    searchController.text.length >= 2
                                        ? 'Aucun utilisateur trouvé'
                                        : 'Entrez un nom ou email pour rechercher',
                                    style: const TextStyle(color: darkGray),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire un bouton d'onglet
  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : darkGray),
            const SizedBox(width: 6),
            Text(
              count != null ? '$label ($count)' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : darkGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire la liste des utilisateurs
  Widget _buildUserList({
    required List<UserModel> users,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required StateSetter setDialogState,
  }) {
    if (users.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(emptyIcon, size: 48, color: darkGray),
              const SizedBox(height: 8),
              Text(
                emptyTitle,
                style: const TextStyle(
                  color: darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emptySubtitle,
                style: const TextStyle(color: darkGray, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserTile(user);
        },
      ),
    );
  }

  /// Construire une tuile d'utilisateur
  Widget _buildUserTile(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primaryColor,
        backgroundImage: user.profile?.photo != null
            ? NetworkImage(user.profile!.photo!)
            : null,
        child: user.profile?.photo == null
            ? Text(
                user.nom.isNotEmpty
                    ? user.nom.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text('${user.prenom} ${user.nom}'),
      subtitle: Text(user.email ?? user.numero),
      trailing: ElevatedButton.icon(
        icon: const Icon(Icons.person_add, size: 16),
        label: const Text('Inviter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onPressed: () async {
          Navigator.pop(context);
          await _sendInvitation(user);
        },
      ),
    );
  }

  /// Envoyer une invitation à un utilisateur
  Future<void> _sendInvitation(UserModel user) async {
    // Dialog pour message optionnel
    final messageController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inviter ${user.nom} ${user.prenom}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoyer une invitation à rejoindre "${_groupe!.nom}"',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Message (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, messageController.text),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (message == null) return; // User a annulé

    // Envoyer l'invitation ou ajouter directement
    try {
      final result = await GroupeInvitationService.inviteMembre(
        groupeId: widget.groupeId,
        invitedUserId: user.id,
        message: message.isEmpty ? null : message,
      );

      if (mounted) {
        // Vérifier si c'est un ajout direct ou une invitation
        final ajoutDirect = result['ajoutDirect'] ?? false;
        final resultMessage = result['message'] as String?;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ajoutDirect
                  ? resultMessage ??
                        '${user.prenom} ${user.nom} a été ajouté(e) au groupe'
                  : resultMessage ??
                        'Invitation envoyée à ${user.prenom} ${user.nom}',
            ),
            backgroundColor: primaryColor,
          ),
        );

        // Recharger les membres si ajout direct
        if (ajoutDirect) {
          _loadGroupeData();
        }
      }
    } catch (e) {
      if (mounted) {
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
        actions: [
          // Bouton de messagerie de groupe (visible pour tous les membres)
          if (_isMember)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {
                if (_groupe != null) {
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
              },
              tooltip: 'Messagerie du groupe',
            ),
          if (_myRole == MembreRole.admin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  // TODO: Naviguer vers la page d'édition
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité d\'édition à implémenter'),
                    ),
                  );
                } else if (value == 'delete') {
                  _deleteGroupe();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: _groupe != null
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Infos', icon: Icon(Icons.info_outline, size: 20)),
                  Tab(
                    text: 'Membres',
                    icon: Icon(Icons.people_outline, size: 20),
                  ),
                  Tab(
                    text: 'Posts',
                    icon: Icon(Icons.article_outlined, size: 20),
                  ),
                ],
              )
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _myRole == MembreRole.admin
          ? FloatingActionButton.extended(
              onPressed: _showInviteUserDialog,
              backgroundColor: primaryColor,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Inviter',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _groupe == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage ?? 'Groupe introuvable',
                textAlign: TextAlign.center,
                style: const TextStyle(color: darkGray),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGroupeData,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildInfoTab(), _buildMembresTab(), _buildPostsTab()],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    image: _groupe!.getLogoUrl() != null
                        ? DecorationImage(
                            image: NetworkImage(_groupe!.getLogoUrl()!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _groupe!.getLogoUrl() == null
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
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.category,
                  label: 'Catégorie',
                  value: _getCategorieLabel(_groupe!.categorie),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          if (_groupe!.description != null) ...[
            const Text(
              'Description',
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
                _groupe!.description!,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Informations supplémentaires
          const Text(
            'Informations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Créé le',
            value: _groupe!.createdAt != null
                ? _formatDate(_groupe!.createdAt!)
                : 'N/A',
          ),
          _buildInfoRow(
            icon: Icons.person,
            label: 'Créé par',
            value: _groupe!.isCreatedBySociete() ? 'Société' : 'Utilisateur',
          ),
          _buildInfoRow(
            icon: Icons.group_add,
            label: 'Capacité max',
            value: '${_groupe!.maxMembres} membres',
          ),
        ],
      ),
    );
  }

  /// Charger les membres du groupe
  Future<void> _loadMembres() async {
    if (_isLoadingMembres) return;

    setState(() {
      _isLoadingMembres = true;
      _membresError = null;
    });

    try {
      final membres = await GroupeMembreService.getMembres(widget.groupeId);
      if (mounted) {
        setState(() {
          _membres = membres;
          _isLoadingMembres = false;
          _membresLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _membresError = e.toString();
          _isLoadingMembres = false;
          _membresLoaded = true;
        });
      }
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'moderateur':
        return 'Modérateur';
      default:
        return 'Membre';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'moderateur':
        return Colors.blue;
      default:
        return primaryColor;
    }
  }

  Widget _buildMembresTab() {
    // Charger les membres au premier affichage
    if (!_membresLoaded && !_isLoadingMembres) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMembres();
      });
    }

    if (_isLoadingMembres) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des membres...'),
          ],
        ),
      );
    }

    if (_membresError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _membresError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: darkGray, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMembres,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      );
    }

    if (_membres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun membre',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembres,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _membres.length,
        itemBuilder: (context, index) {
          final membre = _membres[index];
          final user = membre['user'] as Map<String, dynamic>?;
          final nom = user?['nom'] ?? '';
          final prenom = user?['prenom'] ?? '';
          final photo = user?['photo'] ?? user?['profile']?['photo'];
          final role = membre['role'] as String?;
          final displayName = '$prenom $nom'.trim();

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.2),
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                child: photo == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(
                displayName.isNotEmpty ? displayName : 'Membre',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                user?['email'] ?? user?['numero'] ?? '',
                style: const TextStyle(fontSize: 12, color: darkGray),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getRoleColor(role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRoleLabel(role),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getRoleColor(role),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsTab() {
    // Charger les posts au premier affichage uniquement
    if (!_postsLoaded && !_isLoadingPosts) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGroupePosts();
      });
    }

    // Affichage du chargement
    if (_isLoadingPosts) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des publications...'),
          ],
        ),
      );
    }

    // Affichage de l'erreur
    if (_postsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _postsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: darkGray, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadGroupePosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      );
    }

    // Affichage si pas de posts
    if (_groupePosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune publication',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Soyez le premier à publier dans ce groupe !',
              style: TextStyle(fontSize: 14, color: darkGray),
            ),
            if (_isMember) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreerPostPage(),
                    ),
                  );
                  if (result == true) {
                    _loadGroupePosts();
                  }
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Créer un post', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              ),
            ],
          ],
        ),
      );
    }

    // Affichage des posts
    return RefreshIndicator(
      onRefresh: _loadGroupePosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _groupePosts.length,
        itemBuilder: (context, index) {
          final post = _groupePosts[index];
          return _GroupePostCard(
            post: post,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailsPage(postId: post.id),
                ),
              );
              _loadGroupePosts(); // Rafraîchir après retour
            },
          );
        },
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
          Text(label, style: const TextStyle(fontSize: 14, color: darkGray)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_groupe == null) return null;

    // Si je ne suis pas membre et que le groupe est public
    if (!_isMember && _groupe!.isPublic()) {
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
            onPressed: _groupe!.isFull() ? null : _joinGroupe,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.group_add),
            label: Text(
              _groupe!.isFull() ? 'Groupe plein' : 'Rejoindre le groupe',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    // Si je suis membre (mais pas admin)
    if (_isMember && _myRole != MembreRole.admin) {
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
          child: OutlinedButton.icon(
            onPressed: _leaveGroupe,
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
      );
    }

    return null;
  }

  String _getCategorieLabel(GroupeCategorie categorie) {
    switch (categorie) {
      case GroupeCategorie.simple:
        return 'Simple';
      case GroupeCategorie.professionnel:
        return 'Professionnel';
      case GroupeCategorie.supergroupe:
        return 'Super Groupe';
      case GroupeCategorie.active:
        return 'Actif';
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
      'Déc',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Widget pour afficher une carte de post dans le groupe
class _GroupePostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const _GroupePostCard({
    required this.post,
    this.onTap,
  });

  // Couleurs
  static const Color primaryColor = Color(0xff5ac18e);
  static const Color darkGray = Color(0xFF8D8D8D);

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return 'Il y a ${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Il y a ${diff.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  /// Transformer l'URL du média en URL complète si nécessaire
  String _getMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://api.titingre.com/storage/$url';
  }

  /// Détecter si c'est une vidéo basé sur l'extension
  bool _isVideo(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.mp4') ||
        lowercaseUrl.endsWith('.mov') ||
        lowercaseUrl.endsWith('.avi') ||
        lowercaseUrl.endsWith('.mkv') ||
        lowercaseUrl.endsWith('.webm');
  }

  /// Détecter si c'est un audio basé sur l'extension
  bool _isAudio(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.mp3') ||
        lowercaseUrl.endsWith('.wav') ||
        lowercaseUrl.endsWith('.aac') ||
        lowercaseUrl.endsWith('.m4a') ||
        lowercaseUrl.endsWith('.ogg');
  }

  /// Construire le widget média approprié
  Widget _buildMediaWidget(String url, ColorScheme cs) {
    final fullUrl = _getMediaUrl(url);

    if (_isVideo(url)) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.movie, size: 50, color: Colors.white.withOpacity(0.3)),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Vidéo', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isAudio(url)) {
      return VoiceMessagePlayer(audioUrl: fullUrl);
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: R2NetworkImage(
          imageUrl: fullUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authorPhoto = post.getAuthorPhoto();
    final hasMedia = post.hasMedia() && post.mediaUrls!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec auteur
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    backgroundImage: authorPhoto != null ? NetworkImage(authorPhoto) : null,
                    child: authorPhoto == null
                        ? Icon(
                            post.authorType == AuthorType.societe ? Icons.business : Icons.person,
                            size: 20,
                            color: primaryColor,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.getAuthorName(),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          _formatTimestamp(post.createdAt),
                          style: TextStyle(fontSize: 12, color: darkGray),
                        ),
                      ],
                    ),
                  ),
                  // Badge de visibilité
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      post.visibility == PostVisibility.adminsOnly ? 'Admins' : 'Membres',
                      style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contenu du post
              if (post.contenu.isNotEmpty) ...[
                Text(
                  post.contenu,
                  style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.85), height: 1.4),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Média
              if (hasMedia) ...[
                _buildMediaWidget(post.mediaUrls!.first, cs),
                if (post.mediaUrls!.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${post.mediaUrls!.length - 1} autre(s) média(s)',
                      style: TextStyle(fontSize: 12, color: darkGray),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Statistiques
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 18, color: darkGray),
                  const SizedBox(width: 4),
                  Text('${post.likesCount}', style: TextStyle(fontSize: 12, color: darkGray)),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 18, color: darkGray),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}', style: TextStyle(fontSize: 12, color: darkGray)),
                  const Spacer(),
                  Icon(Icons.share_outlined, size: 18, color: darkGray),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
