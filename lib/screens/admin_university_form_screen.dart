import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/university.dart';
import '../models/program.dart';
import '../services/admin_university_service.dart';
import '../services/firebase_university_service.dart';
import '../services/image_api_service.dart';
import '../providers/app_provider.dart';

class AdminUniversityFormScreen extends StatefulWidget {
  final University? university; // null pour création, non-null pour édition

  const AdminUniversityFormScreen({
    super.key,
    this.university,
  });

  @override
  State<AdminUniversityFormScreen> createState() => _AdminUniversityFormScreenState();
}

class _AdminUniversityFormScreenState extends State<AdminUniversityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Contrôleurs pour les champs de base de l'université
  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _websiteController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _tuitionFeeController;

  String _selectedType = 'public';
  bool _hasScholarships = false;
  bool _hasAccommodation = false;
  List<String> _generalAdmissionRequirements = [];
  List<Program> _programs = [];

  bool _isLoading = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.university != null) {
      _loadUniversityData();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _cityController = TextEditingController();
    _websiteController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _tuitionFeeController = TextEditingController();
  }

  void _loadUniversityData() {
    final university = widget.university!;
    
    _nameController.text = university.name;
    _cityController.text = university.city;
    _selectedType = university.type;
    _websiteController.text = university.website ?? '';
    _contactController.text = university.contact ?? '';
    _emailController.text = university.email ?? '';
    _addressController.text = university.address ?? '';
    _uploadedImageUrl = university.imageUrl;
    _descriptionController.text = university.description ?? '';
    _latitudeController.text = university.latitude.toString();
    _longitudeController.text = university.longitude.toString();
    _tuitionFeeController.text = university.tuitionFee?.toString() ?? '';
    
    _hasScholarships = university.hasScholarships;
    _hasAccommodation = university.hasAccommodation;
    _generalAdmissionRequirements = List.from(university.generalAdmissionRequirements ?? []);
    _programs = List.from(university.programs);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _tuitionFeeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.university != null;

  /// 📷 Sélectionner une image depuis la galerie
  Future<void> _pickImageFromGallery() async {
    if (kIsWeb) {
      // Pour le web, utiliser file_picker
      await _pickImageForWeb();
    } else {
      // Pour mobile, utiliser image_picker
      await _pickImageForMobile(ImageSource.gallery);
    }
  }

  /// 📸 Prendre une photo avec la caméra
  Future<void> _pickImageFromCamera() async {
    if (kIsWeb) {
      _showErrorSnackBar('Prise de photo non supportée sur le web. Utilisez "Sélectionner image".');
      return;
    } else {
      // Pour mobile, utiliser image_picker
      await _pickImageForMobile(ImageSource.camera);
    }
  }

  /// 🌐 Sélection d'image pour le web
  Future<void> _pickImageForWeb() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important pour obtenir les bytes
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final bytes = file.bytes!;
        final fileName = file.name;
        
        print('📁 Fichier web sélectionné: $fileName (${bytes.length} bytes)');
        
        // Upload directement depuis les bytes
        await _uploadImageFromBytes(bytes, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// � Sélection d'image pour mobile
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
      print('🚀 Upload image web vers API Laravel...');
      
      final universityName = _nameController.text.trim();
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await ImageApiService.uploadImageFromBytes(
        bytes,
        fileName,
        altText: 'Image de $universityName',
        universityId: widget.university?.id ?? tempId,
      );

      if (response.success && response.data != null) {
        setState(() {
          _uploadedImageUrl = response.data!.url;
        });
        _showSuccessSnackBar('✅ Image uploadée avec succès!');
        print('✅ URL de l\'image: ${response.data!.url}');
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
      final universityName = _nameController.text.trim();
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await ImageApiService.uploadUniversityImage(
        _selectedImage!,
        altText: 'Image de $universityName',
        universityId: widget.university?.id ?? tempId,
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
  Future<void> _removeImage() async {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  /// 📤 Afficher message de succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// ❌ Afficher message d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveUniversity() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_programs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins un programme est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final university = University(
        id: _isEditing ? widget.university!.id : AdminUniversityService.generateNewId(),
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        type: _selectedType,
        programs: _programs,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        tuitionFee: _tuitionFeeController.text.isEmpty ? null : double.parse(_tuitionFeeController.text),
        website: _websiteController.text.isEmpty ? null : _websiteController.text.trim(),
        contact: _contactController.text.isEmpty ? null : _contactController.text.trim(),
        email: _emailController.text.isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.isEmpty ? null : _addressController.text.trim(),
        imageUrl: _uploadedImageUrl,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
        generalAdmissionRequirements: _generalAdmissionRequirements.isEmpty ? null : _generalAdmissionRequirements,
        hasScholarships: _hasScholarships,
        hasAccommodation: _hasAccommodation,
      );

      // Valider l'université
      final validationError = AdminUniversityService.validateUniversity(university);
      if (validationError != null) {
        throw Exception(validationError);
      }

      if (_isEditing) {
        await AdminUniversityService.updateUniversity(university);
        // Essayer de sauvegarder dans Firebase (avec fallback)
        try {
          await FirebaseUniversityService.updateUniversity(university);
        } catch (e) {
          debugPrint('⚠️ Firebase indisponible pour la mise à jour: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Université modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await AdminUniversityService.createUniversity(university);
        // Essayer de sauvegarder dans Firebase (avec fallback)
        try {
          await FirebaseUniversityService.saveUniversity(university);
        } catch (e) {
          debugPrint('⚠️ Firebase indisponible pour la sauvegarde: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Université créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Rafraîchir les universités dans l'AppProvider
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.refreshUniversities();
      }

      if (mounted) {
        Navigator.of(context).pop(true);
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

  void _addProgram() async {
    final program = await _showProgramDialog();
    if (program != null) {
      setState(() {
        _programs.add(program);
      });
    }
  }

  void _editProgram(int index) async {
    final program = await _showProgramDialog(program: _programs[index]);
    if (program != null) {
      setState(() {
        _programs[index] = program;
      });
    }
  }

  void _deleteProgram(int index) {
    setState(() {
      _programs.removeAt(index);
    });
  }

  void _addRequirement() async {
    final requirement = await _showTextInputDialog(
      title: 'Ajouter une exigence',
      hint: 'Ex: BAC toutes séries',
    );
    if (requirement != null && requirement.isNotEmpty) {
      setState(() {
        _generalAdmissionRequirements.add(requirement);
      });
    }
  }

  void _editRequirement(int index) async {
    final requirement = await _showTextInputDialog(
      title: 'Modifier l\'exigence',
      initialValue: _generalAdmissionRequirements[index],
    );
    if (requirement != null && requirement.isNotEmpty) {
      setState(() {
        _generalAdmissionRequirements[index] = requirement;
      });
    }
  }

  void _deleteRequirement(int index) {
    setState(() {
      _generalAdmissionRequirements.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'université' : 'Créer une université'),
        backgroundColor: Colors.green[700],
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
              onPressed: _saveUniversity,
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
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildContactSection(),
                const SizedBox(height: 24),
                _buildLocationSection(),
                const SizedBox(height: 24),
                _buildOptionsSection(),
                const SizedBox(height: 24),
                _buildRequirementsSection(),
                const SizedBox(height: 24),
                _buildProgramsSection(),
                const SizedBox(height: 100), // Espace pour le bouton flottant
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveUniversity,
              backgroundColor: Colors.green[700],
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
                Icon(Icons.info_outline, color: Colors.green[700]),
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'université *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ville *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La ville est requise';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'public', child: Text('Public')),
                      DropdownMenuItem(value: 'private', child: Text('Privé')),
                      DropdownMenuItem(value: 'formation_center', child: Text('Centre de formation')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Section pour l'image
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Image de l\'université',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Affichage de l'image actuelle ou sélectionnée
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
                              Icons.image_outlined,
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
                    
                    // Boutons pour gérer l'image - Maintenant disponible sur web et mobile !
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Informations de contact',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Site web',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.web),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Email invalide';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Géolocalisation',
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
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La latitude est requise';
                      }
                      final lat = double.tryParse(value);
                      if (lat == null || lat < -90 || lat > 90) {
                        return 'Latitude invalide (-90 à 90)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.place),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La longitude est requise';
                      }
                      final lng = double.tryParse(value);
                      if (lng == null || lng < -180 || lng > 180) {
                        return 'Longitude invalide (-180 à 180)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tuitionFeeController,
              decoration: const InputDecoration(
                labelText: 'Frais de scolarité de base (FCFA/an)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final fee = double.tryParse(value);
                  if (fee == null || fee < 0) {
                    return 'Montant invalide';
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

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Options et services',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Bourses d\'études disponibles'),
              subtitle: const Text('L\'université propose des bourses'),
              value: _hasScholarships,
              onChanged: (value) {
                setState(() {
                  _hasScholarships = value;
                });
              },
              activeColor: Colors.green[700],
            ),
            SwitchListTile(
              title: const Text('Hébergement disponible'),
              subtitle: const Text('L\'université propose un logement'),
              value: _hasAccommodation,
              onChanged: (value) {
                setState(() {
                  _hasAccommodation = value;
                });
              },
              activeColor: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Exigences générales d\'admission',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addRequirement,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter une exigence',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_generalAdmissionRequirements.isEmpty)
              const Center(
                child: Text(
                  'Aucune exigence définie',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generalAdmissionRequirements.length,
                itemBuilder: (context, index) {
                  final requirement = _generalAdmissionRequirements[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(requirement),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editRequirement(index),
                            icon: const Icon(Icons.edit),
                            iconSize: 20,
                          ),
                          IconButton(
                            onPressed: () => _deleteRequirement(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Programmes d\'études',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addProgram,
                  icon: const Icon(Icons.add),
                  tooltip: 'Ajouter un programme',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_programs.isEmpty)
              const Center(
                child: Text(
                  'Aucun programme défini (Au moins un requis)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.red,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _programs.length,
                itemBuilder: (context, index) {
                  final program = _programs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: const Icon(Icons.school),
                      title: Text(program.name),
                      subtitle: Text(
                        '${program.specialties.length} spécialité(s) • ${program.durationYears} ans',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _editProgram(index),
                            icon: const Icon(Icons.edit),
                            iconSize: 20,
                          ),
                          IconButton(
                            onPressed: () => _deleteProgram(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description:',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(program.description),
                              const SizedBox(height: 8),
                              Text(
                                'Débouchés:',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(program.career ?? 'Non spécifié'),
                              const SizedBox(height: 8),
                              Text(
                                'Spécialités:',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              ...program.specialties.map((specialty) => Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text('• ${specialty.name}'),
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showTextInputDialog({
    required String title,
    String? hint,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Program?> _showProgramDialog({Program? program}) async {
    return await showDialog<Program>(
      context: context,
      builder: (context) => _ProgramFormDialog(program: program),
    );
  }
}

class _ProgramFormDialog extends StatefulWidget {
  final Program? program;

  const _ProgramFormDialog({this.program});

  @override
  State<_ProgramFormDialog> createState() => _ProgramFormDialogState();
}

class _ProgramFormDialogState extends State<_ProgramFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _careerController;
  late TextEditingController _durationController;
  
  List<String> _admissionRequirements = [];
  List<Specialty> _specialties = [];
  Map<String, double> _priceByLevel = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _careerController = TextEditingController();
    _durationController = TextEditingController(text: '3');

    if (widget.program != null) {
      final program = widget.program!;
      _nameController.text = program.name;
      _descriptionController.text = program.description;
      _careerController.text = program.career ?? '';
      _durationController.text = program.durationYears.toString();
      _admissionRequirements = List.from(program.admissionRequirements);
      _specialties = List.from(program.specialties);
      _priceByLevel = Map.from(program.priceByLevel);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _careerController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _saveProgram() {
    if (!_formKey.currentState!.validate()) return;

    if (_specialties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins une spécialité est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final program = Program(
      id: widget.program?.id ?? AdminUniversityService.generateNewProgramId(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      specialties: _specialties,
      priceByLevel: _priceByLevel,
      durationYears: int.parse(_durationController.text),
      admissionRequirements: _admissionRequirements,
      career: _careerController.text.isEmpty ? null : _careerController.text.trim(),
    );

    Navigator.of(context).pop(program);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: Text(widget.program == null ? 'Nouveau programme' : 'Modifier le programme'),
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ANNULER',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: _saveProgram,
                  child: const Text(
                    'SAUVEGARDER',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du programme *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom est requis';
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
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Durée en années *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La durée est requise';
                          }
                          final duration = int.tryParse(value);
                          if (duration == null || duration < 1 || duration > 10) {
                            return 'Durée invalide (1-10 ans)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _careerController,
                        decoration: const InputDecoration(
                          labelText: 'Débouchés professionnels',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Spécialités (${_specialties.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_specialties.isEmpty)
                        const Text(
                          'Aucune spécialité (Au moins une requise)',
                          style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                        )
                      else
                        ...(_specialties.asMap().entries.map((entry) {
                          final index = entry.key;
                          final specialty = entry.value;
                          return Card(
                            child: ListTile(
                              title: Text(specialty.name),
                              subtitle: Text(specialty.description),
                              trailing: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _specialties.removeAt(index);
                                  });
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ),
                          );
                        })),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _addSpecialty(),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une spécialité'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSpecialty() async {
    final specialty = await _showSpecialtyDialog();
    if (specialty != null) {
      setState(() {
        _specialties.add(specialty);
      });
    }
  }

  Future<Specialty?> _showSpecialtyDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final licencePriceController = TextEditingController();
    final masterPriceController = TextEditingController();
    final doctoratPriceController = TextEditingController();
    
    return await showDialog<Specialty>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle spécialité'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la spécialité *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Prix par niveau (FCFA/an)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: licencePriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix Licence (Bac+3) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: masterPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix Master (Bac+5)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: doctoratPriceController,
                decoration: const InputDecoration(
                  labelText: 'Prix Doctorat (Bac+8)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.monetization_on),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  descriptionController.text.trim().isNotEmpty &&
                  licencePriceController.text.trim().isNotEmpty) {
                
                // Construire le map des prix
                final Map<String, double> priceByLevel = {};
                
                // Prix licence obligatoire
                final licencePrice = double.tryParse(licencePriceController.text.trim());
                if (licencePrice != null && licencePrice >= 0) {
                  priceByLevel['licence'] = licencePrice;
                }
                
                // Prix master optionnel
                final masterPrice = double.tryParse(masterPriceController.text.trim());
                if (masterPrice != null && masterPrice >= 0) {
                  priceByLevel['master'] = masterPrice;
                }
                
                // Prix doctorat optionnel
                final doctoratPrice = double.tryParse(doctoratPriceController.text.trim());
                if (doctoratPrice != null && doctoratPrice >= 0) {
                  priceByLevel['doctorat'] = doctoratPrice;
                }
                
                if (priceByLevel.isNotEmpty) {
                  final specialty = Specialty(
                    id: AdminUniversityService.generateNewSpecialtyId(),
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    priceByLevel: priceByLevel,
                  );
                  Navigator.of(context).pop(specialty);
                } else {
                  // Afficher une erreur si aucun prix valide
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Au moins le prix de licence doit être renseigné'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                // Afficher une erreur si les champs obligatoires sont vides
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs obligatoires'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
