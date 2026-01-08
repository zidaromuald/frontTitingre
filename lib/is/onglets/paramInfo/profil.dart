import 'package:flutter/material.dart';
import '../../../services/AuthUS/societe_auth_service.dart';
import '../../../services/AuthUS/unified_auth_service.dart';
import '../../../widgets/editable_societe_avatar.dart';
import '../../../loginScreen.dart';

/// Page de profil pour MA société (éditable)
/// Pour éditer les informations de MA propre société
class ProfilDetailPage extends StatefulWidget {
  const ProfilDetailPage({super.key});

  @override
  State<ProfilDetailPage> createState() => _ProfilDetailPageState();
}

class _ProfilDetailPageState extends State<ProfilDetailPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  SocieteModel? _societe;
  String? _logoUrl;

  // Controllers pour les champs éditables
  late TextEditingController _descriptionController;
  late TextEditingController _siteWebController;
  late TextEditingController _nombreEmployesController;
  late TextEditingController _anneeCreationController;
  late TextEditingController _chiffreAffairesController;
  late TextEditingController _certificationsController;

  // Listes pour produits, services et centres d'intérêt
  List<String> _produits = [];
  List<String> _services = [];
  List<String> _centresInteret = [];

  static const Color primaryColor = Color(0xff5ac18e);

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _siteWebController = TextEditingController();
    _nombreEmployesController = TextEditingController();
    _anneeCreationController = TextEditingController();
    _chiffreAffairesController = TextEditingController();
    _certificationsController = TextEditingController();
    _loadMyProfile();
  }

  /// Charger le profil de MA société
  Future<void> _loadMyProfile() async {
    setState(() => _isLoading = true);

    try {
      final societe = await SocieteAuthService.getMyProfile();

      if (mounted) {
        setState(() {
          _societe = societe;
          _logoUrl = societe.profile?.logo;

          // Remplir les controllers avec les données existantes
          _descriptionController.text = societe.profile?.description ?? '';
          _siteWebController.text = societe.profile?.siteWeb ?? '';
          _nombreEmployesController.text =
              societe.profile?.nombreEmployes?.toString() ?? '';
          _anneeCreationController.text =
              societe.profile?.anneeCreation?.toString() ?? '';
          _chiffreAffairesController.text =
              societe.profile?.chiffreAffaires ?? '';
          _certificationsController.text =
              societe.profile?.certifications ?? '';

          // Remplir les listes
          _produits = societe.profile?.produits ?? [];
          _services = societe.profile?.services ?? [];
          _centresInteret = societe.profile?.centresInteret ?? [];

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

  /// Sauvegarder les modifications du profil
  Future<void> _saveProfile() async {
    if (_isSaving) return; // Éviter les doubles clics

    setState(() => _isSaving = true);

    try {
      // Préparer les données à envoyer
      final updates = {
        'description': _descriptionController.text.trim(),
        'site_web': _siteWebController.text.trim(),
        'nombre_employes': int.tryParse(_nombreEmployesController.text.trim()),
        'annee_creation': int.tryParse(_anneeCreationController.text.trim()),
        'chiffre_affaires': _chiffreAffairesController.text.trim(),
        'certifications': _certificationsController.text.trim(),
        'produits': _produits,
        'services': _services,
        'centres_interet': _centresInteret,
      };

      // Appeler l'API
      await SocieteAuthService.updateMyProfile(updates);

      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès'),
            backgroundColor: primaryColor,
          ),
        );

        // Recharger le profil
        await _loadMyProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);

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
          backgroundColor: primaryColor,
          title:
              const Text("Mon Profil", style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_societe == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          title:
              const Text("Mon Profil", style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('Profil non trouvé')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Mon Profil Société",
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save, color: Colors.white),
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyProfile,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Logo de la société (éditable)
              Center(
                child: EditableSocieteAvatar(
                  size: 100,
                  currentLogoUrl: _logoUrl,
                  onLogoUpdated: (newUrl) {
                    setState(() {
                      _logoUrl = newUrl;
                    });
                  },
                  borderColor: primaryColor,
                  borderWidth: 4,
                ),
              ),

              const SizedBox(height: 16),

              // Nom de la société (non éditable)
              Text(
                _societe!.nom,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Email (non éditable)
              Text(
                _societe!.email,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Informations de base
              _buildSectionTitle('Informations de base'),
              _buildTextField(
                  "Description", _descriptionController,
                  maxLines: 4),
              _buildTextField("Site web", _siteWebController),
              _buildTextField("Nombre d'employés", _nombreEmployesController,
                  keyboardType: TextInputType.number),
              _buildTextField("Année de création", _anneeCreationController,
                  keyboardType: TextInputType.number),
              _buildTextField(
                  "Chiffre d'affaires", _chiffreAffairesController),
              _buildTextField("Certifications", _certificationsController,
                  maxLines: 2),

              const SizedBox(height: 24),

              // Produits
              _buildSectionTitle('Produits'),
              _buildChipSection(
                items: _produits,
                onAdd: _addProduit,
                onRemove: (item) => setState(() => _produits.remove(item)),
                color: primaryColor,
              ),

              const SizedBox(height: 24),

              // Services
              _buildSectionTitle('Services'),
              _buildChipSection(
                items: _services,
                onAdd: _addService,
                onRemove: (item) => setState(() => _services.remove(item)),
                color: Colors.blue,
              ),

              const SizedBox(height: 24),

              // Centres d'intérêt
              _buildSectionTitle('Centres d\'intérêt'),
              _buildChipSection(
                items: _centresInteret,
                onAdd: _addCentreInteret,
                onRemove: (item) => setState(() => _centresInteret.remove(item)),
                color: Colors.orange,
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

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Titre de section
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Champ de texte
  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  /// Section avec chips éditables
  Widget _buildChipSection({
    required List<String> items,
    required VoidCallback onAdd,
    required Function(String) onRemove,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => Chip(
                      label: Text(item, style: const TextStyle(fontSize: 12)),
                      backgroundColor: color.withAlpha((255 * 0.1).toInt()),
                      labelStyle: TextStyle(color: color),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemove(item),
                    ),
                  )
                  .toList(),
            ),
          if (items.isEmpty)
            Text(
              'Aucun élément ajouté',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Ajouter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Ajouter un produit
  void _addProduit() {
    _showAddDialog(
      title: 'Ajouter un produit',
      hint: 'Ex: Logiciel de gestion',
      onAdd: (value) {
        setState(() => _produits.add(value));
      },
    );
  }

  /// Ajouter un service
  void _addService() {
    _showAddDialog(
      title: 'Ajouter un service',
      hint: 'Ex: Consulting IT',
      onAdd: (value) {
        setState(() => _services.add(value));
      },
    );
  }

  /// Ajouter un centre d'intérêt
  void _addCentreInteret() {
    _showAddDialog(
      title: 'Ajouter un centre d\'intérêt',
      hint: 'Ex: Technologie',
      onAdd: (value) {
        setState(() => _centresInteret.add(value));
      },
    );
  }

  /// Déconnexion du compte société
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

  /// Dialogue générique pour ajouter un élément
  void _showAddDialog({
    required String title,
    required String hint,
    required Function(String) onAdd,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  onAdd(controller.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              child: const Text("Ajouter",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _siteWebController.dispose();
    _nombreEmployesController.dispose();
    _anneeCreationController.dispose();
    _chiffreAffairesController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }
}
