import 'package:flutter/material.dart';

class SocieteDetailsPage extends StatefulWidget {
  final Map<String, dynamic> societe;
  final Map<String, dynamic> categorie;

  const SocieteDetailsPage({
    super.key,
    required this.societe,
    required this.categorie,
  });

  @override
  State<SocieteDetailsPage> createState() => _SocieteDetailsPageState();
}

class _SocieteDetailsPageState extends State<SocieteDetailsPage> {
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);

  // Données des transactions (inspirées de votre tableau)
  List<Map<String, dynamic>> transactions = [
    {
      'date': 'Janvier à Mars 2023',
      'quantite': '2038 Kg',
      'prixUnitaire': '1000 CFA',
      'prixTotal': '2,038,000 CFA',
    },
    {
      'date': 'Mars à Juin 2023',
      'quantite': '3248 Kg',
      'prixUnitaire': '1000 CFA',
      'prixTotal': '3,248,000 CFA',
    },
  ];

  // Informations du partenariat (inspirées de votre deuxième tableau)
  Map<String, dynamic> partenaireInfo = {
    'localite': 'Sorano (Champs) Uber',
    'maisonEtablissement': 'SORO, KTF',
    'superficie': 'De Agriculture',
    'hectares': '4 Hectares',
    'contact': 'Contrôleur de User',
    'siege': 'Siego do So-Decal Siège et contact',
    'certificatsEntreprise': 'Les Certificats entreprise',
    'secteurActivite': 'Secteur Activité',
    'numeroTelephone': '+226-08-07-80-14',
    'dateCreation': '2003 Depuis 2020',
    'telephone': '215-86280-47',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: widget.categorie['color'] ?? mattermostBlue,
        elevation: 0,
        title: Text(
          widget.societe['nom'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _showOptionsMenu,
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec informations de base
          _buildHeaderCard(),

          // Onglets et contenu
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: widget.categorie['color'] ?? mattermostBlue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor:
                          widget.categorie['color'] ?? mattermostBlue,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.receipt_long),
                          text: "Transactions",
                        ),
                        Tab(
                          icon: Icon(Icons.handshake),
                          text: "Partenariat",
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTransactionsList(),
                        _buildPartenariatInfo(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (widget.categorie['color'] ?? mattermostBlue)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.business,
              color: widget.categorie['color'] ?? mattermostBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.societe['nom'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mattermostDarkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.societe['type'] ?? 'Société',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.categorie['color'] ?? mattermostBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: mattermostGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Société Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: mattermostGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Titre avec résumé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Résumé des Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mattermostDarkBlue,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Total Quantité', '5,286 Kg', Icons.scale),
                  _buildSummaryItem(
                      'Transactions', '${transactions.length}', Icons.receipt),
                  _buildSummaryItem(
                      'Total Montant', '5,286,000 CFA', Icons.attach_money),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Historique des Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: mattermostDarkBlue,
          ),
        ),

        const SizedBox(height: 12),

        // Liste des transactions
        ...transactions
            .map((transaction) => _buildTransactionCard(transaction)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: widget.categorie['color'] ?? mattermostBlue,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.categorie['color'] ?? mattermostBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: mattermostDarkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (widget.categorie['color'] ?? mattermostBlue).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: widget.categorie['color'] ?? mattermostBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                transaction['date'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.categorie['color'] ?? mattermostBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child:
                    _buildTransactionField('Quantité', transaction['quantite']),
              ),
              Expanded(
                flex: 2,
                child: _buildTransactionField(
                    'Prix Unitaire', transaction['prixUnitaire']),
              ),
              Expanded(
                flex: 2,
                child: _buildTransactionField(
                    'Prix Total', transaction['prixTotal']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: mattermostDarkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: mattermostDarkBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildPartenariatInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Informations de contact
        _buildInfoSection(
          'Informations de Contact',
          Icons.contact_phone,
          [
            _buildInfoRow('Téléphone', partenaireInfo['numeroTelephone']),
            _buildInfoRow('Tél. Bureau', partenaireInfo['telephone']),
            _buildInfoRow('Localité', partenaireInfo['localite']),
            _buildInfoRow('Siège', partenaireInfo['siege']),
          ],
        ),

        const SizedBox(height: 20),

        // Informations d'activité
        _buildInfoSection(
          'Activité et Superficie',
          Icons.agriculture,
          [
            _buildInfoRow(
                'Maison/Établissement', partenaireInfo['maisonEtablissement']),
            _buildInfoRow('Superficie', partenaireInfo['superficie']),
            _buildInfoRow('Hectares', partenaireInfo['hectares']),
            _buildInfoRow(
                'Secteur d\'Activité', partenaireInfo['secteurActivite']),
          ],
        ),

        const SizedBox(height: 20),

        // Informations légales
        _buildInfoSection(
          'Informations Légales',
          Icons.business_center,
          [
            _buildInfoRow('Date de Création', partenaireInfo['dateCreation']),
            _buildInfoRow('Contrôleur', partenaireInfo['contact']),
            _buildInfoRow(
                'Certificats', partenaireInfo['certificatsEntreprise']),
          ],
        ),

        const SizedBox(height: 30),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _updatePartnership,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.categorie['color'] ?? mattermostBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Modifier Partenariat'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _suspendPartnership,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('Suspendre'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: widget.categorie['color'] ?? mattermostBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.categorie['color'] ?? mattermostBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontSize: 14,
                color: mattermostDarkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'Non renseigné',
              style: const TextStyle(
                fontSize: 14,
                color: mattermostDarkBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share,
                  color: widget.categorie['color'] ?? mattermostBlue),
              title: const Text('Partager les informations'),
              onTap: () {
                Navigator.pop(context);
                _shareInfo();
              },
            ),
            ListTile(
              leading: Icon(Icons.download,
                  color: widget.categorie['color'] ?? mattermostBlue),
              title: const Text('Exporter les données'),
              onTap: () {
                Navigator.pop(context);
                _exportData();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Résilier le partenariat'),
              onTap: () {
                Navigator.pop(context);
                _terminatePartnership();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updatePartnership() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modification du partenariat...'),
        backgroundColor: mattermostGreen,
      ),
    );
  }

  void _suspendPartnership() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre le partenariat'),
        content:
            const Text('Êtes-vous sûr de vouloir suspendre ce partenariat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Partenariat suspendu'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child:
                const Text('Suspendre', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _shareInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage des informations...'),
        backgroundColor: mattermostGreen,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export des données en cours...'),
        backgroundColor: mattermostGreen,
      ),
    );
  }

  void _terminatePartnership() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résilier le partenariat'),
        content: const Text(
            'Cette action est irréversible. Êtes-vous sûr de vouloir résilier ce partenariat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Retour à la page précédente
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Partenariat résilié'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Résilier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
