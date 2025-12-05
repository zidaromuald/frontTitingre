import 'package:flutter/material.dart';
import '../services/groupe/groupe_service.dart';
import 'create_groupe_page.dart';
import 'groupe_detail_page.dart';

/// Page listant MES groupes (ceux dont je suis membre)
/// Accessible depuis l'interface User ET Société
class MesGroupesPage extends StatefulWidget {
  const MesGroupesPage({super.key});

  @override
  State<MesGroupesPage> createState() => _MesGroupesPageState();
}

class _MesGroupesPageState extends State<MesGroupesPage> {
  List<GroupeModel> _groupes = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Couleurs
  static const Color primaryColor = Color(0xff5ac18e);
  static const Color darkGray = Color(0xFF8D8D8D);
  static const Color lightGray = Color(0xFFF4F4F4);

  @override
  void initState() {
    super.initState();
    _loadGroupes();
  }

  Future<void> _loadGroupes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupes = await GroupeAuthService.getMyGroupes();
      if (mounted) {
        setState(() {
          _groupes = groupes;
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

  Future<void> _navigateToCreateGroupe() async {
    final result = await Navigator.push<GroupeModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateGroupePage(),
      ),
    );

    // Si un groupe a été créé, recharger la liste
    if (result != null) {
      _loadGroupes();
    }
  }

  void _navigateToGroupeDetail(GroupeModel groupe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupeDetailPage(groupeId: groupe.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Groupes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadGroupes,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroupes,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateGroupe,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Créer un groupe'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: darkGray),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGroupes,
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_groupes.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groupes.length,
      itemBuilder: (context, index) {
        final groupe = _groupes[index];
        return _buildGroupeCard(groupe);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_add,
                size: 80,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun groupe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'êtes membre d\'aucun groupe pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: darkGray,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateGroupe,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Créer mon premier groupe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupeCard(GroupeModel groupe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToGroupeDetail(groupe),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo du groupe
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  image: groupe.getLogoUrl() != null
                      ? DecorationImage(
                          image: NetworkImage(groupe.getLogoUrl()!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: groupe.getLogoUrl() == null
                    ? const Icon(
                        Icons.group,
                        size: 32,
                        color: primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Informations du groupe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupe.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (groupe.description != null)
                      Text(
                        groupe.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkGray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Type de groupe
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: groupe.isPublic()
                                ? Colors.blue.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                groupe.isPublic() ? Icons.public : Icons.lock,
                                size: 12,
                                color: groupe.isPublic()
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                groupe.isPublic() ? 'Public' : 'Privé',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: groupe.isPublic()
                                      ? Colors.blue
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Nombre de membres
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.people,
                                size: 12,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${groupe.membresCount ?? 0}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Catégorie
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getCategorieLabel(groupe.categorie),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Icône de navigation
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: darkGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategorieLabel(GroupeCategorie categorie) {
    switch (categorie) {
      case GroupeCategorie.simple:
        return 'Simple';
      case GroupeCategorie.professionnel:
        return 'Pro';
      case GroupeCategorie.supergroupe:
        return 'Super';
    }
  }
}
