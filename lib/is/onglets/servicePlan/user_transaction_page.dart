import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/AuthUS/user_auth_service.dart';
import 'package:gestauth_clean/services/AuthUS/societe_auth_service.dart';
import 'package:gestauth_clean/services/partenariat/transaction_partenariat_service.dart';
import 'package:gestauth_clean/services/partenariat/information_partenaire_service.dart';
import 'package:gestauth_clean/services/partenariat/page_partenariat_service.dart';
import 'package:gestauth_clean/services/messagerie/conversation_service.dart';
import 'package:gestauth_clean/messagerie/conversation_detail_page.dart';

/// Page de gestion des transactions pour l'interface Société
/// Permet à la société de créer/modifier des transactions avec un utilisateur abonné
class UserTransactionPage extends StatefulWidget {
  final int userId;
  final String userName;
  final Color themeColor;

  const UserTransactionPage({
    super.key,
    required this.userId,
    required this.userName,
    this.themeColor = const Color(0xFF1E4A8C),
  });

  @override
  State<UserTransactionPage> createState() => _UserTransactionPageState();
}

class _UserTransactionPageState extends State<UserTransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  UserModel? _user;
  int? _pagePartenaritId; // ID de la page partenariat
  List<TransactionPartenaritModel> _transactions = [];
  List<InformationPartenaireModel> _informations = [];

  bool _isLoadingUser = true;
  bool _isLoadingPageId = true;
  bool _isLoadingTransactions = true;
  bool _isLoadingInformations = true;

  // Couleurs
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserProfile(),
      _loadPagePartenaritId(),
      _loadTransactions(),
      _loadInformations(),
    ]);
  }

  Future<void> _loadPagePartenaritId() async {
    setState(() => _isLoadingPageId = true);

    try {
      // Récupérer l'ID de la société connectée
      final societe = await SocieteAuthService.getMe();

      // Récupérer la page partenariat entre la société et l'utilisateur
      final page = await PagePartenaritService.getPageByUserAndSociete(
        userId: widget.userId,
        societeId: societe.id,
      );

      if (mounted) {
        setState(() {
          _pagePartenaritId = page.id;
          _isLoadingPageId = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPageId = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de la page partenariat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingUser = true);

    try {
      final user = await UserAuthService.getUserProfile(widget.userId);

      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement du profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);

    try {
      // TODO: Récupérer le vrai ID de page partenariat depuis le backend
      // Pour l'instant, on utilise l'ID de l'utilisateur
      final transactions = await TransactionPartenaritService.getTransactionsForPage(widget.userId);

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
        debugPrint('Erreur chargement transactions: $e');
      }
    }
  }

  Future<void> _loadInformations() async {
    setState(() => _isLoadingInformations = true);

    try {
      // TODO: Récupérer le vrai ID de page partenariat depuis le backend
      final informations = await InformationPartenaireService.getInformationsForPage(widget.userId);

      if (mounted) {
        setState(() {
          _informations = informations;
          _isLoadingInformations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingInformations = false);
        debugPrint('Erreur chargement informations: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        elevation: 0,
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: "Transactions"),
            Tab(icon: Icon(Icons.info_outline), text: "Informations"),
            Tab(icon: Icon(Icons.message_outlined), text: "Messages"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildInformationsTab(),
          _buildMessagesTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _createTransaction(),
              backgroundColor: widget.themeColor,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle transaction'),
            )
          : null,
    );
  }

  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Aucune transaction'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createTransaction(),
              icon: const Icon(Icons.add),
              label: const Text('Créer une transaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(_transactions[index]);
      },
    );
  }

  Widget _buildTransactionCard(TransactionPartenaritModel transaction) {
    final Color statusColor = transaction.statut == 'validee'
        ? mattermostGreen
        : transaction.statut == 'rejetee'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  transaction.produit,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  transaction.statut.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Détails
          _buildTransactionDetail('Période', transaction.periodeLabel ??
              '${_formatDate(transaction.dateDebut)} - ${_formatDate(transaction.dateFin)}'),
          _buildTransactionDetail('Quantité', '${transaction.quantite} ${transaction.unite ?? ''}'),
          _buildTransactionDetail('Prix unitaire', '${transaction.prixUnitaire} CFA'),
          _buildTransactionDetail('Prix total', '${transaction.quantite * transaction.prixUnitaire} CFA',
              bold: true),

          // Actions pour transactions en attente
          if (transaction.statut == 'en_attente') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _deleteTransaction(transaction),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _editTransaction(transaction),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionDetail(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: mattermostDarkGray, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsTab() {
    if (_isLoadingInformations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_informations.isEmpty) {
      return const Center(
        child: Text('Aucune information partenaire'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _informations.length,
      itemBuilder: (context, index) {
        final info = _informations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.titre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (info.contenu != null) ...[
                const SizedBox(height: 8),
                Text(info.contenu!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.message_outlined, size: 80, color: Color(0xFF1E4A8C)),
          const SizedBox(height: 24),
          const Text(
            'Messagerie Partenariat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _startConversation(),
            icon: const Icon(Icons.send),
            label: const Text('Envoyer un message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startConversation() async {
    try {
      final conversation = await ConversationService.createOrGetConversation(
        CreateConversationDto(
          participantId: widget.userId,
          participantType: 'User',
        ),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationDetailPage(
              conversationId: conversation.id,
              participantName: widget.userName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTransaction() async {
    // Vérifier que le pagePartenaritId est chargé
    if (_pagePartenaritId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chargement de la page partenariat en cours...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<TransactionPartenaritModel>(
      context: context,
      builder: (context) => TransactionFormDialog(
        userId: widget.userId,
        userName: widget.userName,
        pagePartenaritId: _pagePartenaritId!,
      ),
    );

    if (result != null) {
      setState(() {
        _transactions.insert(0, result);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction créée avec succès'),
            backgroundColor: mattermostGreen,
          ),
        );
      }
    }
  }

  Future<void> _editTransaction(TransactionPartenaritModel transaction) async {
    final result = await showDialog<TransactionPartenaritModel>(
      context: context,
      builder: (context) => TransactionFormDialog(
        userId: widget.userId,
        userName: widget.userName,
        transaction: transaction,
      ),
    );

    if (result != null) {
      setState(() {
        final index = _transactions.indexWhere((t) => t.id == result.id);
        if (index != -1) {
          _transactions[index] = result;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction modifiée avec succès'),
            backgroundColor: mattermostGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(TransactionPartenaritModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la transaction'),
        content: Text('Voulez-vous vraiment supprimer la transaction "${transaction.produit}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TransactionPartenaritService.deleteTransaction(transaction.id);

        setState(() {
          _transactions.remove(transaction);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction supprimée'),
              backgroundColor: mattermostGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Dialog pour créer ou modifier une transaction
class TransactionFormDialog extends StatefulWidget {
  final int userId;
  final String userName;
  final int? pagePartenaritId; // ID de la page partenariat (requis pour création)
  final TransactionPartenaritModel? transaction; // null = création, non-null = modification

  const TransactionFormDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.pagePartenaritId,
    this.transaction,
  });

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _produitController;
  late TextEditingController _quantiteController;
  late TextEditingController _prixUnitaireController;
  late TextEditingController _uniteController;
  late TextEditingController _categorieController;
  late TextEditingController _periodeLabelController;

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isSubmitting = false;

  static const Color primaryColor = Color(0xFF1E4A8C);

  @override
  void initState() {
    super.initState();

    // Initialiser avec les valeurs existantes si modification
    _produitController = TextEditingController(text: widget.transaction?.produit ?? '');
    _quantiteController = TextEditingController(text: widget.transaction?.quantite.toString() ?? '');
    _prixUnitaireController = TextEditingController(text: widget.transaction?.prixUnitaire.toString() ?? '');
    _uniteController = TextEditingController(text: widget.transaction?.unite ?? '');
    _categorieController = TextEditingController(text: widget.transaction?.categorie ?? '');
    _periodeLabelController = TextEditingController(text: widget.transaction?.periodeLabel ?? '');

    _dateDebut = widget.transaction?.dateDebut ?? DateTime.now();
    _dateFin = widget.transaction?.dateFin ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _produitController.dispose();
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
    _uniteController.dispose();
    _categorieController.dispose();
    _periodeLabelController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _dateDebut! : _dateFin!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateDebut == null || _dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner les dates de début et de fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_dateFin!.isBefore(_dateDebut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de fin doit être après la date de début'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      TransactionPartenaritModel result;

      if (widget.transaction == null) {
        // Création
        if (widget.pagePartenaritId == null) {
          throw Exception('ID de page partenariat manquant');
        }

        final dto = CreateTransactionPartenaritDto(
          pagePartenaritId: widget.pagePartenaritId!,
          produit: _produitController.text.trim(),
          quantite: int.parse(_quantiteController.text.trim()),
          prixUnitaire: double.parse(_prixUnitaireController.text.trim()),
          dateDebut: _dateDebut!.toIso8601String(),
          dateFin: _dateFin!.toIso8601String(),
          periodeLabel: _periodeLabelController.text.trim().isNotEmpty
              ? _periodeLabelController.text.trim()
              : null,
          unite: _uniteController.text.trim().isNotEmpty
              ? _uniteController.text.trim()
              : null,
          categorie: _categorieController.text.trim().isNotEmpty
              ? _categorieController.text.trim()
              : null,
        );

        result = await TransactionPartenaritService.createTransaction(dto);
      } else {
        // Modification
        final dto = UpdateTransactionPartenaritDto(
          produit: _produitController.text.trim(),
          quantite: int.parse(_quantiteController.text.trim()),
          prixUnitaire: double.parse(_prixUnitaireController.text.trim()),
          dateDebut: _dateDebut!.toIso8601String(),
          dateFin: _dateFin!.toIso8601String(),
          periodeLabel: _periodeLabelController.text.trim().isNotEmpty
              ? _periodeLabelController.text.trim()
              : null,
          unite: _uniteController.text.trim().isNotEmpty
              ? _uniteController.text.trim()
              : null,
          categorie: _categorieController.text.trim().isNotEmpty
              ? _categorieController.text.trim()
              : null,
        );

        result = await TransactionPartenaritService.updateTransaction(
          widget.transaction!.id,
          dto,
        );
      }

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Modifier la transaction' : 'Nouvelle transaction',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Formulaire
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Produit
                      const Text(
                        'Produit / Service *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _produitController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Riz Basmati',
                          prefixIcon: const Icon(Icons.shopping_bag, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le produit est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quantité et Unité
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quantité *',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _quantiteController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '1000',
                                    prefixIcon: const Icon(Icons.numbers, color: primaryColor),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Requis';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Nombre invalide';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unité',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _uniteController,
                                  decoration: InputDecoration(
                                    hintText: 'Kg',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Prix unitaire
                      const Text(
                        'Prix unitaire (CFA) *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _prixUnitaireController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '500',
                          prefixIcon: const Icon(Icons.attach_money, color: primaryColor),
                          suffixText: 'CFA',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le prix est requis';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Prix invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Catégorie
                      const Text(
                        'Catégorie',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _categorieController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Céréales',
                          prefixIcon: const Icon(Icons.category, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      const Text(
                        'Période *',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, true),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.calendar_today, color: primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  _dateDebut != null
                                      ? '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year}'
                                      : 'Date début',
                                  style: TextStyle(
                                    color: _dateDebut != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context, false),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.calendar_today, color: primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  _dateFin != null
                                      ? '${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
                                      : 'Date fin',
                                  style: TextStyle(
                                    color: _dateFin != null ? Colors.black : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Label de période
                      const Text(
                        'Label de période',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _periodeLabelController,
                        decoration: InputDecoration(
                          hintText: 'Ex: Janvier à Mars 2024',
                          prefixIcon: const Icon(Icons.label, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Boutons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(isEditing ? 'Modifier' : 'Créer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
