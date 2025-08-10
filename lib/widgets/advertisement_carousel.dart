import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/image_url_helper.dart';

class AdvertisementCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final Duration autoPlayInterval;
  final VoidCallback? onAdTap;

  const AdvertisementCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.onAdTap,
  });

  @override
  State<AdvertisementCarousel> createState() => _AdvertisementCarouselState();
}

class _AdvertisementCarouselState extends State<AdvertisementCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Démarrer l'auto-play seulement s'il y a plus d'une image
    if (widget.imageUrls.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvertisementCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si la liste des URLs a changé, redémarrer le carousel
    if (oldWidget.imageUrls != widget.imageUrls) {
      print('🔄 Carousel: Mise à jour détectée - ${oldWidget.imageUrls.length} -> ${widget.imageUrls.length} images');
      
      // Arrêter l'ancien timer
      _timer?.cancel();
      
      // Réinitialiser la page courante si nécessaire
      if (widget.imageUrls.isEmpty) {
        _currentPage = 0;
      } else if (_currentPage >= widget.imageUrls.length) {
        _currentPage = 0;
        // Retourner à la première page si on était au-delà
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
      
      // Redémarrer l'auto-play avec la nouvelle liste
      if (widget.imageUrls.length > 1) {
        _startAutoPlay();
      }
    }
  }

  void _startAutoPlay() {
    // Arrêter l'ancien timer s'il existe
    _timer?.cancel();
    
    // Ne démarrer que s'il y a plus d'une image
    if (widget.imageUrls.length <= 1) {
      return;
    }
    
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (mounted && widget.imageUrls.isNotEmpty) {
        int nextPage = (_currentPage + 1) % widget.imageUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
    
    print('▶️ Carousel: Auto-play démarré pour ${widget.imageUrls.length} images');
  }

  void _stopAutoPlay() {
    _timer?.cancel();
  }

  void _resumeAutoPlay() {
    if (widget.imageUrls.length > 1) {
      _startAutoPlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Aucune publicité disponible',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Carrousel d'images
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: widget.onAdTap,
                  onTapDown: (_) => _stopAutoPlay(), // Arrêter l'auto-play quand l'utilisateur interagit
                  onTapUp: (_) => _resumeAutoPlay(), // Reprendre l'auto-play après interaction
                  onTapCancel: () => _resumeAutoPlay(),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: Builder(
                      builder: (context) {
                        final imageUrl = widget.imageUrls[index];
                        
                        print('🖼️ Advertisement Image (Firebase):');
                        print('   Original: $imageUrl');
                        
                        // Toutes les images de publicité viennent de Firebase/Laravel
                        // Utiliser ImageUrlHelper pour corriger l'URL
                        final correctedUrl = ImageUrlHelper.getCorrectImageUrl(imageUrl);
                        print('   Corrigée: $correctedUrl');
                        
                        return Image.network(
                          correctedUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Erreur chargement publicité: $error');
                            print('   URL: $correctedUrl');
                            return Container(
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Publicité non disponible',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ Publicité chargée avec succès');
                              return child;
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: Colors.blue[600],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Indicateurs de points (si plus d'une image)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Badge "Publicité" en haut à droite
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Pub',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
