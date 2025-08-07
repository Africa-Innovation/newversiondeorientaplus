# 📸 API CRUD Images - Guide Flutter
## Projet OrientaSuccess

### 🚀 Configuration rapide

#### Base URL de l'API
```
http://localhost:8000/api/v1
```

#### URLs selon votre environnement Flutter :
```dart
// Émulateur Android
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Simulateur iOS  
static const String baseUrl = 'http://localhost:8000/api/v1';

// Appareil physique (remplacez par votre IP)
static const String baseUrl = 'http://192.168.1.XXX:8000/api/v1';
```

---

## 📡 Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/images` | Lister toutes les images |
| `POST` | `/images` | Uploader une nouvelle image |
| `GET` | `/images/{id}` | Récupérer une image spécifique |
| `PUT` | `/images/{id}` | Mettre à jour le texte alternatif |
| `DELETE` | `/images/{id}` | Supprimer une image |
| `GET` | `/images/{id}/url` | Obtenir l'URL publique |

---

## 📱 Intégration Flutter

### 🔧 Dépendances (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  image_picker: ^1.0.4
  path: ^1.8.3
  mime: ^1.0.4
  http_parser: ^4.0.2
```

### 📱 Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSCameraUsageDescription</key>
<string>Cette app a besoin d'accéder à la caméra pour prendre des photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette app a besoin d'accéder à la galerie pour sélectionner des images</string>
```

---

## 📦 Modèle de données

### `lib/models/image_model.dart`
```dart
class ImageModel {
  final int id;
  final String filename;
  final String originalName;
  final String url;
  final String mimeType;
  final int size;
  final String formattedSize;
  final int? width;
  final int? height;
  final String? altText;
  final DateTime createdAt;
  final DateTime updatedAt;

  ImageModel({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.formattedSize,
    this.width,
    this.height,
    this.altText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      filename: json['filename'],
      originalName: json['original_name'],
      url: json['url'],
      mimeType: json['mime_type'],
      size: json['size'],
      formattedSize: json['formatted_size'],
      width: json['width'],
      height: json['height'],
      altText: json['alt_text'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      errors: json['errors'],
    );
  }
}
```

---

## 🌐 Service API

### `lib/services/api_service.dart`
```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/image_model.dart';

class ApiService {
  // ⚠️ CHANGER SELON VOTRE ENVIRONNEMENT
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1'; 

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// 📋 Récupérer toutes les images
  static Future<ApiResponse<List<ImageModel>>> getAllImages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        List<ImageModel> images = (json['data'] as List)
            .map((item) => ImageModel.fromJson(item))
            .toList();
        
        return ApiResponse<List<ImageModel>>(
          success: json['success'],
          message: json['message'],
          data: images,
        );
      } else {
        return ApiResponse<List<ImageModel>>(
          success: false,
          message: json['message'] ?? 'Erreur lors de la récupération',
        );
      }
    } catch (e) {
      return ApiResponse<List<ImageModel>>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// 📤 Uploader une image
  static Future<ApiResponse<ImageModel>> uploadImage(
    File imageFile, {
    String? altText,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images'));
      
      String? mimeType = lookupMimeType(imageFile.path);
      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);

      if (altText != null && altText.isNotEmpty) {
        request.fields['alt_text'] = altText;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return ApiResponse<ImageModel>(
          success: json['success'],
          message: json['message'],
          data: ImageModel.fromJson(json['data']),
        );
      } else {
        return ApiResponse<ImageModel>(
          success: false,
          message: json['message'] ?? 'Erreur lors de l\'upload',
          errors: json['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<ImageModel>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// 👁️ Récupérer une image par ID
  static Future<ApiResponse<ImageModel>> getImageById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images/$id'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<ImageModel>(
          success: json['success'],
          message: json['message'],
          data: ImageModel.fromJson(json['data']),
        );
      } else {
        return ApiResponse<ImageModel>(
          success: false,
          message: json['message'] ?? 'Image non trouvée',
        );
      }
    } catch (e) {
      return ApiResponse<ImageModel>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// ✏️ Mettre à jour le texte alternatif
  static Future<ApiResponse<ImageModel>> updateImage(int id, String? altText) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/images/$id'),
        headers: _headers,
        body: jsonEncode({'alt_text': altText}),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<ImageModel>(
          success: json['success'],
          message: json['message'],
          data: ImageModel.fromJson(json['data']),
        );
      } else {
        return ApiResponse<ImageModel>(
          success: false,
          message: json['message'] ?? 'Erreur lors de la mise à jour',
          errors: json['errors'],
        );
      }
    } catch (e) {
      return ApiResponse<ImageModel>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// 🗑️ Supprimer une image
  static Future<ApiResponse<void>> deleteImage(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/images/$id'),
        headers: _headers,
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: json['success'],
          message: json['message'],
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: json['message'] ?? 'Erreur lors de la suppression',
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }
}
```

---

## 📱 Exemple d'utilisation

### Upload simple
```dart
// Sélectionner et uploader une image
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);

if (image != null) {
  final response = await ApiService.uploadImage(
    File(image.path),
    altText: "Ma description",
  );
  
  if (response.success) {
    print('Image uploadée: ${response.data!.url}');
  } else {
    print('Erreur: ${response.message}');
  }
}
```

### Lister les images
```dart
final response = await ApiService.getAllImages();

if (response.success) {
  List<ImageModel> images = response.data!;
  // Afficher les images dans un ListView ou GridView
} else {
  print('Erreur: ${response.message}');
}
```

### Afficher une image
```dart
// Dans un Widget
Image.network(
  imageModel.url,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.broken_image);
  },
)
```

---

## 🔧 Configuration réseau

### Trouver votre IP locale
```bash
# Windows
ipconfig

# macOS/Linux  
ifconfig

# Ou utilisez cette commande dans votre terminal Laravel
php artisan serve --host=0.0.0.0 --port=8000
```

### Modifier l'URL dans le code
Dans `api_service.dart`, changez la `baseUrl` selon votre environnement :
```dart
// Émulateur Android
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Appareil physique (remplacez 192.168.1.100 par votre IP)
static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
```

---

## ⚠️ Points importants

1. **Formats acceptés** : jpeg, png, jpg, gif, svg, webp, bmp, tiff
2. **Taille maximale** : 10 MB par image
3. **Toujours vérifier** `response.success` avant d'utiliser les données
4. **Gestion d'erreurs** : Utilisez try/catch pour toutes les requêtes
5. **URL correcte** : Adaptez `baseUrl` selon votre environnement de test

---

## 🎯 Structure JSON des réponses

### Succès avec données
```json
{
  "success": true,
  "message": "Image uploadée avec succès",
  "data": {
    "id": 1,
    "filename": "uuid-generated.jpg",
    "original_name": "mon_image.jpg",
    "url": "http://localhost:8000/storage/images/uuid-generated.jpg",
    "mime_type": "image/jpeg",
    "size": 1048576,
    "formatted_size": "1 MB",
    "width": 1920,
    "height": 1080,
    "alt_text": "Description",
    "created_at": "2025-08-07T10:30:00.000000Z",
    "updated_at": "2025-08-07T10:30:00.000000Z"
  }
}
```

### Erreur de validation
```json
{
  "success": false,
  "message": "Erreur de validation",
  "errors": {
    "image": ["Une image est requise."],
    "alt_text": ["Le texte alternatif ne doit pas dépasser 255 caractères."]
  }
}
```

---

## 🚀 Quick Start

1. **Copiez** les fichiers `image_model.dart` et `api_service.dart`
2. **Modifiez** la `baseUrl` dans `ApiService`
3. **Ajoutez** les dépendances dans `pubspec.yaml`
4. **Configurez** les permissions Android/iOS
5. **Utilisez** les méthodes `ApiService` dans vos widgets

**L'API est prête à être utilisée ! 🎉**

---

### 📱 Écrans Flutter

#### `lib/screens/image_list_screen.dart`
```dart
import 'package:flutter/material.dart';
import '../models/image_model.dart';
import '../services/api_service.dart';
import 'image_upload_screen.dart';
import 'image_detail_screen.dart';

class ImageListScreen extends StatefulWidget {
  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  List<ImageModel> images = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await ApiService.getAllImages();
    
    setState(() {
      isLoading = false;
      if (response.success) {
        images = response.data ?? [];
      } else {
        errorMessage = response.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galerie d\'images'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadImages,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ImageUploadScreen()),
          );
          if (result == true) {
            loadImages(); // Recharger la liste après upload
          }
        },
        child: Icon(Icons.add_a_photo),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadImages,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (images.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune image trouvée'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ImageUploadScreen()),
                );
                if (result == true) {
                  loadImages();
                }
              },
              child: Text('Ajouter une image'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadImages,
      child: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return _buildImageCard(image);
        },
      ),
    );
  }

  Widget _buildImageCard(ImageModel image) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageDetailScreen(image: image),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                child: Image.network(
                  image.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.originalName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    image.formattedSize,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (image.width != null && image.height != null)
                    Text(
                      '${image.width} x ${image.height}',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
```

#### `lib/screens/image_upload_screen.dart`
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ImageUploadScreen extends StatefulWidget {
  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  File? _selectedImage;
  final TextEditingController _altTextController = TextEditingController();
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter une image'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone de sélection d'image
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Touchez pour sélectionner une image'),
                        ],
                      ),
                    ),
            ),
            
            SizedBox(height: 16),
            
            // Boutons de sélection
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text('Caméra'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Galerie'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Champ texte alternatif
            TextField(
              controller: _altTextController,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Entrez une description de l\'image',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            SizedBox(height: 24),
            
            // Bouton d'upload
            ElevatedButton(
              onPressed: _selectedImage != null && !_isUploading ? _uploadImage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Upload en cours...'),
                      ],
                    )
                  : Text('Uploader l\'image'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final response = await ApiService.uploadImage(
        _selectedImage!,
        altText: _altTextController.text.trim().isEmpty 
            ? null 
            : _altTextController.text.trim(),
      );

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image uploadée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer le succès
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          errorMessage += '\n' + response.errors!.values.join('\n');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _altTextController.dispose();
    super.dispose();
  }
}
```

#### `lib/screens/image_detail_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/image_model.dart';
import '../services/api_service.dart';

class ImageDetailScreen extends StatefulWidget {
  final ImageModel image;

  const ImageDetailScreen({Key? key, required this.image}) : super(key: key);

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late ImageModel _image;
  bool _isUpdating = false;
  bool _isDeleting = false;
  final TextEditingController _altTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _image = widget.image;
    _altTextController.text = _image.altText ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'image'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy_url',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copier l\'URL'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'copy_url') {
                _copyUrl();
              } else if (value == 'delete') {
                _showDeleteDialog();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: double.infinity,
              height: 300,
              child: Image.network(
                _image.url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 100),
                  );
                },
              ),
            ),
            
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations de base
                  _buildInfoCard(),
                  
                  SizedBox(height: 16),
                  
                  // Édition du texte alternatif
                  _buildAltTextEditor(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildInfoRow('Nom original', _image.originalName),
            _buildInfoRow('Nom de fichier', _image.filename),
            _buildInfoRow('Taille', _image.formattedSize),
            if (_image.width != null && _image.height != null)
              _buildInfoRow('Dimensions', '${_image.width} x ${_image.height} pixels'),
            _buildInfoRow('Type', _image.mimeType),
            _buildInfoRow('Uploadé le', _formatDate(_image.createdAt)),
            if (_image.updatedAt != _image.createdAt)
              _buildInfoRow('Modifié le', _formatDate(_image.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAltTextEditor() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            TextField(
              controller: _altTextController,
              decoration: InputDecoration(
                hintText: 'Entrez une description pour cette image',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdating ? null : _updateAltText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isUpdating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          SizedBox(width: 8),
                          Text('Mise à jour...'),
                        ],
                      )
                    : Text('Mettre à jour la description'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _image.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('URL copiée dans le presse-papiers')),
    );
  }

  Future<void> _updateAltText() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final response = await ApiService.updateImage(
        _image.id,
        _altTextController.text.trim().isEmpty ? null : _altTextController.text.trim(),
      );

      if (response.success && response.data != null) {
        setState(() {
          _image = response.data!;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Description mise à jour avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'image'),
        content: Text('Êtes-vous sûr de vouloir supprimer cette image ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImage() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final response = await ApiService.deleteImage(_image.id);

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image supprimée avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner à la liste
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  void dispose() {
    _altTextController.dispose();
    super.dispose();
  }
}
```

#### `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'screens/image_list_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrientaSuccess Images',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ImageListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

### 🔧 Configuration réseau

#### URLs selon l'environnement :

```dart
// Dans api_service.dart, choisissez l'URL appropriée :

// Pour émulateur Android
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Pour simulateur iOS
static const String baseUrl = 'http://localhost:8000/api/v1';

// Pour appareil physique (remplacez XXX par votre IP locale)
static const String baseUrl = 'http://192.168.1.XXX:8000/api/v1';
```

#### Trouver votre IP locale :
```bash
# Windows
ipconfig

# macOS/Linux
ifconfig
```

---

### 🚀 Installation et test

```bash
# 1. Créer un nouveau projet Flutter
flutter create image_gallery_app
cd image_gallery_app

# 2. Ajouter les dépendances dans pubspec.yaml

# 3. Copier les fichiers du code ci-dessus

# 4. Installer les dépendances
flutter pub get

# 5. Lancer l'app
flutter run
```

---

## 📈 Bonnes pratiques

1. **Toujours vérifier la réponse `success`** avant d'utiliser les données
2. **Gérer les erreurs** avec des try/catch
3. **Valider les fichiers côté client** avant l'upload
4. **Utiliser les URLs retournées** par l'API pour afficher les images
5. **Respecter la taille maximale** de 10MB par image

### Flutter spécifique
1. **Gestion des états** : Utilisez des setState appropriés pour l'UI
2. **Images réseau** : Toujours gérer les cas de chargement et d'erreur
3. **Permissions** : Vérifier les permissions avant d'accéder à la caméra/galerie
4. **Optimisation** : Redimensionner les images avant upload pour économiser la bande passante
5. **UX/UI** : Toujours donner un feedback utilisateur pendant les opérations asynchrones

---

## 🔍 Débogage Flutter

### Problèmes courants et solutions

#### 1. Erreur de connexion réseau
```dart
// Vérifiez l'URL dans api_service.dart
// Pour émulateur Android : http://10.0.2.2:8000/api/v1
// Pour appareil physique : http://[VOTRE_IP]:8000/api/v1
```

#### 2. Permissions manquantes
```yaml
# Android : android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />

# iOS : ios/Runner/Info.plist
<key>NSCameraUsageDescription</key>
<string>Cette app a besoin d'accéder à la caméra</string>
```

#### 3. Debug réseau
```dart
// Ajoutez des logs dans api_service.dart
print('Request URL: $baseUrl/images');
print('Response status: ${response.statusCode}');
print('Response body: ${response.body}');
```

---

## 🎯 Fonctionnalités Flutter implémentées

### ✅ Écrans disponibles
- **Liste des images** avec grid view responsive
- **Upload d'images** depuis caméra ou galerie
- **Détails d'image** avec édition du texte alternatif
- **Suppression d'images** avec confirmation

### ✅ Fonctionnalités
- **Pull-to-refresh** sur la liste
- **Loading states** pour toutes les opérations
- **Gestion d'erreurs** complète
- **Validation côté client**
- **Optimisation des images** avant upload
- **Copie d'URL** dans le presse-papiers
- **Interface Material Design**

---

## 🎉 L'API est prête !

Votre API CRUD pour images est maintenant complètement fonctionnelle et documentée. Vous pouvez commencer à l'utiliser pour vos projets !

**URL de test :** http://localhost:8000/test-api.html
**Base API :** http://localhost:8000/api/v1
