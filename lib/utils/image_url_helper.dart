import 'package:flutter/foundation.dart';

/// Utilitaire pour corriger les URLs d'images selon la plateforme
class ImageUrlHelper {
  /// Corrige l'URL de l'image pour la plateforme actuelle
  static String getCorrectImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    
    // Debug: toujours afficher la plateforme
    print('🔧 URL Helper - Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('   URL entrée: $imageUrl');
    
    // Si c'est une URL externe (https), pas de modification
    if (imageUrl.startsWith('https://')) {
      print('   ℹ️ URL externe - pas de correction');
      return imageUrl;
    }
    
    // Sur mobile physique, remplacer les adresses locales par l'IP réelle
    if (!kIsWeb) {
      String correctedUrl = imageUrl;
      
      // Remplacer l'ancienne IP 192.168.11.121 par la nouvelle 192.168.11.101
      if (correctedUrl.contains('192.168.11.121')) {
        correctedUrl = correctedUrl.replaceAll('192.168.11.121', '192.168.11.101');
        print('   ✅ Remplacement 192.168.11.121 → 192.168.11.101');
      }
      
      // Remplacer 127.0.0.1 par l'IP réelle
      if (correctedUrl.contains('127.0.0.1')) {
        correctedUrl = correctedUrl.replaceAll('127.0.0.1', '192.168.11.101');
        print('   ✅ Remplacement 127.0.0.1 → 192.168.11.101');
      }
      
      // Remplacer localhost par l'IP réelle
      if (correctedUrl.contains('localhost')) {
        correctedUrl = correctedUrl.replaceAll('localhost', '192.168.11.101');
        print('   ✅ Remplacement localhost → 192.168.11.101');
      }
      
      print('   URL corrigée: $correctedUrl');
      return correctedUrl;
    }
    
    print('   ℹ️ Web - pas de correction nécessaire');
    return imageUrl;
  }
}
