import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/auth_debugger.dart';

/// Page de debug pour diagnostiquer les problèmes d'authentification
class AuthDebugPage extends StatefulWidget {
  const AuthDebugPage({super.key});

  @override
  State<AuthDebugPage> createState() => _AuthDebugPageState();
}

class _AuthDebugPageState extends State<AuthDebugPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _diagnosticResults;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isLoading = true;
      _diagnosticResults = null;
    });

    try {
      final results = await AuthDebugger.runFullDiagnostic();
      AuthDebugger.printRecommendations(results);

      if (mounted) {
        setState(() {
          _diagnosticResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du diagnostic: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E4A8C),
        title: const Text(
          'Diagnostic Authentification',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _runDiagnostic,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Diagnostic en cours...'),
                ],
              ),
            )
          : _diagnosticResults == null
              ? const Center(child: Text('Aucun résultat'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildAuthStatusCard(),
                      const SizedBox(height: 16),
                      _buildApiTestCard('API /auth/me', _diagnosticResults!['apiConnection']),
                      const SizedBox(height: 16),
                      _buildApiTestCard('API /users/me (Profil)', _diagnosticResults!['profileLoad']),
                      const SizedBox(height: 16),
                      _buildApiTestCard('API /users/autocomplete (Recherche)', _diagnosticResults!['search']),
                      const SizedBox(height: 16),
                      _buildRecommendationsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final authStatus = _diagnosticResults!['authStatus'] as Map<String, dynamic>;
    final apiConnection = _diagnosticResults!['apiConnection'] as Map<String, dynamic>;
    final profileLoad = _diagnosticResults!['profileLoad'] as Map<String, dynamic>;
    final search = _diagnosticResults!['search'] as Map<String, dynamic>;

    final allSuccess = authStatus['isAuthenticated'] &&
        apiConnection['success'] &&
        profileLoad['success'] &&
        search['success'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allSuccess ? Icons.check_circle : Icons.error,
                  color: allSuccess ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    allSuccess ? 'Tout fonctionne !' : 'Problèmes détectés',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatusRow('Authentifié', authStatus['isAuthenticated']),
            _buildStatusRow('Connexion API', apiConnection['success']),
            _buildStatusRow('Chargement profil', profileLoad['success']),
            _buildStatusRow('Recherche', search['success']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.cancel,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthStatusCard() {
    final authStatus = _diagnosticResults!['authStatus'] as Map<String, dynamic>;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔐 Statut d\'authentification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Token présent', authStatus['hasToken'].toString()),
            _buildInfoRow('Longueur token', authStatus['tokenLength'].toString()),
            _buildCopyableRow('Token (aperçu)', authStatus['tokenPreview'] ?? 'N/A'),
            _buildInfoRow('Type utilisateur', authStatus['userType'] ?? 'N/A'),
            _buildInfoRow('Données utilisateur', authStatus['hasUserData'].toString()),
            _buildCopyableRow('URL API', authStatus['apiBaseUrl']),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTestCard(String title, Map<String, dynamic> testResult) {
    final success = testResult['success'] as bool;
    final statusCode = testResult['statusCode'];
    final endpoint = testResult['endpoint'];
    final body = testResult['body'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (endpoint != null) _buildCopyableRow('Endpoint', endpoint),
            if (statusCode != null)
              _buildInfoRow(
                'Code HTTP',
                statusCode.toString(),
                statusCode == 200 ? Colors.green : Colors.red,
              ),
            if (!success && testResult.containsKey('error'))
              _buildInfoRow('Erreur', testResult['error'], Colors.red),
            if (!success && testResult.containsKey('details'))
              _buildInfoRow('Détails', testResult['details'], Colors.orange),
            if (body != null) ...[
              const SizedBox(height: 8),
              const Text('Réponse:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body.length > 300 ? '${body.substring(0, 300)}...' : body,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    if (body.length > 50) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: body));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Réponse copiée !')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copier'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final authStatus = _diagnosticResults!['authStatus'] as Map<String, dynamic>;
    final apiConnection = _diagnosticResults!['apiConnection'] as Map<String, dynamic>;
    final profileLoad = _diagnosticResults!['profileLoad'] as Map<String, dynamic>;
    final search = _diagnosticResults!['search'] as Map<String, dynamic>;

    final recommendations = <String>[];

    if (!authStatus['hasToken']) {
      recommendations.add('❌ Aucun token trouvé - Reconnectez-vous');
    } else if (!apiConnection['success']) {
      final statusCode = apiConnection['statusCode'];
      if (statusCode == 401) {
        recommendations.add('❌ Token invalide ou expiré - Reconnectez-vous');
        recommendations.add('⚠️ Vérifiez que le backend accepte le token JWT');
      } else {
        recommendations.add('❌ Erreur HTTP $statusCode - Vérifiez le backend');
        recommendations.add('⚠️ Vérifiez les CORS sur le backend');
      }
    } else {
      if (!profileLoad['success']) {
        recommendations.add('⚠️ Le profil ne peut pas être chargé');
        recommendations.add('→ Vérifiez que /users/me existe sur le backend');
      }
      if (!search['success']) {
        recommendations.add('⚠️ La recherche ne fonctionne pas');
        recommendations.add('→ Vérifiez que /users/autocomplete existe');
      }
      if (profileLoad['success'] && search['success']) {
        recommendations.add('✅ Tout fonctionne correctement !');
      }
    }

    return Card(
      elevation: 2,
      color: recommendations.first.startsWith('✅') ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💡 Recommandations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(rec, style: const TextStyle(fontSize: 14)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
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
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
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
          Expanded(
            child: Text(value),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copié !')),
              );
            },
          ),
        ],
      ),
    );
  }
}
