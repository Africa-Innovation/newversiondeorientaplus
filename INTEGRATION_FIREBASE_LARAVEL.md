## 🏗️ Configuration Firebase + Laravel API - Guide d'Intégration

### ✅ État Actuel
Votre projet Flutter **Orienta** est maintenant configuré avec une architecture hybride :
- **Firebase Firestore** : Stockage des données des universités
- **Laravel API** : Gestion des images pour éviter les coûts Firebase Storage

---

## 📋 Informations Manquantes pour Finaliser l'Intégration

### 1. 🔧 Configuration Laravel API

**Informations requises :**
- **URL de base de votre API Laravel** (ex: `https://votre-api.com`)
- **Token d'authentification** ou clé API si nécessaire
- **Structure des endpoints** pour les images :
  - Upload : `POST /api/university-images`
  - Update : `PUT /api/university-images/{id}`
  - Delete : `DELETE /api/university-images/{id}`

**Fichier à modifier :** `lib/services/image_api_service.dart`
```dart
class ImageApiService {
  static const String _baseUrl = 'VOTRE_URL_API_ICI'; // ⚠️ À configurer
  static const String _authToken = 'VOTRE_TOKEN_ICI'; // ⚠️ À configurer
```

### 2. 🔑 Authentification Laravel

**Questions importantes :**
- Votre API utilise-t-elle une authentification ?
  - [ ] Bearer Token
  - [ ] API Key
  - [ ] Basic Auth
  - [ ] Aucune authentification

**Si authentifié, fournir :**
- Format du header d'authentification
- Token ou clés d'accès

### 3. 🖼️ Structure de Réponse Laravel

**Format attendu pour l'upload d'image :**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "id": "123",
    "url": "https://votre-api.com/storage/images/university_123.jpg",
    "filename": "university_123.jpg"
  }
}
```

**Confirmer si votre API renvoie ce format ou fournir le format actuel.**

### 4. 🌐 Configuration CORS

**Vérifier que votre API Laravel autorise :**
- Domaine de votre app Flutter (si web)
- Headers : `Content-Type`, `Authorization`
- Méthodes : `GET`, `POST`, `PUT`, `DELETE`

### 5. 📱 Permissions Android/iOS

**Android** (`android/app/src/main/AndroidManifest.xml`) :
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`) :
```xml
<key>NSCameraUsageDescription</key>
<string>Cette app a besoin d'accéder à la caméra pour prendre des photos d'universités</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cette app a besoin d'accéder à la galerie pour sélectionner des images d'universités</string>
```

---

## 🔥 Firebase - Configuration Restante

### 1. 📁 Fichier de Configuration Firebase

**Android** : Vérifier que `android/app/google-services.json` est présent
**iOS** : Vérifier que `ios/Runner/GoogleService-Info.plist` est présent

### 2. 🔧 Configuration Build

**Android** (`android/app/build.gradle`) :
```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.0.0')
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-auth'
}
```

---

## 🚀 Prochaines Étapes

### Immédiatement nécessaire :
1. **URL de votre API Laravel**
2. **Token d'authentification** (si applicable)
3. **Format de réponse** de votre API

### Pour tester :
1. Configurer l'URL API dans `image_api_service.dart`
2. Tester la création d'une université avec image
3. Vérifier que l'université apparaît dans la page d'accueil

### Commande de test :
```bash
flutter run
```

---

## 📞 Questions de Clarification

1. **Avez-vous déjà développé l'API Laravel pour les images ?**
2. **Quelle est l'URL de base de votre API ?**
3. **Votre API nécessite-t-elle une authentification ?**
4. **Quel format de réponse votre API utilise-t-elle ?**

Une fois ces informations fournies, l'intégration sera complète et fonctionnelle ! 🎯
