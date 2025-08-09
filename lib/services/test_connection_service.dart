import 'package:http/http.dart' as http;

class TestConnectionService {
  static Future<void> testServerConnection() async {
    print('🧪 Test de connexion au serveur Laravel...');
    
    List<String> urlsToTest = [
      'http://192.168.11.101:8000',  // IP réseau local (priorité)
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://localhost:8000',
    ];
    
    for (String baseUrl in urlsToTest) {
      try {
        print('📡 Test de $baseUrl...');
        
        final response = await http.get(
          Uri.parse('$baseUrl/api/universities'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));
        
        print('✅ $baseUrl répond avec status: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('📊 Réponse: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');
        }
      } catch (e) {
        print('❌ $baseUrl inaccessible: $e');
      }
    }
    
    // Test spécifique pour les images
    print('\n🖼️ Test des images...');
    List<String> imageUrls = [
      'http://192.168.11.101:8000/storage/images/582124d2-3f85-47f1-800f-12fc1e015ab9.png',
      'http://192.168.11.101:8000/storage/images/fc582a90-48a6-40d9-8db5-41703729f85f.png',
      'http://192.168.11.101:8000/storage/universities/1735222978_IMG_0096.JPG',
      'http://127.0.0.1:8000/storage/images/582124d2-3f85-47f1-800f-12fc1e015ab9.png',
      'http://10.0.2.2:8000/storage/images/582124d2-3f85-47f1-800f-12fc1e015ab9.png',
    ];
    
    for (String imageUrl in imageUrls) {
      try {
        print('🖼️ Test image: $imageUrl');
        
        // Test HEAD first
        final headResponse = await http.head(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));
        
        print('✅ Image HEAD: ${headResponse.statusCode}');
        print('📄 Content-Type: ${headResponse.headers['content-type']}');
        print('📏 Content-Length: ${headResponse.headers['content-length']}');
        
        // Si HEAD fonctionne, essayer GET pour vérifier le contenu
        if (headResponse.statusCode == 200) {
          final getResponse = await http.get(Uri.parse(imageUrl))
              .timeout(const Duration(seconds: 10));
          
          print('📥 GET Status: ${getResponse.statusCode}');
          print('📊 Body Length: ${getResponse.bodyBytes.length}');
          print('🎯 Content-Type GET: ${getResponse.headers['content-type']}');
          
          // Vérifier les premiers bytes pour voir si c'est vraiment une image
          if (getResponse.bodyBytes.isNotEmpty) {
            List<int> firstBytes = getResponse.bodyBytes.take(10).toList();
            print('🔢 Premiers bytes: $firstBytes');
            
            // Vérifier les signatures d'images
            if (firstBytes.length >= 3) {
              if (firstBytes[0] == 0xFF && firstBytes[1] == 0xD8 && firstBytes[2] == 0xFF) {
                print('✅ Signature JPEG détectée');
              } else if (firstBytes.length >= 8 && 
                        firstBytes[0] == 0x89 && firstBytes[1] == 0x50 && 
                        firstBytes[2] == 0x4E && firstBytes[3] == 0x47) {
                print('✅ Signature PNG détectée');
              } else {
                print('⚠️ Signature d\'image non reconnue');
              }
            }
          }
        }
        
        print(''); // Ligne vide pour séparer
        
      } catch (e) {
        print('❌ Image inaccessible: $e');
        print(''); // Ligne vide pour séparer
      }
    }
  }
}
