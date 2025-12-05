import 'package:flutter/material.dart';
import '../services/groupe/groupe_service.dart';
import '../services/groupe/groupe_membre_service.dart';

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
      final results = await Future.wait([
        GroupeAuthService.getGroupe(widget.groupeId),
        GroupeAuthService.isMember(widget.groupeId),
        GroupeAuthService.getMyRole(widget.groupeId),
      ]);

      if (mounted) {
        setState(() {
          _groupe = results[0] as GroupeModel;
          _isMember = results[1] as bool;
          _myRole = results[2] as MembreRole?;
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
                      icon: Icon(Icons.people_outline, size: 20)),
                  Tab(text: 'Posts', icon: Icon(Icons.article_outlined, size: 20)),
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
      children: [
        _buildInfoTab(),
        _buildMembresTab(),
        _buildPostsTab(),
      ],
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

  Widget _buildMembresTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Liste des membres',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fonctionnalité à implémenter',
            style: TextStyle(fontSize: 14, color: darkGray),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Publications du groupe',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fonctionnalité à implémenter',
            style: TextStyle(fontSize: 14, color: darkGray),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
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
