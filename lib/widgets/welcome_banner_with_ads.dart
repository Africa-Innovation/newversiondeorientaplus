import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'advertisement_carousel.dart';

class WelcomeBannerWithAds extends StatelessWidget {
  final List<String> advertisementImages;
  final VoidCallback? onAdTap;

  const WelcomeBannerWithAds({
    super.key,
    this.advertisementImages = const [],
    this.onAdTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Obtenir les publicités du provider
        final advertisements = provider.advertisements;
        
        // Extraire les URLs des images des publicités FIREBASE uniquement
        final List<String> adImageUrls = advertisements.isNotEmpty 
            ? advertisements.map((ad) => ad.imageUrl).toList()
            : []; // Pas de fallback assets - utiliser uniquement Firebase

        return Container(
          margin: const EdgeInsets.all(16),
          child: Stack(
            children: [
              // Carrousel publicitaire en arrière-plan
              AdvertisementCarousel(
                imageUrls: adImageUrls,
                height: 200,
                autoPlayInterval: const Duration(seconds: 5),
                onAdTap: onAdTap,
              ),
          
          // Overlay avec dégradé pour améliorer la lisibilité
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          
          // Message de bienvenue par-dessus
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur OrientaPlus!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez les meilleures universités et centres de formation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton d'action optionnel en bas
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () {
                    // Action à définir - par exemple ouvrir la recherche
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Commencez votre recherche !'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.blue[700],
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Explorer',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
              ),
            ],
          ),
        );
      },
    );
  }
}