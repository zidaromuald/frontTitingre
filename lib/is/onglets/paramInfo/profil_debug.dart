import 'package:flutter/material.dart';
import '../../../services/AuthUS/societe_auth_service.dart';
import '../../../services/AuthUS/auth_base_service.dart';
import '../../../services/api_service.dart';
import 'dart:convert';

/// Page de débogage pour tester le profil société
class ProfilDebugPage extends StatefulWidget {
  const ProfilDebugPage({super.key});

  @override
  State<ProfilDebugPage> createState() => _ProfilDebugPageState();
}

class _ProfilDebugPageState extends State<ProfilDebugPage> {
  String _debugInfo = 'En attente...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _testProfile();
  }

  Future<void> _testProfile() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '🔍 Test en cours...\n\n';
    });

    try {
      // Test 1: Vérifier le token
      _addDebug('📌 Test 1: Vérification du token');
      final token = await AuthBaseService.getToken();
      _addDebug('Token présent: ${token != null}');
      if (token != null) {
        _addDebug('Token (premiers 20 chars): ${token.substring(0, 20)}...');
      }

      // Test 2: Appel API brut
      _addDebug('\n📌 Test 2: Appel API brut à /societes/me');
      final response = await ApiService.get('/societes/me');
      _addDebug('Status code: ${response.statusCode}');
      _addDebug('Body: ${response.body}');

      if (response.statusCode == 200) {
        // Test 3: Parser le JSON
        _addDebug('\n📌 Test 3: Parsing JSON');
        final jsonResponse = jsonDecode(response.body);
        _addDebug('Structure JSON:');
        _addDebug(JsonEncoder.withIndent('  ').convert(jsonResponse));

        // Test 4: Créer le modèle
        _addDebug('\n📌 Test 4: Création du modèle SocieteModel');
        final societe = SocieteModel.fromJson(jsonResponse['data']);
        _addDebug('✅ Société créée:');
        _addDebug('  - ID: ${societe.id}');
        _addDebug('  - Nom: ${societe.nom}');
        _addDebug('  - Email: ${societe.email}');
        _addDebug('  - Profile présent: ${societe.profile != null}');

        if (societe.profile != null) {
          _addDebug('\n  Détails du profile:');
          _addDebug('    - Logo: ${societe.profile!.logo ?? "null"}');
          _addDebug('    - Description: ${societe.profile!.description ?? "null"}');
          _addDebug('    - Site web: ${societe.profile!.siteWeb ?? "null"}');
          _addDebug('    - Nb employés: ${societe.profile!.nombreEmployes ?? "null"}');
          _addDebug('    - Année création: ${societe.profile!.anneeCreation ?? "null"}');
          _addDebug('    - Produits: ${societe.profile!.produits ?? []}');
          _addDebug('    - Services: ${societe.profile!.services ?? []}');
          _addDebug('    - Centres intérêt: ${societe.profile!.centresInteret ?? []}');
        }

        _addDebug('\n✅ TOUS LES TESTS RÉUSSIS!');
      } else if (response.statusCode == 401) {
        _addDebug('❌ ERREUR 401: Non authentifié');
        _addDebug('Le token est invalide ou expiré');
      } else if (response.statusCode == 404) {
        _addDebug('❌ ERREUR 404: Profil introuvable');
        _addDebug('La société n\'a pas de profil créé');
      } else {
        _addDebug('❌ ERREUR ${response.statusCode}');
        _addDebug('Message: ${response.body}');
      }
    } catch (e, stackTrace) {
      _addDebug('\n❌ EXCEPTION CAPTURÉE:');
      _addDebug('Type: ${e.runtimeType}');
      _addDebug('Message: $e');
      _addDebug('\nStack trace:');
      _addDebug(stackTrace.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addDebug(String message) {
    setState(() {
      _debugInfo += '$message\n';
    });
    print('[ProfilDebug] $message');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5ac18e),
        title: const Text('Debug Profil Société', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _testProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _debugInfo,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Vérifiez si le token est présent\n'
              '2. Regardez le status code de la réponse API\n'
              '3. Examinez la structure JSON retournée\n'
              '4. Vérifiez si le profil est présent dans les données\n\n'
              'Si vous voyez "TOUS LES TESTS RÉUSSIS", alors le problème est ailleurs.\n'
              'Si une erreur apparaît, notez le message pour corriger.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
