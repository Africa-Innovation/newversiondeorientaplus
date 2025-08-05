import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/university.dart';

class UniversityCard extends StatelessWidget {
  final University university;
  final double? userLatitude;
  final double? userLongitude;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final bool isFavorite;

  const UniversityCard({
    super.key,
    required this.university,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.isFavorite,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    final distance = (userLatitude != null && userLongitude != null)
        ? university.distanceFrom(userLatitude!, userLongitude!)
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'université
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: university.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: university.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.school,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.school,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête avec nom et bouton favori
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          university.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoriteToggle,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Informations de base
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        university.city,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Type d'établissement
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(university.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(university.type),
                          style: TextStyle(
                            color: _getTypeColor(university.type),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Programmes principaux (max 3)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: university.programs
                        .take(3)
                        .map((program) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                program.name,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 11,
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  if (university.programs.length > 3) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+${university.programs.length - 3} autre(s) programme(s)',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Prix et informations pratiques
                  Row(
                    children: [
                      if (university.minPrice != null) ...[
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        Text(
                          university.priceRange,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Prix non communiqué',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (university.hasScholarships)
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.green[600],
                        ),
                      if (university.hasAccommodation) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.home,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'public':
        return Colors.green;
      case 'private':
        return Colors.blue;
      case 'formation_center':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Privé';
      case 'formation_center':
        return 'Centre de formation';
      default:
        return type;
    }
  }
}
