import 'package:flutter/material.dart';
import '../../../services/AuthUS/user_auth_service.dart';
import '../../../services/AuthUS/unified_auth_service.dart';
import '../../../widgets/editable_profile_avatar.dart';
import '../../../loginScreen.dart';

class ProfilDetailPage extends StatefulWidget {
  const ProfilDetailPage({super.key});

  @override
  State<ProfilDetailPage> createState() => _ProfilDetailPageState();
}

class _ProfilDetailPageState extends State<ProfilDetailPage> {
  // Controllers
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _numeroController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _formationController;

  // État
  bool _isLoading = true;
  bool _isSaving = false;
  String? _photoUrl;
  List<String> _competences = [];

  // Couleurs
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _numeroController = TextEditingController();
    _bioController = TextEditingController();
    _experienceController = TextEditingController();
    _formationController = TextEditingController();

    _loadMyProfile();
  }

  /// Charger le profil de l'utilisateur connecté
  Future<void> _loadMyProfile() async {
    setState(() => _isLoading = true);

    try {
      // Appel à l'API pour récupérer MON profil
      final userModel = await UserAuthService.getMyProfile();

      setState(() {
        // Remplir les controllers avec les données récupérées
        _nomController.text = userModel.nom;
        _prenomController.text = userModel.prenom;
        _emailController.text = userModel.email ?? '';
        _numeroController.text = userModel.numero;

        // La photo est dans profile.photo
        _photoUrl = userModel.profile?.photo;

        // Charger les données du profil enrichi si disponibles
        if (userModel.profile != null) {
          _bioController.text = userModel.profile!.bio ?? '';
          _experienceController.text = userModel.profile!.experience ?? '';
          _formationController.text = userModel.profile!.formation ?? '';
          _competences = userModel.profile!.competences ?? [];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement du profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sauvegarder les modifications du profil
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      // Préparer les données à mettre à jour
      final updates = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'experience': _experienceController.text.trim(),
        'formation': _formationController.text.trim(),
        'competences': _competences,
      };

      // Appel à l'API pour mettre à jour le profil
      await UserAuthService.updateMyProfile(updates);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil sauvegardé avec succès"),
            backgroundColor: mattermostGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

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


  /// Ajouter une compétence
  void _addCompetence() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Ajouter une compétence"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Ex: Flutter"),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _competences.add(controller.text.trim());
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mattermostBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  /// Retirer une compétence
  void _removeCompetence(String competence) {
    setState(() {
      _competences.remove(competence);
    });
  }

  /// Déconnexion du compte (User ou Société)
  Future<void> _logout() async {
    // Demander confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Appeler le service de déconnexion unifié
      await UnifiedAuthService.logout();

      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.pop(context);
      }

      // Naviguer vers la page de login et effacer tout l'historique
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) {
        Navigator.pop(context);
      }

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
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
        backgroundColor: mattermostGray,
        appBar: AppBar(
          backgroundColor: mattermostBlue,
          title: const Text(
            "Mon Profil",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: mattermostBlue,
        title: const Text("Mon Profil", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save, color: Colors.white),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Photo de profil
              Center(
                child: EditableProfileAvatar(
                  size: 100,
                  currentPhotoUrl: _photoUrl,
                  onPhotoUpdated: (newUrl) {
                    setState(() {
                      _photoUrl = newUrl;
                    });
                  },
                  borderColor: mattermostBlue,
                  borderWidth: 4,
                ),
              ),

              const SizedBox(height: 24),

              // Informations non modifiables (affichées uniquement)
              _buildReadOnlyCard("Nom", _nomController.text),
              _buildReadOnlyCard("Prénom", _prenomController.text),
              _buildReadOnlyCard("Email", _emailController.text),
              _buildReadOnlyCard("Numéro", _numeroController.text),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Formulaire modifiable
              _buildTextField("Bio", _bioController, maxLines: 3),
              _buildTextField("Expérience", _experienceController, maxLines: 2),
              _buildTextField("Formation", _formationController, maxLines: 2),

              const SizedBox(height: 24),

              // Compétences
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Compétences",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_competences.isEmpty)
                      const Text(
                        "Aucune compétence ajoutée",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _competences
                            .map(
                              (competence) => Chip(
                                label: Text(
                                  competence,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: mattermostBlue.withOpacity(
                                  0.1,
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeCompetence(competence),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addCompetence,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Ajouter une compétence"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mattermostBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card de déconnexion
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          "Déconnexion",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Déconnectez-vous de votre compte en toute sécurité",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.exit_to_app, color: Colors.white),
                        label: const Text(
                          "Se déconnecter",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pour les champs en lecture seule
  Widget _buildReadOnlyCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Non renseigné' : value,
                  style: TextStyle(
                    fontSize: 16,
                    color: value.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
        ],
      ),
    );
  }

  /// Widget pour les champs de texte modifiables
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: mattermostBlue, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _numeroController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _formationController.dispose();
    super.dispose();
  }
}
