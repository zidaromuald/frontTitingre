import 'package:flutter/material.dart';
import '../services/groupe/groupe_service.dart';

/// Page de création d'un nouveau groupe
/// Accessible depuis l'interface User ET Société
class CreateGroupePage extends StatefulWidget {
  const CreateGroupePage({super.key});

  @override
  State<CreateGroupePage> createState() => _CreateGroupePageState();
}

class _CreateGroupePageState extends State<CreateGroupePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();

  GroupeType _selectedType = GroupeType.prive;
  int _maxMembres = 50;
  bool _isCreating = false;

  // Couleurs
  static const Color primaryColor = Color(0xff5ac18e);
  static const Color darkGray = Color(0xFF8D8D8D);

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroupe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final groupe = await GroupeAuthService.createGroupe(
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        type: _selectedType,
        maxMembres: _maxMembres,
      );

      if (mounted) {
        // Retourner le groupe créé à la page précédente
        Navigator.pop(context, groupe);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Groupe "${groupe.nom}" créé avec succès !'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création : ${e.toString()}'),
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
        title: const Text(
          'Créer un canal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de groupe
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group, size: 64, color: primaryColor),
                ),
              ),
              const SizedBox(height: 32),

              // Nom du groupe
              const Text(
                'Nom du groupe *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  hintText: 'Ex: Producteurs de Riz BF',
                  prefixIcon: const Icon(Icons.label, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du groupe est requis';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Décrivez l\'objectif et les thèmes du groupe...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description, color: primaryColor),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Type de groupe
              const Text(
                'Type de groupe *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _selectedType = GroupeType.prive),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedType == GroupeType.prive
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: _selectedType == GroupeType.prive
                                  ? primaryColor
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.lock, color: primaryColor),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Privé',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Les membres doivent être invités',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    InkWell(
                      onTap: () =>
                          setState(() => _selectedType = GroupeType.public),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedType == GroupeType.public
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: _selectedType == GroupeType.public
                                  ? primaryColor
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.public, color: primaryColor),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Public',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'N\'importe qui peut rejoindre',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: darkGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nombre maximum de membres
              const Text(
                'Nombre maximum de membres',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_maxMembres membres',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          _getGroupeCategorie(_maxMembres),
                          style: const TextStyle(
                            fontSize: 12,
                            color: darkGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _maxMembres.toDouble(),
                      min: 10,
                      max: 10000,
                      divisions: 99,
                      activeColor: primaryColor,
                      label: '$_maxMembres',
                      onChanged: (value) {
                        setState(() => _maxMembres = value.toInt());
                      },
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '10',
                          style: TextStyle(fontSize: 12, color: darkGray),
                        ),
                        Text(
                          'Simple ≤ 100',
                          style: TextStyle(fontSize: 10, color: darkGray),
                        ),
                        Text(
                          'Professionnel ≤ 9999',
                          style: TextStyle(fontSize: 10, color: darkGray),
                        ),
                        Text(
                          '10 000+',
                          style: TextStyle(fontSize: 12, color: darkGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createGroupe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Créer le groupe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGroupeCategorie(int maxMembres) {
    if (maxMembres <= 100) {
      return 'Groupe Simple';
    } else if (maxMembres <= 9999) {
      return 'Groupe Professionnel';
    } else {
      return 'Super Groupe';
    }
  }
}
