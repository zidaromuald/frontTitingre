import 'package:flutter/material.dart';
import 'package:gestauth_clean/services/partenariat/transaction_partenariat_service.dart';
import 'package:gestauth_clean/services/AuthUS/auth_base_service.dart';

/// ========================================
/// EXEMPLE 1: Société crée une transaction
/// ========================================

Future<void> exempleCreerTransaction() async {
  try {
    final dto = CreateTransactionPartenaritDto(
      pageId: 1,
      userId: 5, // ID du producteur
      periode: 'Janvier à Mars 2023',
      quantite: '2038 Kg',
      prixUnitaire: '1000 CFA',
      prixTotal: '2,038,000 CFA',
      commentaire: 'Achat de cacao première récolte',
    );

    final transaction = await TransactionPartenaritService.createTransaction(dto);

    print('✅ Transaction créée:');
    print('   ID: ${transaction.id}');
    print('   Période: ${transaction.periode}');
    print('   Montant: ${transaction.prixTotal}');
    print('   Statut: ${transaction.getStatusLabel()}');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// ========================================
/// EXEMPLE 2: User consulte transactions en attente
/// ========================================

Future<void> exempleConsulterTransactionsEnAttente() async {
  try {
    // Compter les transactions en attente
    final count = await TransactionPartenaritService.countPendingTransactions();
    print('🔔 $count transaction(s) en attente');

    // Récupérer les transactions en attente
    final transactions = await TransactionPartenaritService.getPendingTransactions();

    print('\n📋 Transactions en attente:');
    for (var transaction in transactions) {
      print('   • Transaction #${transaction.id}');
      print('     Société: ${transaction.societeNom}');
      print('     Période: ${transaction.periode}');
      print('     Montant: ${transaction.prixTotal}');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// ========================================
/// EXEMPLE 3: User valide une transaction
/// ========================================

Future<void> exempleValiderTransaction(int transactionId) async {
  try {
    final dto = ValidateTransactionDto(
      valide: true,
      commentaire: 'Transaction conforme, quantité vérifiée',
    );

    final validated = await TransactionPartenaritService.validateTransaction(
      transactionId,
      dto,
    );

    print('✅ Transaction validée:');
    print('   Statut: ${validated.getStatusLabel()}');
    print('   Date: ${validated.dateValidation}');
    print('   Commentaire: ${validated.commentaire}');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// ========================================
/// EXEMPLE 4: User rejette une transaction
/// ========================================

Future<void> exempleRejeterTransaction(int transactionId) async {
  try {
    final dto = ValidateTransactionDto(
      valide: false,
      commentaire: 'Quantité incorrecte - vérification nécessaire',
    );

    final rejected = await TransactionPartenaritService.validateTransaction(
      transactionId,
      dto,
    );

    print('❌ Transaction rejetée:');
    print('   Statut: ${rejected.getStatusLabel()}');
    print('   Raison: ${rejected.commentaire}');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// ========================================
/// EXEMPLE 5: Société modifie une transaction
/// ========================================

Future<void> exempleModifierTransaction(int transactionId) async {
  try {
    // Vérifier d'abord le statut
    final transaction = await TransactionPartenaritService.getTransactionById(transactionId);

    if (!transaction.isEnAttente()) {
      print('❌ Cette transaction ne peut plus être modifiée (statut: ${transaction.statut})');
      return;
    }

    // Modifier la transaction
    final dto = UpdateTransactionPartenaritDto(
      quantite: '2100 Kg',
      prixTotal: '2,100,000 CFA',
      commentaire: 'Correction quantité - pesée finale',
    );

    final updated = await TransactionPartenaritService.updateTransaction(transactionId, dto);

    print('✅ Transaction modifiée:');
    print('   Nouvelle quantité: ${updated.quantite}');
    print('   Nouveau total: ${updated.prixTotal}');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

/// ========================================
/// EXEMPLE 6: Widget complet pour Société
/// ========================================

class TransactionsSocietePage extends StatefulWidget {
  final int pageId;

  const TransactionsSocietePage({
    super.key,
    required this.pageId,
  });

  @override
  State<TransactionsSocietePage> createState() => _TransactionsSocietePageState();
}

class _TransactionsSocietePageState extends State<TransactionsSocietePage> {
  List<TransactionPartenaritModel> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await TransactionPartenaritService
          .getTransactionsForPage(widget.pageId);

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateDialog() {
    final periodeController = TextEditingController();
    final quantiteController = TextEditingController();
    final prixUnitaireController = TextEditingController();
    final prixTotalController = TextEditingController();
    final commentaireController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: periodeController,
                decoration: const InputDecoration(
                  labelText: 'Période',
                  hintText: 'Ex: Janvier à Mars 2023',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  hintText: 'Ex: 2038 Kg',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: prixUnitaireController,
                decoration: const InputDecoration(
                  labelText: 'Prix unitaire',
                  hintText: 'Ex: 1000 CFA',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: prixTotalController,
                decoration: const InputDecoration(
                  labelText: 'Prix total',
                  hintText: 'Ex: 2,038,000 CFA',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentaireController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Récupérer userId depuis le contexte
              final userId = 5; // À remplacer

              final dto = CreateTransactionPartenaritDto(
                pageId: widget.pageId,
                userId: userId,
                periode: periodeController.text,
                quantite: quantiteController.text,
                prixUnitaire: prixUnitaireController.text,
                prixTotal: prixTotalController.text,
                commentaire: commentaireController.text.isEmpty
                    ? null
                    : commentaireController.text,
              );

              try {
                await TransactionPartenaritService.createTransaction(dto);
                Navigator.pop(context);
                _loadTransactions();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction créée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showTransactionOptions(TransactionPartenaritModel transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Détails'),
            onTap: () {
              Navigator.pop(context);
              _showDetails(transaction);
            },
          ),
          if (transaction.isEnAttente()) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteTransaction(transaction.id);
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showDetails(TransactionPartenaritModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction #${transaction.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Période', transaction.periode),
            _buildDetailRow('Quantité', transaction.quantite),
            _buildDetailRow('Prix unitaire', transaction.prixUnitaire),
            _buildDetailRow('Prix total', transaction.prixTotal),
            _buildDetailRow('Statut', transaction.getStatusLabel()),
            if (transaction.commentaire != null)
              _buildDetailRow('Commentaire', transaction.commentaire!),
            if (transaction.dateValidation != null)
              _buildDetailRow(
                'Date validation',
                transaction.dateValidation.toString().substring(0, 16),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditDialog(TransactionPartenaritModel transaction) {
    final periodeController = TextEditingController(text: transaction.periode);
    final quantiteController = TextEditingController(text: transaction.quantite);
    final prixUnitaireController = TextEditingController(text: transaction.prixUnitaire);
    final prixTotalController = TextEditingController(text: transaction.prixTotal);
    final commentaireController = TextEditingController(text: transaction.commentaire);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: periodeController,
                decoration: const InputDecoration(labelText: 'Période'),
              ),
              TextField(
                controller: quantiteController,
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              TextField(
                controller: prixUnitaireController,
                decoration: const InputDecoration(labelText: 'Prix unitaire'),
              ),
              TextField(
                controller: prixTotalController,
                decoration: const InputDecoration(labelText: 'Prix total'),
              ),
              TextField(
                controller: commentaireController,
                decoration: const InputDecoration(labelText: 'Commentaire'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dto = UpdateTransactionPartenaritDto(
                periode: periodeController.text,
                quantite: quantiteController.text,
                prixUnitaire: prixUnitaireController.text,
                prixTotal: prixTotalController.text,
                commentaire: commentaireController.text,
              );

              try {
                await TransactionPartenaritService.updateTransaction(
                  transaction.id,
                  dto,
                );
                Navigator.pop(context);
                _loadTransactions();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction modifiée'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette transaction ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TransactionPartenaritService.deleteTransaction(id);
        _loadTransactions();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Aucune transaction'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                ),
    );
  }

  Widget _buildTransactionCard(TransactionPartenaritModel transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(transaction.getStatusColor()),
          child: const Icon(Icons.receipt, color: Colors.white, size: 20),
        ),
        title: Text(
          transaction.periode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantité: ${transaction.quantite}'),
            Text('Montant: ${transaction.prixTotal}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(transaction.getStatusColor()).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.getStatusLabel(),
                style: TextStyle(
                  color: Color(transaction.getStatusColor()),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: transaction.isEnAttente()
            ? const Icon(Icons.edit, color: Colors.blue)
            : null,
        onTap: () => _showTransactionOptions(transaction),
      ),
    );
  }
}

/// ========================================
/// EXEMPLE 7: Widget pour User (Validation)
/// ========================================

class TransactionsPendingUserPage extends StatefulWidget {
  const TransactionsPendingUserPage({super.key});

  @override
  State<TransactionsPendingUserPage> createState() =>
      _TransactionsPendingUserPageState();
}

class _TransactionsPendingUserPageState
    extends State<TransactionsPendingUserPage> {
  List<TransactionPartenaritModel> _transactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingTransactions();
  }

  Future<void> _loadPendingTransactions() async {
    setState(() => _isLoading = true);

    try {
      final transactions = await TransactionPartenaritService.getPendingTransactions();

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showValidationDialog(TransactionPartenaritModel transaction) {
    final commentaireController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider la transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Société: ${transaction.societeNom ?? "Inconnue"}'),
            const SizedBox(height: 8),
            Text('Période: ${transaction.periode}'),
            Text('Quantité: ${transaction.quantite}'),
            Text('Prix total: ${transaction.prixTotal}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentaireController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                hintText: 'Ajouter un commentaire...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final dto = ValidateTransactionDto(
                valide: false,
                commentaire: commentaireController.text.isEmpty
                    ? null
                    : commentaireController.text,
              );

              try {
                await TransactionPartenaritService.validateTransaction(
                  transaction.id,
                  dto,
                );
                Navigator.pop(context);
                _loadPendingTransactions();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction rejetée'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
          ElevatedButton(
            onPressed: () async {
              final dto = ValidateTransactionDto(
                valide: true,
                commentaire: commentaireController.text.isEmpty
                    ? null
                    : commentaireController.text,
              );

              try {
                await TransactionPartenaritService.validateTransaction(
                  transaction.id,
                  dto,
                );
                Navigator.pop(context);
                _loadPendingTransactions();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction validée'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions en attente'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('Aucune transaction en attente'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingTransactions,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFA500),
                            child: Icon(Icons.pending_actions, color: Colors.white),
                          ),
                          title: Text(
                            transaction.societeNom ?? 'Société inconnue',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Période: ${transaction.periode}'),
                              Text('Quantité: ${transaction.quantite}'),
                              Text('Montant: ${transaction.prixTotal}'),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _showValidationDialog(transaction),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
