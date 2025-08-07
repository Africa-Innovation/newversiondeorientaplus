# 📚 Documentation API Laravel - Images Management

## 🌐 **Informations Générales de l'API**

### 🔗 **Configuration Serveur**
- **URL de Base** : `http://127.0.0.1:8000`
- **Préfixe API** : `/api/v1`
- **URL Complète** : `http://127.0.0.1:8000/api/v1`
- **Authentification** : Aucune (API publique)
- **Format de Réponse** : JSON
- **Encodage** : UTF-8

### 🚀 **Démarrage du Serveur**
```bash
# Dans le dossier du projet Laravel
cd C:\xampp\htdocs\orientanewversion

# Démarrer le serveur de développement
php artisan serve

# Résultat attendu:
# INFO  Server running on [http://127.0.0.1:8000].
```

### 📋 **Prérequis**
- ✅ **XAMPP MySQL** démarré
- ✅ **PHP 8.1+** installé
- ✅ **Laravel 11** configuré
- ✅ **Base de données** : `orientasuccess`
- ✅ **Table** : `images`

---

## 🛣️ **Routes Disponibles**

### 📊 **Tableau des Endpoints**

| Méthode | Endpoint | Description | Paramètres |
|---------|----------|-------------|------------|
| `GET` | `/api/v1/images` | Liste toutes les images | - |
| `POST` | `/api/v1/images` | Upload une nouvelle image | `image` (file), `alt_text` (string, optionnel) |
| `GET` | `/api/v1/images/{id}` | Détails d'une image spécifique | `id` (integer) |
| `PUT` | `/api/v1/images/{id}` | Mettre à jour une image | `id` (integer), `alt_text` (string) |
| `DELETE` | `/api/v1/images/{id}` | Supprimer une image | `id` (integer) |
| `GET` | `/api/v1/images/{id}/url` | Obtenir l'URL publique d'une image | `id` (integer) |

### 🏷️ **Headers Requis**
```http
Accept: application/json
Content-Type: application/json  (pour GET/DELETE)
Content-Type: multipart/form-data  (pour POST avec fichier)
```

---

## 📋 **Détails des Endpoints**

### 1. 📥 **GET /api/v1/images** - Liste des Images

**Description** : Récupère la liste de toutes les images triées par date de création (plus récentes en premier)

**URL Complète** : `http://127.0.0.1:8000/api/v1/images`

**Méthode** : `GET`

**Paramètres** : Aucun

**Réponse Succès (200)** :
```json
{
  "success": true,
  "message": "Images récupérées avec succès",
  "data": [
    {
      "id": 1,
      "filename": "550e8400-e29b-41d4-a716-446655440000.jpg",
      "original_name": "mon_image.jpg",
      "path": "images/550e8400-e29b-41d4-a716-446655440000.jpg",
      "url": "http://127.0.0.1:8000/storage/images/550e8400-e29b-41d4-a716-446655440000.jpg",
      "mime_type": "image/jpeg",
      "size": 1048576,
      "formatted_size": "1.00 MB",
      "width": 1920,
      "height": 1080,
      "alt_text": "Description de l'image",
      "created_at": "2025-08-07T10:30:00.000000Z",
      "updated_at": "2025-08-07T10:30:00.000000Z"
    }
  ]
}
```

**Réponse Erreur (500)** :
```json
{
  "success": false,
  "message": "Erreur lors de la récupération des images",
  "error": "Message d'erreur détaillé"
}
```

---

### 2. 📤 **POST /api/v1/images** - Upload d'Image

**Description** : Upload une nouvelle image sur le serveur

**URL Complète** : `http://127.0.0.1:8000/api/v1/images`

**Méthode** : `POST`

**Content-Type** : `multipart/form-data`

**Paramètres** :
- `image` (file, **requis**) : Le fichier image à uploader
- `alt_text` (string, optionnel) : Texte alternatif pour l'image

**Formats Supportés** : JPG, JPEG, PNG, GIF, WEBP

**Taille Maximum** : Définie par PHP (généralement 2MB par défaut)

**Exemple de Requête** :
```http
POST http://127.0.0.1:8000/api/v1/images
Content-Type: multipart/form-data

image: [fichier binaire]
alt_text: "Photo de l'université XYZ"
```

**Réponse Succès (201)** :
```json
{
  "success": true,
  "message": "Image uploadée avec succès",
  "data": {
    "id": 1,
    "filename": "550e8400-e29b-41d4-a716-446655440000.jpg",
    "original_name": "mon_image.jpg",
    "path": "images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "url": "http://127.0.0.1:8000/storage/images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "mime_type": "image/jpeg",
    "size": 1048576,
    "formatted_size": "1.00 MB",
    "width": 1920,
    "height": 1080,
    "alt_text": "Photo de l'université XYZ",
    "created_at": "2025-08-07T10:30:00.000000Z",
    "updated_at": "2025-08-07T10:30:00.000000Z"
  }
}
```

**Réponse Erreur Validation (422)** :
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "image": [
      "The image field is required."
    ]
  }
}
```

**Réponse Erreur Serveur (500)** :
```json
{
  "success": false,
  "message": "Erreur lors de l'upload de l'image",
  "error": "Message d'erreur détaillé"
}
```

---

### 3. 🔍 **GET /api/v1/images/{id}** - Détails d'une Image

**Description** : Récupère les détails d'une image spécifique

**URL Complète** : `http://127.0.0.1:8000/api/v1/images/{id}`

**Méthode** : `GET`

**Paramètres URL** :
- `id` (integer, **requis**) : L'ID de l'image

**Exemple** : `http://127.0.0.1:8000/api/v1/images/1`

**Réponse Succès (200)** :
```json
{
  "success": true,
  "message": "Image récupérée avec succès",
  "data": {
    "id": 1,
    "filename": "550e8400-e29b-41d4-a716-446655440000.jpg",
    "original_name": "mon_image.jpg",
    "path": "images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "url": "http://127.0.0.1:8000/storage/images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "mime_type": "image/jpeg",
    "size": 1048576,
    "formatted_size": "1.00 MB",
    "width": 1920,
    "height": 1080,
    "alt_text": "Description de l'image",
    "created_at": "2025-08-07T10:30:00.000000Z",
    "updated_at": "2025-08-07T10:30:00.000000Z"
  }
}
```

**Réponse Erreur Non Trouvé (404)** :
```json
{
  "success": false,
  "message": "Image non trouvée"
}
```

---

### 4. ✏️ **PUT /api/v1/images/{id}** - Modifier une Image

**Description** : Met à jour le texte alternatif d'une image

**URL Complète** : `http://127.0.0.1:8000/api/v1/images/{id}`

**Méthode** : `PUT`

**Content-Type** : `application/json`

**Paramètres URL** :
- `id` (integer, **requis**) : L'ID de l'image

**Paramètres Body** :
- `alt_text` (string, **requis**) : Nouveau texte alternatif

**Exemple de Requête** :
```http
PUT http://127.0.0.1:8000/api/v1/images/1
Content-Type: application/json

{
  "alt_text": "Nouveau texte alternatif"
}
```

**Réponse Succès (200)** :
```json
{
  "success": true,
  "message": "Image mise à jour avec succès",
  "data": {
    "id": 1,
    "filename": "550e8400-e29b-41d4-a716-446655440000.jpg",
    "original_name": "mon_image.jpg",
    "path": "images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "url": "http://127.0.0.1:8000/storage/images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "mime_type": "image/jpeg",
    "size": 1048576,
    "formatted_size": "1.00 MB",
    "width": 1920,
    "height": 1080,
    "alt_text": "Nouveau texte alternatif",
    "created_at": "2025-08-07T10:30:00.000000Z",
    "updated_at": "2025-08-07T10:35:00.000000Z"
  }
}
```

**Réponse Erreur Non Trouvé (404)** :
```json
{
  "success": false,
  "message": "Image non trouvée"
}
```

---

### 5. 🗑️ **DELETE /api/v1/images/{id}** - Supprimer une Image

**Description** : Supprime une image et son fichier physique

**URL Complète** : `http://127.0.0.1:8000/api/v1/images/{id}`

**Méthode** : `DELETE`

**Paramètres URL** :
- `id` (integer, **requis**) : L'ID de l'image

**Exemple** : `http://127.0.0.1:8000/api/v1/images/1`

**Réponse Succès (200)** :
```json
{
  "success": true,
  "message": "Image supprimée avec succès"
}
```

**Réponse Erreur Non Trouvé (404)** :
```json
{
  "success": false,
  "message": "Image non trouvée"
}
```

**Réponse Erreur Serveur (500)** :
```json
{
  "success": false,
  "message": "Erreur lors de la suppression de l'image",
  "error": "Message d'erreur détaillé"
}
```

---

### 6. 🔗 **GET /api/v1/images/{id}/url** - URL Publique d'une Image

**Description** : Récupère uniquement l'URL publique d'une image

**URL Complète** : `http://127.0.0.1:8000/api/v1/images/{id}/url`

**Méthode** : `GET`

**Paramètres URL** :
- `id` (integer, **requis**) : L'ID de l'image

**Exemple** : `http://127.0.0.1:8000/api/v1/images/1/url`

**Réponse Succès (200)** :
```json
{
  "success": true,
  "message": "URL de l'image récupérée avec succès",
  "data": {
    "id": 1,
    "url": "http://127.0.0.1:8000/storage/images/550e8400-e29b-41d4-a716-446655440000.jpg",
    "filename": "550e8400-e29b-41d4-a716-446655440000.jpg",
    "original_name": "mon_image.jpg"
  }
}
```

---

## 📊 **Structure des Données**

### 🖼️ **Objet Image Complet**
```json
{
  "id": 1,                    // ID unique de l'image
  "filename": "uuid.jpg",     // Nom de fichier généré (UUID)
  "original_name": "img.jpg", // Nom original du fichier uploadé
  "path": "images/uuid.jpg",  // Chemin relatif du fichier
  "url": "http://127.0.0.1:8000/storage/images/uuid.jpg", // URL complète
  "mime_type": "image/jpeg",  // Type MIME du fichier
  "size": 1048576,           // Taille en bytes
  "formatted_size": "1.00 MB", // Taille formatée lisible
  "width": 1920,             // Largeur en pixels
  "height": 1080,            // Hauteur en pixels
  "alt_text": "Description", // Texte alternatif (peut être null)
  "created_at": "2025-08-07T10:30:00.000000Z", // Date de création
  "updated_at": "2025-08-07T10:30:00.000000Z"  // Date de modification
}
```

### 📝 **Types de Données**
- `id`: integer
- `filename`: string (UUID + extension)
- `original_name`: string
- `path`: string
- `url`: string (URL complète)
- `mime_type`: string
- `size`: integer (bytes)
- `formatted_size`: string (ex: "1.00 MB")
- `width`: integer (pixels)
- `height`: integer (pixels)
- `alt_text`: string|null
- `created_at`: datetime (ISO 8601)
- `updated_at`: datetime (ISO 8601)

---

## 🚨 **Gestion des Erreurs**

### 📋 **Codes de Statut HTTP**
- `200` : Succès
- `201` : Créé avec succès
- `404` : Ressource non trouvée
- `422` : Erreur de validation
- `500` : Erreur serveur interne

### 🔧 **Format des Erreurs de Validation**
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "field_name": [
      "Message d'erreur spécifique"
    ]
  }
}
```

### ⚠️ **Format des Erreurs Serveur**
```json
{
  "success": false,
  "message": "Description de l'erreur",
  "error": "Message technique détaillé"
}
```

---

## 🔧 **Configuration pour Flutter**

### 📱 **URL selon l'Environnement**

**Développement Local (Localhost)** :
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
```

**Émulateur Android** :
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

**Appareil Physique** :
```dart
// Remplacez par l'IP de votre PC
static const String baseUrl = 'http://192.168.1.XXX:8000/api/v1';
```

### 🛠️ **Service Flutter Recommandé**
```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  
  static Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // GET /api/v1/images
  static Future<List<dynamic>> getAllImages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/images'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    }
    throw Exception('Erreur: ${response.statusCode}');
  }

  // POST /api/v1/images
  static Future<Map<String, dynamic>> uploadImage(File imageFile, {String? altText}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images'));
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    if (altText != null) request.fields['alt_text'] = altText;
    
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 201) {
      return json.decode(responseBody);
    }
    throw Exception('Erreur: ${response.statusCode}');
  }

  // GET /api/v1/images/{id}
  static Future<Map<String, dynamic>> getImage(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/images/$id'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    }
    throw Exception('Erreur: ${response.statusCode}');
  }

  // PUT /api/v1/images/{id}
  static Future<Map<String, dynamic>> updateImage(int id, String altText) async {
    final response = await http.put(
      Uri.parse('$baseUrl/images/$id'),
      headers: headers,
      body: json.encode({'alt_text': altText}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    }
    throw Exception('Erreur: ${response.statusCode}');
  }

  // DELETE /api/v1/images/{id}
  static Future<bool> deleteImage(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/images/$id'),
      headers: headers,
    );
    
    return response.statusCode == 200;
  }

  // GET /api/v1/images/{id}/url
  static Future<String> getImageUrl(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/images/$id/url'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['url'];
    }
    throw Exception('Erreur: ${response.statusCode}');
  }
}
```

---

## 🧪 **Tests de l'API**

### 📋 **Checklist de Test**
- [ ] Serveur Laravel démarré : `php artisan serve`
- [ ] XAMPP MySQL actif
- [ ] Test GET /api/v1/images dans le navigateur
- [ ] Test upload avec Postman/curl
- [ ] Vérification des fichiers dans storage/app/public/images

### 🔧 **Commandes de Test curl**

**Test de connexion** :
```bash
curl -X GET "http://127.0.0.1:8000/api/v1/images" -H "Accept: application/json"
```

**Test upload** :
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/images" \
  -H "Accept: application/json" \
  -F "image=@/path/to/image.jpg" \
  -F "alt_text=Test image"
```

**Test récupération** :
```bash
curl -X GET "http://127.0.0.1:8000/api/v1/images/1" -H "Accept: application/json"
```

---

## 📁 **Structure des Fichiers**

### 🗂️ **Dossiers Importants**
```
orientanewversion/
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/
│   │   │   └── ImageController.php
│   │   ├── Requests/
│   │   │   ├── StoreImageRequest.php
│   │   │   └── UpdateImageRequest.php
│   │   └── Resources/
│   │       └── ImageResource.php
│   └── Models/
│       └── Image.php
├── routes/
│   └── api.php
├── storage/
│   └── app/
│       └── public/
│           └── images/  (fichiers uploadés)
└── public/
    └── storage/  (lien symbolique)
```

### 📝 **Base de Données**
**Table** : `images`
```sql
CREATE TABLE images (
    id bigint PRIMARY KEY AUTO_INCREMENT,
    filename varchar(255) NOT NULL,
    original_name varchar(255) NOT NULL,
    path varchar(255) NOT NULL,
    mime_type varchar(255) NOT NULL,
    size bigint NOT NULL,
    width int,
    height int,
    alt_text text,
    created_at timestamp,
    updated_at timestamp
);
```

---

## 🎯 **Résumé pour l'Équipe Flutter**

### ✅ **Informations Essentielles**
- **URL Base** : `http://127.0.0.1:8000/api/v1`
- **Format** : JSON avec structure `{success, message, data}`
- **Upload** : Multipart form-data sur `/images`
- **CRUD Complet** : Toutes les opérations disponibles
- **Pas d'authentification** requise

### 🚀 **Prêt à l'Intégration**
L'API est complètement fonctionnelle et prête pour l'intégration Flutter. Toutes les routes retournent des données cohérentes et gèrent les erreurs proprement.

**L'équipe Flutter peut commencer l'intégration immédiatement !** 🎉
