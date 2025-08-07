import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/image_model.dart';

class ImageApiService {
  // Configuration réseau selon la documentation API
  // URL différente selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1'; // Web - localhost direct
    } else {
      return 'http://10.0.2.2:8000/api/v1'; // Mobile - émulateur Android
    }
  }
  
  // URLs alternatives pour tests
  static const List<String> _alternativeUrls = [
    'http://10.0.2.2:8000/api/v1',      // Émulateur Android (principal)
    'http://127.0.0.1:8000/api/v1',     // Localhost (pour test)
    'http://localhost:8000/api/v1',     // Localhost alternatif
    'http://192.168.1.100:8000/api/v1', // IP locale (à ajuster selon votre réseau)
  ];

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Uploader une image pour une université
  static Future<ApiResponse<ImageModel>> uploadUniversityImage(
    File imageFile, {
    String? altText,
    String? universityId,
  }) async {
    try {
      print('Début upload image vers API Laravel...');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images'));
      
      // Ajout du fichier image - différent selon la plateforme
      String? mimeType = lookupMimeType(imageFile.path);
      http.MultipartFile multipartFile;
      
      if (kIsWeb) {
        // Pour le web, utiliser fromBytes
        final bytes = await imageFile.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.path.split('/').last,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
        print('Fichier web ajouté: ${imageFile.path.split('/').last}');
      } else {
        // Pour mobile, utiliser fromPath
        multipartFile = await http.MultipartFile.fromPath(
          'image', // Nom du champ attendu par l'API
          imageFile.path,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        );
        print('Fichier mobile ajouté: ${imageFile.path}');
      }
      
      request.files.add(multipartFile);

      // Ajouter les métadonnées optionnelles
      if (altText != null && altText.isNotEmpty) {
        request.fields['alt_text'] = altText;
        print('Alt text: $altText');
      }
      if (universityId != null) {
        request.fields['university_id'] = universityId;
        print('University ID: $universityId');
      }

      // Headers pour multipart
      request.headers.addAll({
        'Accept': 'application/json',
      });

      print('Envoi vers: $baseUrl/images');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Réponse API: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          print('Upload réussi!');
          return ApiResponse<ImageModel>(
            success: true,
            message: json['message'] ?? 'Image uploadée avec succès',
            data: ImageModel.fromJson(json['data']),
          );
        } else {
          return ApiResponse<ImageModel>(
            success: false,
            message: json['message'] ?? 'Erreur dans la réponse de l\'API',
            errors: json['errors'],
          );
        }
      } else {
        final json = jsonDecode(response.body);
        return ApiResponse<ImageModel>(
          success: false,
          message: json['message'] ?? 'Erreur HTTP ${response.statusCode}',
          errors: json['errors'],
        );
      }
    } catch (e) {
      print('Erreur upload image: $e');
      return ApiResponse<ImageModel>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Uploader une image depuis le web (avec bytes)
  static Future<ApiResponse<ImageModel>> uploadImageFromBytes(
    Uint8List imageBytes,
    String fileName, {
    String? altText,
    String? universityId,
  }) async {
    try {
      print('Début upload image web vers API Laravel...');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images'));
      
      // Détecter le type MIME depuis le nom de fichier
      String? mimeType = lookupMimeType(fileName);
      
      // Créer le fichier multipart depuis les bytes
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);
      print('Fichier web ajouté: $fileName (${imageBytes.length} bytes)');

      // Ajouter les métadonnées optionnelles
      if (altText != null && altText.isNotEmpty) {
        request.fields['alt_text'] = altText;
        print('Alt text: $altText');
      }
      if (universityId != null) {
        request.fields['university_id'] = universityId;
        print('University ID: $universityId');
      }

      // Headers pour multipart
      request.headers.addAll({
        'Accept': 'application/json',
      });

      print('Envoi vers: $baseUrl/images');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Réponse API: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['success'] == true && json['data'] != null) {
          print('Upload web réussi!');
          return ApiResponse<ImageModel>(
            success: true,
            message: json['message'] ?? 'Image uploadée avec succès',
            data: ImageModel.fromJson(json['data']),
          );
        } else {
          return ApiResponse<ImageModel>(
            success: false,
            message: json['message'] ?? 'Erreur dans la réponse de l\'API',
            errors: json['errors'],
          );
        }
      } else {
        final json = jsonDecode(response.body);
        return ApiResponse<ImageModel>(
          success: false,
          message: json['message'] ?? 'Erreur HTTP ${response.statusCode}',
          errors: json['errors'],
        );
      }
    } catch (e) {
      print('Erreur upload image web: $e');
      return ApiResponse<ImageModel>(
        success: false,
        message: 'Erreur de connexion: $e',
      );
    }
  }

  /// Récupérer toutes les images
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

  /// Récupérer une image par ID
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

  /// Supprimer une image
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

  /// Tester la connexion à l'API
  static Future<bool> testConnection() async {
    try {
      print('Test de connexion vers: $baseUrl');
      print('Vérifiez que votre serveur Laravel tourne sur le port 8000');
      
      final response = await http.get(
        Uri.parse('$baseUrl/images'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      print('Réponse reçue: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 200) {
        // Vérifier la structure de réponse selon la documentation
        try {
          final json = jsonDecode(response.body);
          // Structure attendue selon doc: {success, message, data}
          if (json.containsKey('success') && json.containsKey('data')) {
            print('API Laravel confirmée - Structure correcte');
            return true;
          } else {
            print('Réponse inattendue - Structure différente');
            return false;
          }
        } catch (e) {
          print('Erreur parsing JSON: $e');
          return false;
        }
      } else {
        print('Échec HTTP: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Test connexion API échoué: $e');
      print('Solutions possibles :');
      print('   1. Démarrez Laravel : php artisan serve --host=0.0.0.0 --port=8000');
      print('   2. Vérifiez l\'URL : $baseUrl');
      print('   3. Testez manuellement : curl $baseUrl/images');
      return false;
    }
  }

  /// Tester différentes URLs de connexion
  static Future<Map<String, bool>> testMultipleUrls() async {
    Map<String, bool> results = {};
    
    for (String url in _alternativeUrls) {
      try {
        print('Test de: $url');
        final response = await http.get(
          Uri.parse('$url/images'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
          // Vérifier que c'est bien notre API Laravel selon la doc
          try {
            final json = jsonDecode(response.body);
            // Structure attendue: {success, message, data}
            if (json.containsKey('success') && json.containsKey('data')) {
              results[url] = true;
              print('API Laravel détectée: $url');
            } else {
              results[url] = false;
              print('Réponse non conforme: $url');
            }
          } catch (e) {
            results[url] = false;
            print('JSON invalide: $url');
          }
        } else {
          results[url] = false;
          print('HTTP ${response.statusCode}: $url');
        }
      } catch (e) {
        results[url] = false;
        print('Connexion échouée: $url ($e)');
      }
    }
    
    return results;
  }

  /// Configuration pour différents environnements
  static String getCurrentBaseUrl() {
    return baseUrl;
  }
}