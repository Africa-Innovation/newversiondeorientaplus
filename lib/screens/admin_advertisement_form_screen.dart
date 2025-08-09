import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/advertisement.dart';
import '../services/image_api_service.dart';
import '../services/firebase_advertisement_service.dart';
import '../providers/admin_advertisement_provider.dart';
import '../providers/app_provider.dart';

class AdminAdvertisementFormScreen extends StatefulWidget {
  final Advertisement? advertisement; // null pour création, non-null pour édition

  const AdminAdvertisementFormScreen({
    super.key,
    this.advertisement,
  });

  @override
  State<AdminAdvertisementFormScreen> createState() => _AdminAdvertisementFormScreenState();
}

class _AdminAdvertisementFormScreenState extends State<AdminAdvertisementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetUrlController;
  late TextEditingController _priorityController;
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.advertisement != null) {
      _loadAdvertisementData();
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _targetUrlController = TextEditingController();
    _priorityController = TextEditingController(text: '1');
  }

  void _loadAdvertisementData() {
    final ad = widget.advertisement!;
    
    _titleController.text = ad.title;
    _descriptionController.text = ad.description;
    _targetUrlController.text = ad.targetUrl ?? '';
    _priorityController.text = ad.priority.toString();
    _startDate = ad.startDate;
    _endDate = ad.endDate;
    _isActive = ad.isActive;
    _uploadedImageUrl = ad.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetUrlController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.advertisement != null;

  /// 📷 Sélectionner une image depuis la galerie
  Future<void> _pickImageFromGallery() async {
    if (kIsWeb) {
      await _pickImageForWeb();
    } else {
      await _pickImageForMobile(ImageSource.gallery);
    }
  }

  /// 📸 Prendre une photo avec la caméra
  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) {
      _showErrorSnackBar('Prise de photo non supportée sur le web. Utilisez "Sélectionner image".');
      return;
    } else {
      await _pickImageForMobile(ImageSource.camera);
    }
  }

  /// 🌐 Sélection d'image pour le web
  Future<void> _pickImageForWeb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final bytes = file.bytes!;
        final fileName = file.name;
        
        print('📁 Image pub web sélectionnée: $fileName (${bytes.length} bytes)');
        await _uploadImageFromBytes(bytes, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// 📱 Sélection d'image pour mobile
  Future<void> _pickImageForMobile(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadSelectedImage();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// 🌐 Upload d'image depuis des bytes (pour le web)
  Future<void> _uploadImageFromBytes(Uint8List bytes, String fileName) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      print('🚀 Upload image pub vers API Laravel...');
      
      final adTitle = _titleController.text.trim().isNotEmpty 
          ? _titleController.text.trim() 
          : 'Advertisement';
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await ImageApiService.uploadImageFromBytes(
        bytes,
        fileName,
        altText: 'Publicité $adTitle',
        universityId: 'advertisement_$tempId',
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedImageUrl = response.data!.url;
        });
        _showSuccessSnackBar('✅ Image uploadée avec succès!');
        print('✅ URL de l\'image pub: ${response.data!.url}');
      } else {
        _showErrorSnackBar('❌ Erreur upload: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('❌ Erreur lors de l\'upload: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  /// ☁️ Upload de l'image sélectionnée vers l'API Laravel
  Future<void> _uploadSelectedImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final adTitle = _titleController.text.trim().isNotEmpty 
          ? _titleController.text.trim() 
          : 'Advertisement';
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await ImageApiService.uploadUniversityImage(
        _selectedImage!,
        altText: 'Publicité $adTitle',
        universityId: 'advertisement_$tempId',
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedImageUrl = response.data!.url;
        });
        _showSuccessSnackBar('Image uploadée avec succès!');
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'upload: $e');
      setState(() {
        _selectedImage = null;
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  /// 🗑️ Supprimer l'image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  /// 💾 Sauvegarder la publicité
  Future<void> _saveAdvertisement() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une image est requise pour la publicité'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final advertisement = Advertisement(
        id: _isEditing ? widget.advertisement!.id : FirebaseAdvertisementService.generateNewId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _uploadedImageUrl!,
        targetUrl: _targetUrlController.text.isEmpty ? null : _targetUrlController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isActive: _isActive,
        priority: int.parse(_priorityController.text),
      );

      final provider = Provider.of<AdminAdvertisementProvider>(context, listen: false);
      bool success;

      if (_isEditing) {
        success = await provider.updateAdvertisement(advertisement);
      } else {
        success = await provider.addAdvertisement(advertisement);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Publicité modifiée avec succès' : 'Publicité créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 🔄 NOUVEAU: Rafraîchir les publicités dans l'AppProvider
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.refreshAdvertisements();
        
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 📅 Sélectionner une date
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // S'assurer que la date de fin est après la date de début
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
          // S'assurer que la date de fin est après la date de début
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la publicité' : 'Créer une publicité'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAdvertisement,
              child: Text(
                _isEditing ? 'MODIFIER' : 'CRÉER',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildImageSection(),
              const SizedBox(height: 24),
              _buildDateSection(),
              const SizedBox(height: 24),
              _buildSettingsSection(),
              const SizedBox(height: 100), // Espace pour le bouton flottant
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveAdvertisement,
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Sauvegarder' : 'Créer'),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Informations de base',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la publicité *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de destination (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
                hintText: 'https://example.com',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.isAbsolute) {
                    return 'URL invalide';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Image de la publicité *',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Affichage de l'image
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _uploadedImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.grey.shade100,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 50,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Aucune image sélectionnée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Boutons pour gérer l'image
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickImageFromGallery,
                    icon: Icon(kIsWeb ? Icons.upload_file : Icons.photo_library),
                    label: Text(kIsWeb ? 'Sélectionner image' : 'Galerie'),
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                    ),
                  ),
                ],
                if (_selectedImage != null || _uploadedImageUrl != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _removeImage,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            if (_isUploadingImage)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Période d\'affichage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date de début',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date de fin',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Paramètres',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorityController,
              decoration: const InputDecoration(
                labelText: 'Priorité *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
                helperText: 'Plus le nombre est élevé, plus la publicité sera prioritaire',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La priorité est requise';
                }
                final priority = int.tryParse(value);
                if (priority == null || priority < 0) {
                  return 'Priorité invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Publicité active'),
              subtitle: const Text('La publicité sera visible par les utilisateurs'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
              activeColor: Colors.orange[700],
            ),
          ],
        ),
      ),
    );
  }
}
