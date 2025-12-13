import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/partenariat/transaction_partenariat_service.dart';
import 'package:gestauth_clean/services/partenariat/information_partenaire_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';
import 'package:gestauth_clean/iu/onglets/servicePlan/transaction_dialogs.dart';

/// Page de détails d'un partenariat avec gestion des transactions et informations
///
/// Permissions:
/// - SOCIÉTÉ: Peut créer, modifier, supprimer des transactions (si non validées)
///            Peut modifier ses informations partenaire
/// - USER:    Peut valider les transactions
///            Peut modifier ses informations partenaire
class PartenaireDetailsPage extends StatefulWidget {
  final int pagePartenaritId;       // ID de la page de partenariat
  final String partenaireName;      // Nom du partenaire affiché
  final Color? themeColor;          // Couleur du thème

  const PartenaireDetailsPage({
    super.key,
    required this.pagePartenaritId,
    required this.partenaireName,
    this.themeColor,
  });

  @override
  State<PartenaireDetailsPage> createState() => _PartenaireDetailsPageState();
}

class _PartenaireDetailsPageState extends State<PartenaireDetailsPage> {
  static const Color mattermostBlue = Color(0xFF1E4A8C);
  static const Color mattermostGreen = Color(0xFF28A745);
  static const Color mattermostOrange = Color(0xFFFFA500);
  static const Color mattermostRed = Color(0xFFDC3545);
  static const Color mattermostGray = Color(0xFFF4F4F4);
  static const Color mattermostDarkBlue = Color(0xFF0B2340);
  static const Color mattermostDarkGray = Color(0xFF8D8D8D);

  // Données chargées depuis le backend
  List<TransactionPartenaritModel> _transactions = [];
  List<InformationPartenaireModel> _informations = [];

  bool _isLoadingTransactions = true;
  bool _isLoadingInformations = true;
  String? _errorTransactions;
  String? _errorInformations;

  // Type d'utilisateur actuel (User ou Societe)
  String _userType = 'User'; // À récupérer depuis AuthBaseService
  int _currentUserId = 0;    // À récupérer depuis AuthBaseService

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadTransactions();
    _loadInformations();
  }

  /// Charger les informations de l'utilisateur connecté
  Future<void> _loadUserInfo() async {
    try {
      // Récupérer le type d'utilisateur depuis SharedPreferences
      final userType = await AuthBaseService.getUserType();
      final userData = await AuthBaseService.getUserData();

      if (userType != null && userData != null) {
        setState(() {
          // Le type est stocké en minuscules ('user' ou 'societe')
          // Mais on a besoin de 'User' ou 'Societe' pour correspondre au backend
          _userType = userType == 'user' ? 'User' : 'Societe';
          _currentUserId = userData['id'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des infos utilisateur: $e');
    }
  }

  /// Charger les transactions depuis le backend
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _errorTransactions = null;
    });

    try {
      final transactions = await TransactionPartenaritService.getTransactionsForPage(
        widget.pagePartenaritId,
      );

      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      setState(() {
        _errorTransactions = e.toString();
        _isLoadingTransactions = false;
      });
    }
  }

  /// Charger les informations partenaire depuis le backend
  Future<void> _loadInformations() async {
    setState(() {
      _isLoadingInformations = true;
      _errorInformations = null;
    });

    try {
      final informations = await InformationPartenaireService.getInformationsForPage(
        widget.pagePartenaritId,
      );

      setState(() {
        _informations = informations;
        _isLoadingInformations = false;
      });
    } catch (e) {
      setState(() {
        _errorInformations = e.toString();
        _isLoadingInformations = false;
      });
    }
  }

  /// Vérifier si l'utilisateur actuel est une Société
  bool get _isSociete => _userType == 'Societe';

  /// Vérifier si l'utilisateur actuel est un User
  bool get _isUser => _userType == 'User';

  Color get _themeColor => widget.themeColor ?? mattermostBlue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: mattermostGray,
      appBar: AppBar(
        backgroundColor: _themeColor,
        elevation: 0,
        title: Text(
          widget.partenaireName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSociete)
            IconButton(
              onPressed: _showAddTransactionDialog,
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Ajouter une transaction',
            ),
          IconButton(
            onPressed: _showOptionsMenu,
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderCard(),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      labelColor: _themeColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: _themeColor,
                      tabs: const [
                        Tab(icon: Icon(Icons.receipt_long), text: "Transactions"),
                        Tab(icon: Icon(Icons.handshake), text: "Informations"),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTransactionsList(),
                        _buildInformationsList(),
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
              color: _themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.handshake,
              color: _themeColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.partenaireName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mattermostDarkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSociete ? 'Vous êtes Société' : 'Vous êtes User',
                  style: TextStyle(
                    fontSize: 14,
                    color: _themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: mattermostGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_transactions.length} transaction(s)',
                    style: const TextStyle(
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
    if (_isLoadingTransactions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorTransactions != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: mattermostRed),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorTransactions!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: mattermostDarkGray),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: mattermostDarkGray),
            const SizedBox(height: 16),
            const Text(
              'Aucune transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les transactions apparaîtront ici',
              style: TextStyle(color: mattermostDarkGray),
            ),
            if (_isSociete) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddTransactionDialog,
                icon: const Icon(Icons.add),
                label: const Text('Créer une transaction'),
                style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTransactionsSummary(),
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
          ..._transactions.map((transaction) => _buildTransactionCard(transaction)),
        ],
      ),
    );
  }

  Widget _buildTransactionsSummary() {
    final validees = _transactions.where((t) => t.isValidee()).length;
    final enAttente = _transactions.where((t) => t.isEnAttente()).length;

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
          const Text(
            'Résumé des Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: mattermostDarkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', '${_transactions.length}', Icons.receipt, _themeColor),
              _buildSummaryItem('Validées', '$validees', Icons.check_circle, mattermostGreen),
              _buildSummaryItem('En attente', '$enAttente', Icons.hourglass_empty, mattermostOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildTransactionCard(TransactionPartenaritModel transaction) {
    final statusColor = Color(transaction.getStatusColor());
    final canEdit = _isSociete && transaction.isEnAttente();
    final canValidate = _isUser && transaction.isEnAttente();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
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
          // En-tête avec période et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: _themeColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.periodeFormatee,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  transaction.getStatusLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Détails de la transaction
          Row(
            children: [
              Expanded(
                child: _buildTransactionField('Quantité', transaction.quantiteFormatee),
              ),
              Expanded(
                child: _buildTransactionField('Prix Unitaire', transaction.prixUnitaireFormate),
              ),
              Expanded(
                child: _buildTransactionField('Prix Total', transaction.prixTotalFormate),
              ),
            ],
          ),

          // Informations additionnelles
          if (transaction.userNom != null || transaction.societeNom != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                if (transaction.societeNom != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.business,
                      'Société',
                      transaction.societeNom!,
                      mattermostBlue,
                    ),
                  ),
                if (transaction.userNom != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.person,
                      'User',
                      transaction.getUserName(),
                      mattermostGreen,
                    ),
                  ),
              ],
            ),
          ],

          // Commentaire si présent
          if (transaction.commentaire != null && transaction.commentaire!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: mattermostGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment, size: 16, color: mattermostDarkGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction.commentaire!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: mattermostDarkGray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Boutons d'action
          if (canEdit || canValidate) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (canEdit) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditTransactionDialog(transaction),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _themeColor,
                        side: BorderSide(color: _themeColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteTransaction(transaction),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mattermostRed,
                        side: const BorderSide(color: mattermostRed),
                      ),
                    ),
                  ),
                ],
                if (canValidate) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _validateTransaction(transaction, true),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mattermostGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _validateTransaction(transaction, false),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mattermostRed,
                        side: const BorderSide(color: mattermostRed),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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

  Widget _buildInfoChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsList() {
    if (_isLoadingInformations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorInformations != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: mattermostRed),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorInformations!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: mattermostDarkGray),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInformations,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            ),
          ],
        ),
      );
    }

    if (_informations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: mattermostDarkGray),
            const SizedBox(height: 16),
            const Text(
              'Aucune information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les informations partenaire apparaîtront ici',
              style: TextStyle(color: mattermostDarkGray),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddInformationDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter des informations'),
              style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInformations,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _informations.map((info) => _buildInformationCard(info)).toList(),
      ),
    );
  }

  Widget _buildInformationCard(InformationPartenaireModel info) {
    final canEdit = info.isCreatedByMe(_currentUserId, _userType);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Icon(Icons.info, color: _themeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.titre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _themeColor,
                  ),
                ),
              ),
              if (canEdit)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditInformationDialog(info);
                    } else if (value == 'delete') {
                      _deleteInformation(info);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: mattermostRed),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: mattermostRed)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (info.contenu != null && info.contenu!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              info.contenu!,
              style: const TextStyle(
                fontSize: 14,
                color: mattermostDarkGray,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                info.createdByType == 'Societe' ? Icons.business : Icons.person,
                size: 14,
                color: mattermostDarkGray,
              ),
              const SizedBox(width: 4),
              Text(
                'Par ${info.getCreatorName()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: mattermostDarkGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // Actions CRUD - Transactions
  // ========================================

  Future<void> _showAddTransactionDialog() async {
    if (!_isSociete) {
      _showErrorSnackBar('Seule la Société peut créer des transactions');
      return;
    }

    final dto = await TransactionDialogs.showAddTransactionDialog(
      context,
      widget.pagePartenaritId,
    );

    if (dto != null) {
      try {
        await TransactionPartenaritService.createTransaction(dto);
        _showSuccessSnackBar('Transaction créée avec succès');
        _loadTransactions();
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _showEditTransactionDialog(TransactionPartenaritModel transaction) async {
    if (!_isSociete) {
      _showErrorSnackBar('Seule la Société peut modifier des transactions');
      return;
    }

    if (!transaction.isEnAttente()) {
      _showErrorSnackBar('Impossible de modifier une transaction validée ou rejetée');
      return;
    }

    final dto = await TransactionDialogs.showEditTransactionDialog(
      context,
      transaction,
    );

    if (dto != null) {
      try {
        await TransactionPartenaritService.updateTransaction(transaction.id, dto);
        _showSuccessSnackBar('Transaction modifiée avec succès');
        _loadTransactions();
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _deleteTransaction(TransactionPartenaritModel transaction) async {
    if (!_isSociete) {
      _showErrorSnackBar('Seule la Société peut supprimer des transactions');
      return;
    }

    if (!transaction.isEnAttente()) {
      _showErrorSnackBar('Impossible de supprimer une transaction validée ou rejetée');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la transaction'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette transaction ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: mattermostRed),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TransactionPartenaritService.deleteTransaction(transaction.id);
        _showSuccessSnackBar('Transaction supprimée avec succès');
        _loadTransactions();
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _validateTransaction(TransactionPartenaritModel transaction, bool approve) async {
    if (!_isUser) {
      _showErrorSnackBar('Seul un User peut valider des transactions');
      return;
    }

    String? commentaire;
    if (!approve) {
      commentaire = await _showRejectDialog();
      if (commentaire == null) return; // Annulé
    }

    try {
      final dto = ValidateTransactionDto(commentaire: commentaire);
      await TransactionPartenaritService.validateTransaction(transaction.id, dto);

      _showSuccessSnackBar(
        approve ? 'Transaction validée avec succès' : 'Transaction rejetée',
      );
      _loadTransactions();
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<String?> _showRejectDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter la transaction'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet (optionnel)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: mattermostRed),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Actions CRUD - Informations
  // ========================================

  Future<void> _showAddInformationDialog() async {
    final dto = await TransactionDialogs.showAddInformationDialog(
      context,
      widget.pagePartenaritId,
      _currentUserId,
      _userType,
    );

    if (dto != null) {
      try {
        await InformationPartenaireService.createInformation(dto);
        _showSuccessSnackBar('Information créée avec succès');
        _loadInformations();
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _showEditInformationDialog(InformationPartenaireModel info) async {
    final dto = await TransactionDialogs.showEditInformationDialog(
      context,
      info,
    );

    if (dto != null) {
      try {
        await InformationPartenaireService.updateInformation(info.id, dto);
        _showSuccessSnackBar('Information modifiée avec succès');
        _loadInformations();
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  Future<void> _deleteInformation(InformationPartenaireModel info) async {
    if (!info.isCreatedByMe(_currentUserId, _userType)) {
      _showErrorSnackBar('Vous ne pouvez supprimer que vos propres informations');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'information'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette information ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: mattermostRed),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await InformationPartenaireService.deleteInformation(info.id);
        _showSuccessSnackBar('Information supprimée avec succès');
        _loadInformations();
      } catch (e) {
        _showErrorSnackBar('Erreur: $e');
      }
    }
  }

  // ========================================
  // Menu d'options
  // ========================================

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
              leading: Icon(Icons.refresh, color: _themeColor),
              title: const Text('Actualiser les données'),
              onTap: () {
                Navigator.pop(context);
                _loadTransactions();
                _loadInformations();
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: _themeColor),
              title: const Text('Partager les informations'),
              onTap: () {
                Navigator.pop(context);
                _showErrorSnackBar('Fonctionnalité en cours de développement');
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: _themeColor),
              title: const Text('Exporter les données'),
              onTap: () {
                Navigator.pop(context);
                _showErrorSnackBar('Fonctionnalité en cours de développement');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Helpers
  // ========================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: mattermostGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: mattermostRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
