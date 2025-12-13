import 'package:flutter/material.dart';
import '../../../services/AuthUS/societe_auth_service.dart';
import '../../../services/suivre/suivre_auth_service.dart';
import '../../../services/suivre/demande_abonnement_service.dart';
import '../../../services/suivre/abonnement_auth_service.dart' as abonnement_service;
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
  abonnement_service.AbonnementModel? _abonnementDetails; // Détails de l'abonnement actif

  // États de demande d'abonnement
  bool _demandeAbonnementEnvoyee = false;
  DemandeAbonnementStatus? _demandeAbonnementStatut;

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

      // 3. Vérifier si on a une demande d'abonnement en attente
      bool demandeAbonnementEnvoyee = false;
      DemandeAbonnementStatus? demandeAbonnementStatut;
      try {
        final demande = await DemandeAbonnementService.checkDemandeExistante(
          widget.societeId,
        );
        if (demande != null) {
          demandeAbonnementEnvoyee = true;
          demandeAbonnementStatut = demande.status;
        }
      } catch (e) {
        // Pas de demande en attente
        demandeAbonnementEnvoyee = false;
      }

      // 4. Vérifier si on est abonné à cette société (via checkAbonnement)
      bool isAbonne = false;
      abonnement_service.AbonnementModel? abonnementDetails;
      try {
        final abonnementCheck = await abonnement_service.AbonnementAuthService.checkAbonnement(widget.societeId);
        isAbonne = abonnementCheck['is_abonne'] == true;

        // Si abonné, récupérer les détails de l'abonnement
        if (isAbonne && abonnementCheck['abonnement'] != null) {
          abonnementDetails = abonnement_service.AbonnementModel.fromJson(abonnementCheck['abonnement']);
        }
      } catch (e) {
        // Pas d'abonnement actif
        isAbonne = false;
        abonnementDetails = null;
      }

      if (mounted) {
        setState(() {
          _societe = societe;
          _isSuivant = isSuivant;
          _isAbonne = isAbonne;
          _abonnementDetails = abonnementDetails;
          _demandeAbonnementEnvoyee = demandeAbonnementEnvoyee;
          _demandeAbonnementStatut = demandeAbonnementStatut;
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

  /// S'abonner à la société (envoyer une demande d'abonnement premium)
  /// UNIQUEMENT pour User → Societe
  Future<void> _sabonner() async {
    // Si déjà une demande en attente, afficher un message
    if (_demandeAbonnementEnvoyee && _demandeAbonnementStatut == DemandeAbonnementStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà une demande d\'abonnement en attente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Dialog pour message optionnel
    final messageController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('S\'abonner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envoyer une demande d\'abonnement à ${_societe!.nom}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'abonnement premium vous donnera accès à des fonctionnalités exclusives.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffFFA500)),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (message == null) return;

    setState(() => _isActionLoading = true);

    try {
      await DemandeAbonnementService.envoyerDemande(
        societeId: widget.societeId,
        message: message.isEmpty ? null : message,
      );

      if (mounted) {
        setState(() {
          _demandeAbonnementEnvoyee = true;
          _demandeAbonnementStatut = DemandeAbonnementStatus.pending;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande d\'abonnement envoyée avec succès'),
            backgroundColor: Color(0xffFFA500),
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

  /// Gérer l'abonnement actif (voir détails et annuler)
  Future<void> _gererAbonnement() async {
    if (_abonnementDetails == null) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Color(0xffFFA500)),
            const SizedBox(width: 8),
            const Text('Abonnement Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vous êtes abonné à cette société',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildAbonnementInfoRow(
              Icons.business,
              'Société',
              _societe!.nom,
            ),
            _buildAbonnementInfoRow(
              Icons.calendar_today,
              'Date de début',
              _abonnementDetails!.dateDebut != null
                  ? '${_abonnementDetails!.dateDebut!.day}/${_abonnementDetails!.dateDebut!.month}/${_abonnementDetails!.dateDebut!.year}'
                  : 'Non définie',
            ),
            _buildAbonnementInfoRow(
              Icons.event,
              'Date de fin',
              _abonnementDetails!.dateFin != null
                  ? '${_abonnementDetails!.dateFin!.day}/${_abonnementDetails!.dateFin!.month}/${_abonnementDetails!.dateFin!.year}'
                  : 'Indéterminée',
            ),
            if (_abonnementDetails!.planCollaboration != null)
              _buildAbonnementInfoRow(
                Icons.workspace_premium,
                'Plan',
                _abonnementDetails!.planCollaboration!,
              ),
            _buildAbonnementInfoRow(
              Icons.verified,
              'Statut',
              _abonnementDetails!.statut.value,
              valueColor: const Color(0xff28A745),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _annulerAbonnement();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text(
              'Annuler l\'abonnement',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper pour afficher une ligne d'info dans le dialog
  Widget _buildAbonnementInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xffFFA500)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Annuler l'abonnement actif
  Future<void> _annulerAbonnement() async {
    if (_abonnementDetails == null) return;

    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement premium à ${_societe!.nom} ?\n\nCette action est irréversible et vous perdrez l\'accès aux fonctionnalités exclusives.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Oui, annuler',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      await abonnement_service.AbonnementAuthService.deleteAbonnement(_abonnementDetails!.id);

      if (mounted) {
        setState(() {
          _isAbonne = false;
          _abonnementDetails = null;
          _isActionLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement annulé avec succès'),
            backgroundColor: Colors.orange,
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

  /// Annuler une demande d'abonnement envoyée
  Future<void> _annulerDemandeAbonnement() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text(
          'Voulez-vous vraiment annuler votre demande d\'abonnement ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isActionLoading = true);

    try {
      // On doit retrouver l'ID de la demande
      final demande = await DemandeAbonnementService.checkDemandeExistante(
        widget.societeId,
      );

      if (demande != null) {
        await DemandeAbonnementService.annulerDemande(demande.id);

        if (mounted) {
          setState(() {
            _demandeAbonnementEnvoyee = false;
            _demandeAbonnementStatut = null;
            _isActionLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demande d\'abonnement annulée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
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

    // Si déjà abonné (demande acceptée), afficher le badge "Abonné Premium" avec bouton de gestion
    if (_isAbonne) {
      return Column(
        children: [
          Container(
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
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _gererAbonnement,
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Gérer l\'abonnement'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffFFA500),
              side: const BorderSide(color: Color(0xffFFA500), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      );
    }

    // Sinon, afficher les boutons Suivre et S'abonner
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Suivre / Suivi (gratuit)
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

        // Bouton S'abonner - Selon l'état de la demande
        _buildAbonnementButton(),
      ],
    );
  }

  /// Bouton d'abonnement selon l'état de la demande
  Widget _buildAbonnementButton() {
    // Si demande en attente
    if (_demandeAbonnementEnvoyee && _demandeAbonnementStatut == DemandeAbonnementStatus.pending) {
      return OutlinedButton.icon(
        onPressed: _annulerDemandeAbonnement,
        icon: const Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
        label: const Text(
          'Demande en attente',
          style: TextStyle(color: Colors.orange, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orange, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    }

    // Si demande refusée
    if (_demandeAbonnementEnvoyee && _demandeAbonnementStatut == DemandeAbonnementStatus.declined) {
      return OutlinedButton.icon(
        onPressed: null, // Désactivé
        icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
        label: const Text(
          'Demande refusée',
          style: TextStyle(color: Colors.red, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      );
    }

    // Sinon, bouton normal "S'abonner"
    return ElevatedButton.icon(
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
