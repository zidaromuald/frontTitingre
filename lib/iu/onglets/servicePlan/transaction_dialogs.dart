import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/partenariat/transaction_partenariat_service.dart';
import 'package:gestauth_clean/services/partenariat/information_partenaire_service.dart';

/// Dialogues pour la gestion des transactions et informations partenaire
class TransactionDialogs {
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostRed = Color(0xFFDC3545);

  /// ========================================
  /// Dialogue de Création de Transaction (SOCIÉTÉ)
  /// ========================================
  static Future<CreateTransactionPartenaritDto?> showAddTransactionDialog(
    BuildContext context,
    int pagePartenaritId,
  ) async {
    final formKey = GlobalKey<FormState>();
    final produitController = TextEditingController();
    final quantiteController = TextEditingController();
    final prixUnitaireController = TextEditingController();
    final periodeLabelController = TextEditingController();
    final uniteController = TextEditingController();
    final categorieController = TextEditingController();

    DateTime? dateDebut;
    DateTime? dateFin;

    return showDialog<CreateTransactionPartenaritDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_shopping_cart, color: mattermostBlue),
            const SizedBox(width: 8),
            const Text('Créer une Transaction'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Produit (obligatoire)
                TextFormField(
                  controller: produitController,
                  decoration: const InputDecoration(
                    labelText: 'Produit/Service *',
                    hintText: 'Ex: Café arabica',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le produit est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantité (obligatoire)
                TextFormField(
                  controller: quantiteController,
                  decoration: const InputDecoration(
                    labelText: 'Quantité *',
                    hintText: 'Ex: 2038',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La quantité est obligatoire';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre entier valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Prix Unitaire (obligatoire)
                TextFormField(
                  controller: prixUnitaireController,
                  decoration: const InputDecoration(
                    labelText: 'Prix Unitaire *',
                    hintText: 'Ex: 1000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le prix unitaire est obligatoire';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Début (obligatoire)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: mattermostBlue),
                  title: Text(
                    dateDebut == null
                        ? 'Date de Début *'
                        : 'Début: ${dateDebut!.day}/${dateDebut!.month}/${dateDebut!.year}',
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      (context as Element).markNeedsBuild();
                      dateDebut = picked;
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Fin (obligatoire)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.event, color: mattermostBlue),
                  title: Text(
                    dateFin == null
                        ? 'Date de Fin *'
                        : 'Fin: ${dateFin!.day}/${dateFin!.month}/${dateFin!.year}',
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateDebut ?? DateTime.now(),
                      firstDate: dateDebut ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      (context as Element).markNeedsBuild();
                      dateFin = picked;
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                const SizedBox(height: 16),

                // Période Label (optionnel)
                TextFormField(
                  controller: periodeLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Libellé Période (optionnel)',
                    hintText: 'Ex: Janvier à Mars 2023',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),

                // Unité (optionnel)
                TextFormField(
                  controller: uniteController,
                  decoration: const InputDecoration(
                    labelText: 'Unité (optionnel)',
                    hintText: 'Ex: Kg, Litres, Tonnes',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 16),

                // Catégorie (optionnel)
                TextFormField(
                  controller: categorieController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie (optionnel)',
                    hintText: 'Ex: Agriculture, Commerce',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (dateDebut == null || dateFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner les dates de début et de fin'),
                      backgroundColor: mattermostRed,
                    ),
                  );
                  return;
                }

                final dto = CreateTransactionPartenaritDto(
                  pagePartenaritId: pagePartenaritId,
                  produit: produitController.text,
                  quantite: int.parse(quantiteController.text),
                  prixUnitaire: double.parse(prixUnitaireController.text),
                  dateDebut: dateDebut!.toIso8601String(),
                  dateFin: dateFin!.toIso8601String(),
                  periodeLabel: periodeLabelController.text.isEmpty
                      ? null
                      : periodeLabelController.text,
                  unite: uniteController.text.isEmpty ? null : uniteController.text,
                  categorie: categorieController.text.isEmpty
                      ? null
                      : categorieController.text,
                  statut: 'en_attente',
                );

                Navigator.pop(context, dto);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: mattermostGreen),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// Dialogue de Modification de Transaction (SOCIÉTÉ)
  /// ========================================
  static Future<UpdateTransactionPartenaritDto?> showEditTransactionDialog(
    BuildContext context,
    TransactionPartenaritModel transaction,
  ) async {
    final formKey = GlobalKey<FormState>();

    // Extraction des valeurs actuelles
    final produitController = TextEditingController(text: transaction.periode); // TODO: Récupérer le vrai produit
    final quantiteController = TextEditingController(
      text: transaction.quantite.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final prixUnitaireController = TextEditingController(
      text: transaction.prixUnitaire.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final periodeLabelController = TextEditingController(text: transaction.periode);
    final uniteController = TextEditingController(); // TODO: Récupérer l'unité
    final categorieController = TextEditingController(); // TODO: Récupérer la catégorie

    DateTime? dateDebut;
    DateTime? dateFin;

    return showDialog<UpdateTransactionPartenaritDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: mattermostBlue),
            const SizedBox(width: 8),
            const Text('Modifier la Transaction'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Produit
                TextFormField(
                  controller: produitController,
                  decoration: const InputDecoration(
                    labelText: 'Produit/Service',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                ),
                const SizedBox(height: 16),

                // Quantité
                TextFormField(
                  controller: quantiteController,
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (int.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre entier valide';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Prix Unitaire
                TextFormField(
                  controller: prixUnitaireController,
                  decoration: const InputDecoration(
                    labelText: 'Prix Unitaire',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (double.tryParse(value) == null) {
                        return 'Veuillez entrer un nombre valide';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Période Label
                TextFormField(
                  controller: periodeLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Libellé Période',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),

                // Unité
                TextFormField(
                  controller: uniteController,
                  decoration: const InputDecoration(
                    labelText: 'Unité',
                    hintText: 'Ex: Kg, Litres',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 16),

                // Catégorie
                TextFormField(
                  controller: categorieController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final dto = UpdateTransactionPartenaritDto(
                  produit: produitController.text.isEmpty ? null : produitController.text,
                  quantite: quantiteController.text.isEmpty
                      ? null
                      : int.parse(quantiteController.text),
                  prixUnitaire: prixUnitaireController.text.isEmpty
                      ? null
                      : double.parse(prixUnitaireController.text),
                  dateDebut: dateDebut?.toIso8601String(),
                  dateFin: dateFin?.toIso8601String(),
                  periodeLabel: periodeLabelController.text.isEmpty
                      ? null
                      : periodeLabelController.text,
                  unite: uniteController.text.isEmpty ? null : uniteController.text,
                  categorie: categorieController.text.isEmpty
                      ? null
                      : categorieController.text,
                );

                Navigator.pop(context, dto);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: mattermostBlue),
            child: const Text('Modifier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// Dialogue de Création d'Information (SOCIÉTÉ + USER)
  /// ========================================
  static Future<CreateInformationPartenaireDto?> showAddInformationDialog(
    BuildContext context,
    int pagePartenaritId,
    int currentUserId,
    String currentUserType,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nomAffichageController = TextEditingController();
    final secteurActiviteController = TextEditingController();
    final descriptionController = TextEditingController();
    final localiteController = TextEditingController();
    final adresseController = TextEditingController();
    final telephoneController = TextEditingController();
    final emailController = TextEditingController();

    // Champs Agriculture
    final superficieController = TextEditingController();
    final typeCultureController = TextEditingController();
    final maisonEtablissementController = TextEditingController();
    final contactControleurController = TextEditingController();

    // Champs Entreprise
    final siegeSocialController = TextEditingController();
    final numeroRegistrationController = TextEditingController();
    final capitalSocialController = TextEditingController();
    final chiffreAffairesController = TextEditingController();
    final nombreEmployesController = TextEditingController();

    return showDialog<CreateInformationPartenaireDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: mattermostBlue),
            const SizedBox(width: 8),
            const Text('Ajouter des Informations'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de Base
                const Text(
                  'Informations de Base',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: nomAffichageController,
                  decoration: const InputDecoration(
                    labelText: 'Nom à Afficher *',
                    hintText: 'Ex: Jean Dupont, Société ABC',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: secteurActiviteController,
                  decoration: const InputDecoration(
                    labelText: 'Secteur d\'Activité *',
                    hintText: 'Ex: Agriculture biologique',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le secteur d\'activité est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Décrivez votre activité',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Informations de Contact
                const Text(
                  'Contact',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: localiteController,
                  decoration: const InputDecoration(
                    labelText: 'Localité',
                    hintText: 'Ex: Bukavu, RDC',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse Complète',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de Téléphone',
                    hintText: 'Ex: +243 XXX XXX XXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'contact@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),

                // Informations Agriculture (Optionnel)
                const Text(
                  'Agriculture (si applicable)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: superficieController,
                  decoration: const InputDecoration(
                    labelText: 'Superficie',
                    hintText: 'Ex: 5 hectares',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.terrain),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: typeCultureController,
                  decoration: const InputDecoration(
                    labelText: 'Type de Culture',
                    hintText: 'Ex: Café arabica',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.eco),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: maisonEtablissementController,
                  decoration: const InputDecoration(
                    labelText: 'Maison/Établissement',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home_work),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: contactControleurController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Contrôleur',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.supervisor_account),
                  ),
                ),
                const SizedBox(height: 20),

                // Informations Entreprise (Optionnel)
                const Text(
                  'Entreprise (si applicable)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: siegeSocialController,
                  decoration: const InputDecoration(
                    labelText: 'Siège Social',
                    hintText: 'Ex: Kinshasa, RDC',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.corporate_fare),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: numeroRegistrationController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro d\'Enregistrement',
                    hintText: 'Ex: RC-123456',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: capitalSocialController,
                  decoration: const InputDecoration(
                    labelText: 'Capital Social',
                    hintText: 'Ex: 1000000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: chiffreAffairesController,
                  decoration: const InputDecoration(
                    labelText: 'Chiffre d\'Affaires',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: nombreEmployesController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre d\'Employés',
                    hintText: 'Ex: 50',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final dto = CreateInformationPartenaireDto(
                  pagePartenaritId: pagePartenaritId,
                  partenaireId: currentUserId,
                  partenaireType: currentUserType,
                  nomAffichage: nomAffichageController.text,
                  secteurActivite: secteurActiviteController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  localite: localiteController.text.isEmpty
                      ? null
                      : localiteController.text,
                  adresseComplete: adresseController.text.isEmpty
                      ? null
                      : adresseController.text,
                  numeroTelephone: telephoneController.text.isEmpty
                      ? null
                      : telephoneController.text,
                  emailContact: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  // Agriculture
                  superficie: superficieController.text.isEmpty
                      ? null
                      : superficieController.text,
                  typeCulture: typeCultureController.text.isEmpty
                      ? null
                      : typeCultureController.text,
                  maisonEtablissement: maisonEtablissementController.text.isEmpty
                      ? null
                      : maisonEtablissementController.text,
                  contactControleur: contactControleurController.text.isEmpty
                      ? null
                      : contactControleurController.text,
                  // Entreprise
                  siegeSocial: siegeSocialController.text.isEmpty
                      ? null
                      : siegeSocialController.text,
                  numeroRegistration: numeroRegistrationController.text.isEmpty
                      ? null
                      : numeroRegistrationController.text,
                  capitalSocial: capitalSocialController.text.isEmpty
                      ? null
                      : double.tryParse(capitalSocialController.text),
                  chiffreAffaires: chiffreAffairesController.text.isEmpty
                      ? null
                      : double.tryParse(chiffreAffairesController.text),
                  nombreEmployes: nombreEmployesController.text.isEmpty
                      ? null
                      : int.tryParse(nombreEmployesController.text),
                  visibleSurPage: true,
                );

                Navigator.pop(context, dto);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: mattermostGreen),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ========================================
  /// Dialogue de Modification d'Information (SOCIÉTÉ + USER)
  /// ========================================
  static Future<UpdateInformationPartenaireDto?> showEditInformationDialog(
    BuildContext context,
    InformationPartenaireModel info,
  ) async {
    final formKey = GlobalKey<FormState>();

    // Pré-remplir avec les valeurs actuelles
    final nomAffichageController = TextEditingController(text: info.titre);
    final descriptionController = TextEditingController(text: info.contenu ?? '');

    // Note: Les autres champs ne sont pas disponibles dans InformationPartenaireModel actuel
    // Vous devrez adapter selon votre modèle backend réel

    return showDialog<UpdateInformationPartenaireDto>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: mattermostBlue),
            const SizedBox(width: 8),
            const Text('Modifier l\'Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomAffichageController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final dto = UpdateInformationPartenaireDto(
                  nomAffichage: nomAffichageController.text.isEmpty
                      ? null
                      : nomAffichageController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                );

                Navigator.pop(context, dto);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: mattermostBlue),
            child: const Text('Modifier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
