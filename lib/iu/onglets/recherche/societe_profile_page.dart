import 'package:flutter/material.dart';
import '../../../services/AuthUS/societe_auth_service.dart';
import '../../../services/suivre/suivre_auth_service.dart';
import '../../../widgets/editable_profile_avatar.dart';

/// Page de profil pour visualiser le profil d'une AUTRE société
/// (pas MA société - pour MA société, utiliser une page éditable séparée)
class SocieteProfilePage extends StatefulWidget {
  final int societeId;
  const SocieteProfilePage({super.key, required this.societeId});

  @override
  State<SocieteProfilePage> createState() => _SocieteProfilePageState();
}

class _SocieteProfilePageState extends State<SocieteProfilePage> {
  bool _isLoading = true;
  bool _isActionLoading = false;
  SocieteModel? _societe;
  bool _isSuivant = false; // true si on suit déjà cette société
  bool _isAbonne = false; // true si on est abonné (upgrade payant)

  static const Color primaryColor = Color(0xff5ac18e);

  @override
  void initState() {
    super.initState();
    _loadSocieteProfile();
  }

  /// Charge le profil de la société et son statut de suivi
  Future<void> _loadSocieteProfile() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger le profil de la société
      final societe = await SocieteAuthService.getSocieteProfile(widget.societeId);

      // 2. Vérifier si on suit déjà cette société
      bool isSuivant = false;
      try {
        isSuivant = await SuivreAuthService.checkSuivi(
          followedId: widget.societeId,
          followedType: EntityType.societe,
        );
      } catch (e) {
        // Si erreur, considérer qu'on ne suit pas
        isSuivant = false;
      }

      // TODO: Vérifier si on est abonné (upgrade payant)
      // Pour l'instant, on considère qu'on n'est pas abonné
      bool isAbonne = false;

      if (mounted) {
        setState(() {
          _societe = societe;
          _isSuivant = isSuivant;
          _isAbonne = isAbonne;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Suivre la société (gratuit)
  Future<void> _suivreSociete() async {
    setState(() => _isActionLoading = true);

    try {
      await SuivreAuthService.suivre(
        followedId: widget.societeId,
        followedType: EntityType.societe,
      );

      if (mounted) {
        setState(() {
          _isSuivant = true;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous suivez maintenant cette société'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Ne plus suivre la société
  Future<void> _unfollowSociete() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(
          'Voulez-vous ne plus suivre ${_societe!.nom} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await SuivreAuthService.unfollow(
        followedId: widget.societeId,
        followedType: EntityType.societe,
      );

      if (mounted) {
        setState(() {
          _isSuivant = false;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous ne suivez plus cette société'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// S'abonner à la société (upgrade payant)
  /// UNIQUEMENT pour User → Societe
  Future<void> _sabonner() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('S\'abonner'),
        content: Text(
          'Voulez-vous vous abonner à ${_societe!.nom} ?\n\nCeci est un abonnement payant qui vous donnera accès à des fonctionnalités premium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await SuivreAuthService.upgradeToAbonnement(
        societeId: widget.societeId,
        planCollaboration: 'Premium', // Peut être personnalisé
      );

      if (mounted) {
        setState(() {
          _isAbonne = true;
          _isSuivant = true; // Si on est abonné, on suit forcément
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement réussi ! Vous êtes maintenant abonné à cette société.'),
            backgroundColor: primaryColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isActionLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil Société'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_societe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil Société'),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Société introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_societe!.nom),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Logo de la société (lecture seule)
            Center(
              child: ReadOnlyProfileAvatar(
                size: 100,
                photoUrl: _societe!.profile?.logo,
                borderColor: primaryColor,
                borderWidth: 4,
              ),
            ),

            const SizedBox(height: 16),

            // Nom de la société
            Text(
              _societe!.nom,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Email et téléphone
            Text(
              _societe!.email,
              style: const TextStyle(color: Colors.grey),
            ),
            if (_societe!.telephone != null)
              Text(
                _societe!.telephone!,
                style: const TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 8),

            // Secteur d'activité
            if (_societe!.secteurActivite != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _societe!.secteurActivite!,
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Boutons d'action
            _buildActionButtons(),

            const SizedBox(height: 24),

            // Description
            if (_societe!.profile?.description != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_societe!.profile!.description!),
                  ],
                ),
              ),
            ],

            // Produits
            if (_societe!.profile?.produits != null &&
                _societe!.profile!.produits!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Produits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _societe!.profile!.produits!
                          .map(
                            (produit) => Chip(
                              label: Text(produit),
                              backgroundColor:
                                  primaryColor.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: primaryColor),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Services
            if (_societe!.profile?.services != null &&
                _societe!.profile!.services!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _societe!.profile!.services!
                          .map(
                            (service) => Chip(
                              label: Text(service),
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.blue),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Centres d'intérêt
            if (_societe!.profile?.centresInteret != null &&
                _societe!.profile!.centresInteret!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Centres d\'intérêt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _societe!.profile!.centresInteret!
                          .map(
                            (centre) => Chip(
                              label: Text(centre),
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.orange),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Informations supplémentaires
            if (_societe!.profile?.siteWeb != null ||
                _societe!.profile?.nombreEmployes != null ||
                _societe!.profile?.anneeCreation != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_societe!.profile?.siteWeb != null)
                      _buildInfoRow(Icons.web, 'Site web', _societe!.profile!.siteWeb!),
                    if (_societe!.profile?.nombreEmployes != null)
                      _buildInfoRow(Icons.people, 'Employés', '${_societe!.profile!.nombreEmployes} employés'),
                    if (_societe!.profile?.anneeCreation != null)
                      _buildInfoRow(Icons.calendar_today, 'Fondée en', '${_societe!.profile!.anneeCreation}'),
                    if (_societe!.adresse != null)
                      _buildInfoRow(Icons.location_on, 'Adresse', _societe!.adresse!),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Boutons d'action selon le statut de suivi et d'abonnement
  Widget _buildActionButtons() {
    if (_isActionLoading) {
      return const CircularProgressIndicator();
    }

    // Si déjà abonné, afficher seulement le badge "Abonné Premium"
    if (_isAbonne) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xffFFD700), Color(0xffFFA500)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.star, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Abonné Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Sinon, afficher les boutons Suivre et S'abonner
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Suivre / Abonné (gratuit)
        if (_isSuivant)
          OutlinedButton.icon(
            onPressed: _unfollowSociete,
            icon: const Icon(Icons.check, color: primaryColor),
            label: const Text(
              'Suivi',
              style: TextStyle(color: primaryColor, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryColor, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: _suivreSociete,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Suivre',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),

        const SizedBox(width: 12),

        // Bouton S'abonner (payant)
        ElevatedButton.icon(
          onPressed: _sabonner,
          icon: const Icon(Icons.star, color: Colors.white),
          label: const Text(
            'S\'abonner',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffFFA500), // Orange pour premium
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Widget pour afficher une ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
