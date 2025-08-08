import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class RobustImageWidget extends StatelessWidget {
  final String imageUrl;
  final String universityName;
  final BoxFit fit;
  final double? width;
  final double? height;

  const RobustImageWidget({
    super.key,
    required this.imageUrl,
    required this.universityName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  String _getCorrectImageUrl(String originalUrl) {
    print('🔧 Robust Image - Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('   URL entrée: $originalUrl');

    // Si c'est une URL externe (unsplash, etc.), pas de modification
    if (originalUrl.startsWith('https://')) {
      print('   ℹ️ URL externe - pas de correction');
      return originalUrl;
    }

    // Si c'est une URL localhost et qu'on est sur mobile
    if (!kIsWeb && (originalUrl.contains('127.0.0.1') || originalUrl.contains('localhost'))) {
      String correctedUrl = originalUrl
          .replaceAll('127.0.0.1', '192.168.11.121')
          .replaceAll('localhost', '192.168.11.121');
      print('   📱 Mobile - correction: $correctedUrl');
      return correctedUrl;
    }

    print('   ℹ️ Web - pas de correction nécessaire');
    return originalUrl;
  }

  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      print('📥 Téléchargement direct de l\'image: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'image/*',
          'User-Agent': 'Flutter/OrientaPlus',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Image téléchargée: ${response.bodyBytes.length} bytes');
        print('📄 Content-Type: ${response.headers['content-type']}');
        
        // Vérifier que c'est bien une image
        if (response.bodyBytes.isNotEmpty) {
          List<int> firstBytes = response.bodyBytes.take(10).toList();
          print('🔢 Premiers bytes: $firstBytes');
          
          // Vérifier les signatures
          if (firstBytes.length >= 3) {
            bool isValidImage = false;
            
            if ((firstBytes[0] == 0xFF && firstBytes[1] == 0xD8)) { // JPEG
              print('✅ Signature JPEG détectée');
              isValidImage = true;
            } else if (firstBytes.length >= 8 && firstBytes[0] == 0x89 && 
                      firstBytes[1] == 0x50 && firstBytes[2] == 0x4E && firstBytes[3] == 0x47) { // PNG
              print('✅ Signature PNG détectée');
              isValidImage = true;
            } else if (firstBytes.length >= 6 && firstBytes[0] == 0x47 && 
                      firstBytes[1] == 0x49 && firstBytes[2] == 0x46) { // GIF
              print('✅ Signature GIF détectée');
              isValidImage = true;
            } else if (firstBytes.length >= 12 && firstBytes[4] == 0x66 && 
                      firstBytes[5] == 0x74 && firstBytes[6] == 0x79 && firstBytes[7] == 0x70) { // WebP
              print('✅ Signature WebP détectée');
              isValidImage = true;
            } else {
              print('⚠️ Signature d\'image non reconnue');
              // Essayer quand même, parfois Flutter peut décoder même sans signature reconnue
              isValidImage = true;
            }
            
            if (isValidImage) {
              return response.bodyBytes;
            }
          }
        }
      } else {
        print('❌ Échec téléchargement: ${response.statusCode}');
        print('📄 Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur téléchargement: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String correctedUrl = _getCorrectImageUrl(imageUrl);
    
    print('🖼️ Robust Image URL pour $universityName:');
    print('   Original: $imageUrl');
    print('   Corrigée: $correctedUrl');

    return FutureBuilder<Uint8List?>(
      future: _downloadImageBytes(correctedUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Erreur Image.memory pour $universityName: $error');
              print('📊 Taille des données: ${snapshot.data!.length} bytes');
              print('🔍 StackTrace: $stackTrace');
              
              // Essayer de sauvegarder les données pour debug
              try {
                final firstBytes = snapshot.data!.take(20).toList();
                print('🔢 20 premiers bytes: $firstBytes');
              } catch (e) {
                print('❌ Impossible de lire les bytes: $e');
              }
              
              return _buildErrorWidget();
            },
          );
        }

        // Si le téléchargement direct échoue, essayer avec CachedNetworkImage comme fallback
        return CachedNetworkImage(
          imageUrl: correctedUrl,
          fit: fit,
          width: width,
          height: height,
          placeholder: (context, url) => Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) {
            print('❌ Erreur CachedNetworkImage fallback pour $universityName: $error');
            return _buildErrorWidget();
          },
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.broken_image,
            size: 30,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            'Image indisponible',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
