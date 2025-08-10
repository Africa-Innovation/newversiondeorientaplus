import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../utils/image_url_helper.dart';

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

  Future<Uint8List?> _downloadImageBytes(String url) async {
    try {
      print('📥 Téléchargement direct de l\'image: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Accept': 'image/*',
              'User-Agent': 'Flutter/OrientaPlus',
              'Cache-Control': 'no-cache',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Téléchargement réussi: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur téléchargement: $e');
      return null;
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            universityName,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    final String correctedUrl = ImageUrlHelper.getCorrectImageUrl(imageUrl);
    
    print('📷 Admin List Advertisement Image:');
    print('   Original: $imageUrl');
    print('   Corrigée: $correctedUrl');

    return CachedNetworkImage(
      imageUrl: correctedUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('❌ Erreur chargement admin pub: $error');
        return FutureBuilder<Uint8List?>(
          future: _downloadImageBytes(correctedUrl),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorWidget();
                },
              );
            }

            return _buildErrorWidget();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildImageContent(),
    );
  }
}
