import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/image_api_service.dart';
import '../services/test_connection_service.dart';
import '../models/image_model.dart';

class TestApiScreen extends StatefulWidget {
  const TestApiScreen({super.key});

  @override
  State<TestApiScreen> createState() => _TestApiScreenState();
}

class _TestApiScreenState extends State<TestApiScreen> {
  bool _isTestingConnection = false;
  bool _isTestingMultiple = false;
  bool _isUploading = false;
  String _connectionStatus = 'Non testé';
  Map<String, bool> _urlTestResults = {};
  File? _selectedImage;
  ApiResponse<ImageModel>? _lastUploadResponse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test API Laravel'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔧 Test de connexion
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔧 Test de connexion API',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('URL: ${ImageApiService.getCurrentBaseUrl()}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTestingConnection ? null : _testConnection,
                            child: _isTestingConnection
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Test Simple'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTestingMultiple ? null : _testMultipleUrls,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            child: _isTestingMultiple
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Test Toutes URLs'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testServerDiagnostic,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                            child: const Text('Diagnostic Serveur'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'État: $_connectionStatus',
                      style: TextStyle(
                        color: _connectionStatus == 'Connecté'
                            ? Colors.green
                            : _connectionStatus == 'Échec'
                                ? Colors.red
                                : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Résultats des tests multiples
                    if (_urlTestResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Résultats des tests :',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ..._urlTestResults.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                entry.value ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: entry.value ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 📱 Test d'upload (mobile uniquement)
            if (!kIsWeb) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📤 Test upload d\'image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Affichage de l'image sélectionnée
                      if (_selectedImage != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.grey.shade100,
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Aucune image sélectionnée'),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Boutons de sélection
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galerie'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Caméra'),
                            ),
                          ),
                        ],
                      ),

                      if (_selectedImage != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _uploadImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: _isUploading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Upload en cours...'),
                                    ],
                                  )
                                : const Text('Uploader vers API Laravel'),
                          ),
                        ),
                      ],

                      // Résultat du dernier upload
                      if (_lastUploadResponse != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _lastUploadResponse!.success 
                                ? Colors.green.shade50 
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _lastUploadResponse!.success 
                                  ? Colors.green.shade200 
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _lastUploadResponse!.success 
                                        ? Icons.check_circle 
                                        : Icons.error,
                                    color: _lastUploadResponse!.success 
                                        ? Colors.green 
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _lastUploadResponse!.success ? 'Succès' : 'Échec',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _lastUploadResponse!.success 
                                          ? Colors.green.shade700 
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Message: ${_lastUploadResponse!.message}'),
                              if (_lastUploadResponse!.success && _lastUploadResponse!.data != null) ...[
                                const SizedBox(height: 8),
                                Text('URL: ${_lastUploadResponse!.data!.url}'),
                                Text('Taille: ${_lastUploadResponse!.data!.formattedSize}'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Message pour le web
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.web,
                        size: 48,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Test d\'upload non disponible sur le web',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Utilisez l\'application mobile pour tester l\'upload d\'images vers votre API Laravel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = 'Test en cours...';
    });

    final isConnected = await ImageApiService.testConnection();
    
    setState(() {
      _isTestingConnection = false;
      _connectionStatus = isConnected ? 'Connecté' : 'Échec';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConnected 
                ? '✅ API Laravel accessible !' 
                : '❌ Impossible de contacter l\'API Laravel',
          ),
          backgroundColor: isConnected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testMultipleUrls() async {
    setState(() {
      _isTestingMultiple = true;
      _urlTestResults.clear();
    });

    try {
      final results = await ImageApiService.testMultipleUrls();
      setState(() {
        _urlTestResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du test multiple: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTestingMultiple = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _lastUploadResponse = null; // Reset previous result
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ImageApiService.uploadUniversityImage(
        _selectedImage!,
        altText: 'Test image depuis l\'app Orienta',
        universityId: 'test_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _lastUploadResponse = response;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.success 
                  ? '✅ Image uploadée avec succès !' 
                  : '❌ Échec de l\'upload: ${response.message}',
            ),
            backgroundColor: response.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _testServerDiagnostic() async {
    print('\n' + '=' * 50);
    print('🧪 DIAGNOSTIC COMPLET DU SERVEUR');
    print('=' * 50);
    
    await TestConnectionService.testServerConnection();
    
    print('=' * 50);
    print('🧪 FIN DU DIAGNOSTIC');
    print('=' * 50 + '\n');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Diagnostic terminé - Vérifiez la console'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
}
