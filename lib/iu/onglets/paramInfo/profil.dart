import 'package:flutter/material.dart';

class ProfilDetailPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ProfilDetailPage({super.key, required this.userProfile});

  @override
  State<ProfilDetailPage> createState() => _ProfilDetailPageState();
}

class _ProfilDetailPageState extends State<ProfilDetailPage> {
  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _numeroController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _formationController;

  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.userProfile['nom']);
    _prenomController =
        TextEditingController(text: widget.userProfile['prenom']);
    _emailController = TextEditingController(text: widget.userProfile['email']);
    _numeroController =
        TextEditingController(text: widget.userProfile['numero']);
    _bioController = TextEditingController(text: widget.userProfile['bio']);
    _experienceController =
        TextEditingController(text: widget.userProfile['experience']);
    _formationController =
        TextEditingController(text: widget.userProfile['formation']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: mattermostBlue,
        title: const Text("Mon Profil", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Photo de profil
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: mattermostBlue,
                    child: widget.userProfile['photo'] != null
                        ? ClipOval(
                            child: Image.network(widget.userProfile['photo']))
                        : Text(
                            "${widget.userProfile['prenom'][0]}${widget.userProfile['nom'][0]}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: mattermostGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Formulaire
            _buildTextField("Nom", _nomController),
            _buildTextField("Prénom", _prenomController),
            _buildTextField("Email", _emailController),
            _buildTextField("Numéro", _numeroController),
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
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (widget.userProfile['competences']
                            as List<String>)
                        .map((competence) => Chip(
                              label: Text(competence,
                                  style: const TextStyle(fontSize: 12)),
                              backgroundColor: mattermostBlue.withOpacity(0.1),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _removeCompetence(competence),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addCompetence,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Ajouter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mattermostBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
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
        ),
      ),
    );
  }

  void _changePhoto() {
    // Logique pour changer la photo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fonctionnalité de changement de photo")),
    );
  }

  void _addCompetence() {
    // Logique pour ajouter une compétence
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text("Ajouter une compétence"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Ex: Flutter"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    (widget.userProfile['competences'] as List<String>)
                        .add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  void _removeCompetence(String competence) {
    setState(() {
      (widget.userProfile['competences'] as List<String>).remove(competence);
    });
  }

  void _saveProfile() {
    // Logique pour sauvegarder le profil
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profil sauvegardé avec succès"),
        backgroundColor: mattermostGreen,
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
