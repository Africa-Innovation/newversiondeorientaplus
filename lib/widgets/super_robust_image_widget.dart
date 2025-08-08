import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SuperRobustImageWidget extends StatelessWidget {
  final String imageUrl;
  final String universityName;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SuperRobustImageWidget({
    super.key,
    required this.imageUrl,
    required this.universityName,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  String _getCorrectImageUrl(String originalUrl) {
    print('🔧 Super Robust - Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('   URL entrée: $originalUrl');

    // Si c'est une URL externe (unsplash, etc.), pas de modification
    if (originalUrl.startsWith('https://')) {
      print('   ℹ️ URL externe - pas de correction');
      return originalUrl;
    }

    // Si c'est une URL localhost et qu'on est sur mobile
    if (!kIsWeb && (originalUrl.contains('127.0.0.1') || originalUrl.contains('localhost'))) {
      String correctedUrl = originalUrl
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');
      print('   📱 Mobile - correction: $correctedUrl');
      return correctedUrl;
    }

    print('   ℹ️ Web - pas de correction nécessaire');
    return originalUrl;
  }

  Future<ui.Image?> _loadImageFromBytes(Uint8List bytes) async {
    try {
      print('🎨 Tentative de décodage manuel de l\'image...');
      
      final ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
        allowUpscaling: false,
      );
      
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      print('✅ Image décodée manuellement: ${frameInfo.image.width}x${frameInfo.image.height}');
      
      return frameInfo.image;
    } catch (e) {
      print('❌ Échec décodage manuel: $e');
      return null;
    }
  }

  Future<Widget> _buildImageWidget() async {
    try {
      final String correctedUrl = _getCorrectImageUrl(imageUrl);
      
      print('🖼️ Super Robust Image pour $universityName:');
      print('   URL: $correctedUrl');

      // Télécharger l'image
      final response = await http.get(
        Uri.parse(correctedUrl),
        headers: {
          'Accept': 'image/*',
          'User-Agent': 'Flutter/OrientaPlus',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Téléchargement réussi: ${response.bodyBytes.length} bytes');
        
        // Essayer le décodage manuel
        final ui.Image? decodedImage = await _loadImageFromBytes(response.bodyBytes);
        
        if (decodedImage != null) {
          return CustomPaint(
            painter: ImagePainter(decodedImage, fit),
            child: Container(
              width: width,
              height: height,
            ),
          );
        } else {
          // Si le décodage manuel échoue, essayer Image.memory avec gestion d'erreur
          return Image.memory(
            response.bodyBytes,
            fit: fit,
            width: width,
            height: height,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Image.memory échoue aussi: $error');
              return _buildErrorWidget('Décodage impossible');
            },
          );
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return _buildErrorWidget('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur générale: $e');
      return _buildErrorWidget('Erreur de chargement');
    }
  }

  Widget _buildErrorWidget(String message) {
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
            message,
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _buildImageWidget(),
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

        if (snapshot.hasData) {
          return snapshot.data!;
        }

        return _buildErrorWidget('Chargement échoué');
      },
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final BoxFit fit;

  ImagePainter(this.image, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: fit,
    );
  }

  @override
  bool shouldRepaint(ImagePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.fit != fit;
  }
}
