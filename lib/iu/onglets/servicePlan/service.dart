import 'package:flutter/material.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/transaction.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  String selectedTab = "suivie"; // suivie, canaux, societe

  // Couleurs Mattermost
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);
  static const Color mattermostGreen = Color(0xFF28A745);

  // Données simulées - remplacez par vos vraies données
  final List<Map<String, dynamic>> collaborateurs = [
    {
      'nom': 'Jean Dupont',
      'poste': 'Développeur Flutter',
      'avatar': 'JD',
      'statut': 'en ligne',
      'dernierMessage': 'Salut ! Comment ça va ?',
      'heureMessage': '14:32',
    },
    {
      'nom': 'Marie Martin',
      'poste': 'Designer UI/UX',
      'avatar': 'MM',
      'statut': 'absent',
      'dernierMessage': 'Je travaille sur le nouveau design',
      'heureMessage': '13:15',
    },
    {
      'nom': 'Pierre Durand',
      'poste': 'Chef de projet',
      'avatar': 'PD',
      'statut': 'en ligne',
      'dernierMessage': 'Réunion à 16h',
      'heureMessage': '12:45',
    },
    {
      'nom': 'Sophie Leroy',
      'poste': 'Développeuse Backend',
      'avatar': 'SL',
      'statut': 'occupé',
      'dernierMessage': 'API prête pour les tests',
      'heureMessage': '11:20',
    },
  ];

  final List<Map<String, dynamic>> canaux = [
    {
      'nom': 'Équipe Développement',
      'description': 'Discussions techniques',
      'membres': 12,
      'dernierMessage': 'Nouveau framework disponible',
      'heureMessage': '15:20',
      'nonLus': 3,
    },
    {
      'nom': 'Design & UI',
      'description': 'Créativité et design',
      'membres': 8,
      'dernierMessage': 'Prototype validé !',
      'heureMessage': '14:45',
      'nonLus': 0,
    },
    {
      'nom': 'Général',
      'description': 'Discussions générales',
      'membres': 25,
      'dernierMessage': 'Pause café à 15h30',
      'heureMessage': '13:30',
      'nonLus': 1,
    },
  ];

  final List<Map<String, dynamic>> societes = [
    {
      'nom': 'TechCorp Solutions',
      'type': 'Client',
      'projets': 3,
      'statut': 'actif',
      'dernierMessage': 'Validation du livrable',
      'heureMessage': '16:10',
    },
    {
      'nom': 'Innovation Lab',
      'type': 'Partenaire',
      'projets': 1,
      'statut': 'actif',
      'dernierMessage': 'Nouvelle collaboration',
      'heureMessage': '10:30',
    },
    {
      'nom': 'StartupHub',
      'type': 'Incubateur',
      'projets': 2,
      'statut': 'en attente',
      'dernierMessage': 'Présentation demain',
      'heureMessage': 'hier',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: mattermostBlue,
        elevation: 0,
        title: const Text(
          "Services",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              // Action de recherche
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Boutons de services en haut (petits, arrondis)
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   color: Colors.white,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //     children: [
          //       _buildServiceButton("Vocal", Icons.mic, () {
          //         _showServiceDialog("Vocal");
          //       }),
          //       _buildServiceButton("Texte", Icons.edit_note, () {
          //         _showServiceDialog("Texte");
          //       }),
          //       _buildServiceButton("Image", Icons.image, () {
          //         _showServiceDialog("Image");
          //       }),
          //       _buildServiceButton("Galerie", Icons.photo_library, () {
          //         _showServiceDialog("Galerie");
          //       }),
          //     ],
          //   ),
          // ),

          // Sélecteur d'onglets (Suivie, Canaux, Société)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTabOption("Suivie", "suivie", Icons.people),
                const SizedBox(width: 8),
                _buildTabOption("Canaux", "canaux", Icons.tag),
                const SizedBox(width: 8),
                _buildTabOption("Société", "societe", Icons.business),
              ],
            ),
          ),

          // Contenu selon l'onglet sélectionné
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildTabContent(),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Widget pour les petits boutons de service
  // Widget _buildServiceButton(String label, IconData icon, VoidCallback onTap) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       decoration: BoxDecoration(
  //         color: mattermostBlue,
  //         borderRadius: BorderRadius.circular(20), // Petit et arrondi
  //         boxShadow: [
  //           BoxShadow(
  //             color: mattermostBlue.withOpacity(0.3),
  //             blurRadius: 4,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             icon,
  //             color: Colors.white,
  //             size: 16,
  //           ),
  //           const SizedBox(width: 6),
  //           Text(
  //             label,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget pour les onglets (Suivie, Canaux, Société)
  Widget _buildTabOption(String label, String value, IconData icon) {
    final isSelected = selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? mattermostBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : mattermostDarkBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : mattermostDarkBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Contenu selon l'onglet sélectionné
  Widget _buildTabContent() {
    switch (selectedTab) {
      case "suivie":
        return _buildCollaborateursList();
      case "canaux":
        return _buildCanauxList();
      case "societe":
        return _buildSocietesList();
      default:
        return const Center(child: Text("Contenu non disponible"));
    }
  }

  // Liste des collaborateurs (onglet Suivie)
  Widget _buildCollaborateursList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Collaborateurs suivis (${collaborateurs.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostDarkBlue,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: collaborateurs.length,
            itemBuilder: (context, index) {
              final collab = collaborateurs[index];
              return _buildCollaborateurItem(collab);
            },
          ),
        ),
      ],
    );
  }

  // Item collaborateur
  Widget _buildCollaborateurItem(Map<String, dynamic> collab) {
    Color statutColor;
    switch (collab['statut']) {
      case 'en ligne':
        statutColor = mattermostGreen;
        break;
      case 'occupé':
        statutColor = Colors.orange;
        break;
      default:
        statutColor = mattermostDarkGray;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: mattermostBlue,
              radius: 24,
              child: Text(
                collab['avatar'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statutColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          collab['nom'],
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              collab['poste'],
              style: TextStyle(color: mattermostDarkGray, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              collab['dernierMessage'],
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          collab['heureMessage'],
          style: TextStyle(color: mattermostDarkGray, fontSize: 11),
        ),
        onTap: () {
          _showCollaborateurDetails(collab);
        },
      ),
    );
  }

  // Liste des canaux
  Widget _buildCanauxList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Canaux (${canaux.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostDarkBlue,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: canaux.length,
            itemBuilder: (context, index) {
              final canal = canaux[index];
              return _buildCanalItem(canal);
            },
          ),
        ),
      ],
    );
  }

  // Item canal
  Widget _buildCanalItem(Map<String, dynamic> canal) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mattermostBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.tag, color: mattermostBlue, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                canal['nom'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (canal['nonLus'] > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  canal['nonLus'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${canal['membres']} membres • ${canal['description']}",
              style: TextStyle(color: mattermostDarkGray, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              canal['dernierMessage'],
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          canal['heureMessage'],
          style: TextStyle(color: mattermostDarkGray, fontSize: 11),
        ),
        onTap: () {
          _showCanalDetails(canal);
        },
      ),
    );
  }

  // Liste des sociétés
  Widget _buildSocietesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Sociétés (${societes.length})",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: mattermostDarkBlue,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: societes.length,
            itemBuilder: (context, index) {
              final societe = societes[index];
              return _buildSocieteItem(societe);
            },
          ),
        ),
      ],
    );
  }

  // Item société
  Widget _buildSocieteItem(Map<String, dynamic> societe) {
    Color statutColor;
    switch (societe['statut']) {
      case 'actif':
        statutColor = mattermostGreen;
        break;
      case 'en attente':
        statutColor = Colors.orange;
        break;
      default:
        statutColor = mattermostDarkGray;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mattermostBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.business, color: Colors.white, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                societe['nom'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statutColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                societe['statut'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${societe['type']} • ${societe['projets']} projet(s)",
              style: TextStyle(color: mattermostDarkGray, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              societe['dernierMessage'],
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Text(
          societe['heureMessage'],
          style: const TextStyle(color: mattermostDarkGray, fontSize: 11),
        ),
        onTap: () {
          _showSocieteDetails(societe);
        },
      ),
    );
  }

  // Dialog pour les services
  // void _showServiceDialog(String service) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Service $service"),
  //         content: Text("Vous avez sélectionné le service $service"),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: const Text("Fermer"),
  //           ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               // Logique pour utiliser le service
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: mattermostBlue,
  //             ),
  //             child:
  //                 const Text("Utiliser", style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Détails collaborateur
  void _showCollaborateurDetails(Map<String, dynamic> collab) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: mattermostBlue,
                radius: 30,
                child: Text(
                  collab['avatar'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                collab['nom'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                collab['poste'],
                style: TextStyle(color: mattermostDarkGray, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text("Message"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mattermostBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text("Appeler"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mattermostGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Détails canal
  void _showCanalDetails(Map<String, dynamic> canal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: mattermostBlue,
            title: Text(
              canal['nom'],
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(child: Text("Contenu du canal ${canal['nom']}")),
        ),
      ),
    );
  }

  // Dans votre CategoriePage, modifiez la fonction _showSocieteDetails
  void _showSocieteDetails(Map<String, dynamic> societe) {
    // Catégorie par défaut si pas disponible
    Map<String, dynamic> defaultCategorie = {
      'nom': 'Service',
      'color': const Color(0xFF1E4A8C), // mattermostBlue
      'icon': Icons.business,
      'description': 'Services généraux',
    };

    if (societe['statut'] == 'actif') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SocieteDetailsPage(
            societe: societe,
            categorie: defaultCategorie, // Catégorie par défaut
          ),
        ),
      );
    } else {
      // Pour les sociétés non actives, afficher la modal simple
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                societe['nom'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                societe['description'],
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Text(
                'Cette société n\'est pas encore active. Vous pouvez envoyer une demande de partenariat.',
                style: TextStyle(fontSize: 14, color: Colors.orange[700]),
              ),
            ],
          ),
        ),
      );
    }
  }
}
