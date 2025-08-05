import 'package:geolocator/geolocator.dart';
import '../models/university.dart';
import '../models/program.dart';

class UniversityService {
  // Données simulées des universités burkinabè avec la nouvelle structure Programme → Filières
  static final List<University> _universitiesData = [
    University(
      id: 'univ_001',
      name: 'Université Joseph Ki-Zerbo',
      city: 'Ouagadougou',
      type: 'public',
      programs: [
        Program(
          id: 'prog_medecine',
          name: 'Sciences de la Santé',
          description:
              'Formation complète dans le domaine médical et paramédical',
          specialties: [
            Specialty(
              id: 'spec_medecine',
              name: 'Médecine Générale',
              description: 'Formation pour devenir médecin généraliste',
              specificRequirements: ['BAC série D ou C', 'Concours d\'entrée'],
            ),
            Specialty(
              id: 'spec_chirurgie',
              name: 'Chirurgie',
              description: 'Spécialisation en chirurgie générale',
              specificRequirements: [
                'Diplôme de médecine',
                'Concours de spécialisation',
              ],
            ),
            Specialty(
              id: 'spec_pharmacie',
              name: 'Pharmacie',
              description: 'Formation en sciences pharmaceutiques',
              specificRequirements: ['BAC série D ou C', 'Concours d\'entrée'],
            ),
          ],
          priceByLevel: {
            'licence': 75000,
            'master': 100000,
            'doctorat': 125000,
          },
          durationYears: 7,
          admissionRequirements: [
            'BAC série D ou C',
            'Concours d\'entrée',
            'Visite médicale',
          ],
          career: 'Médecin, Chirurgien, Pharmacien, Chercheur en santé',
        ),
        Program(
          id: 'prog_droit',
          name: 'Sciences Juridiques et Politiques',
          description: 'Formation complète en droit et sciences politiques',
          specialties: [
            Specialty(
              id: 'spec_droit_prive',
              name: 'Droit Privé',
              description: 'Spécialisation en droit privé et des affaires',
            ),
            Specialty(
              id: 'spec_droit_public',
              name: 'Droit Public',
              description: 'Spécialisation en droit public et administratif',
            ),
            Specialty(
              id: 'spec_sciences_politiques',
              name: 'Sciences Politiques',
              description:
                  'Formation en sciences politiques et relations internationales',
            ),
          ],
          priceByLevel: {'licence': 45000, 'master': 65000, 'doctorat': 85000},
          durationYears: 5,
          admissionRequirements: ['BAC toutes séries', 'Moyenne >= 10'],
          career: 'Avocat, Magistrat, Juriste d\'entreprise, Diplomate',
        ),
        Program(
          id: 'prog_informatique',
          name: 'Sciences et Technologies',
          description: 'Formation en informatique et technologies numériques',
          specialties: [
            Specialty(
              id: 'spec_informatique',
              name: 'Informatique Fondamentale',
              description:
                  'Formation en développement et systèmes informatiques',
            ),
            Specialty(
              id: 'spec_reseaux',
              name: 'Réseaux et Télécommunications',
              description: 'Spécialisation en infrastructure réseau',
            ),
            Specialty(
              id: 'spec_cybersecurite',
              name: 'Cybersécurité',
              description:
                  'Formation en sécurité informatique et protection des données',
            ),
          ],
          priceByLevel: {'licence': 60000, 'master': 80000},
          durationYears: 5,
          admissionRequirements: [
            'BAC série D ou C',
            'Notions en mathématiques',
          ],
          career: 'Développeur, Ingénieur réseau, Expert en cybersécurité',
        ),
      ],
      website: 'https://www.ujkz.bf',
      contact: '+226 25 30 70 64',
      email: 'info@ujkz.bf',
      address: '03 BP 7021 Ouagadougou 03',
      imageUrl: 'https://example.com/ujkz.jpg',
      description:
          'La plus ancienne université du Burkina Faso, offrant une formation de qualité dans de nombreux domaines.',
      generalAdmissionRequirements: [
        'BAC toutes séries selon filière',
        'Dossier complet',
        'Frais d\'inscription',
      ],
      hasScholarships: true,
      hasAccommodation: true,
      latitude: 12.3714,
      longitude: -1.5197,
    ),

    University(
      id: 'univ_002',
      name: 'Université Polytechnique de Bobo-Dioulasso',
      city: 'Bobo-Dioulasso',
      type: 'public',
      programs: [
        Program(
          id: 'prog_ingenierie',
          name: 'Ingénierie et Technologies',
          description:
              'Formation d\'ingénieurs dans diverses spécialités techniques',
          specialties: [
            Specialty(
              id: 'spec_genie_civil',
              name: 'Génie Civil',
              description: 'Formation en construction et travaux publics',
            ),
            Specialty(
              id: 'spec_genie_electrique',
              name: 'Génie Électrique',
              description: 'Formation en électrotechnique et électronique',
            ),
            Specialty(
              id: 'spec_genie_mecanique',
              name: 'Génie Mécanique',
              description: 'Formation en mécanique et maintenance industrielle',
            ),
          ],
          priceByLevel: {'licence': 70000, 'master': 90000},
          durationYears: 5,
          admissionRequirements: [
            'BAC série D ou C',
            'Concours d\'entrée',
            'Excellentes notes en maths',
          ],
          career: 'Ingénieur, Chef de projet, Consultant technique',
        ),
        Program(
          id: 'prog_agriculture',
          name: 'Sciences Agricoles et Environnementales',
          description:
              'Formation en agriculture moderne et développement durable',
          specialties: [
            Specialty(
              id: 'spec_agronomie',
              name: 'Agronomie',
              description: 'Science de la production végétale',
            ),
            Specialty(
              id: 'spec_elevage',
              name: 'Élevage et Productions Animales',
              description: 'Formation en zootechnie et productions animales',
            ),
            Specialty(
              id: 'spec_environnement',
              name: 'Environnement et Développement Durable',
              description: 'Gestion des ressources naturelles',
            ),
          ],
          priceByLevel: {'licence': 55000, 'master': 75000},
          durationYears: 5,
          admissionRequirements: [
            'BAC toutes séries',
            'Intérêt pour l\'agriculture',
          ],
          career:
              'Agronome, Conseiller agricole, Expert en développement rural',
        ),
      ],
      website: 'https://www.univ-bobo.bf',
      contact: '+226 20 98 03 45',
      email: 'contact@univ-bobo.bf',
      address: '01 BP 1091 Bobo-Dioulasso 01',
      imageUrl: 'https://example.com/upb.jpg',
      description:
          'Université technique spécialisée dans les formations d\'ingénierie et d\'agriculture.',
      generalAdmissionRequirements: [
        'BAC scientifique ou technique',
        'Concours selon filière',
      ],
      hasScholarships: true,
      hasAccommodation: true,
      latitude: 11.1784,
      longitude: -4.2970,
    ),

    University(
      id: 'univ_003',
      name: 'Institut Supérieur de Commerce (ISC)',
      city: 'Ouagadougou',
      type: 'private',
      programs: [
        Program(
          id: 'prog_commerce',
          name: 'Sciences Commerciales et de Gestion',
          description: 'Formation complète en management et commerce',
          specialties: [
            Specialty(
              id: 'spec_marketing',
              name: 'Marketing et Communication',
              description:
                  'Stratégies marketing et communication d\'entreprise',
            ),
            Specialty(
              id: 'spec_finance',
              name: 'Finance et Comptabilité',
              description: 'Gestion financière et comptabilité d\'entreprise',
            ),
            Specialty(
              id: 'spec_rh',
              name: 'Ressources Humaines',
              description:
                  'Gestion du personnel et développement organisationnel',
            ),
            Specialty(
              id: 'spec_entrepreneuriat',
              name: 'Entrepreneuriat',
              description: 'Création et gestion d\'entreprise',
            ),
          ],
          priceByLevel: {'licence': 450000, 'master': 550000},
          durationYears: 5,
          admissionRequirements: [
            'BAC toutes séries',
            'Entretien de motivation',
            'Dossier scolaire',
          ],
          career: 'Manager, Entrepreneur, Consultant, Responsable commercial',
        ),
      ],
      website: 'https://www.isc-bf.com',
      contact: '+226 25 36 28 70',
      email: 'info@isc-bf.com',
      address: 'Secteur 4, Ouagadougou',
      imageUrl: 'https://example.com/isc.jpg',
      description:
          'École de commerce privée reconnue, formant les futurs leaders du monde des affaires.',
      generalAdmissionRequirements: [
        'BAC toutes séries',
        'Capacité de financement',
        'Motivation',
      ],
      hasScholarships: false,
      hasAccommodation: false,
      latitude: 12.3581,
      longitude: -1.5339,
    ),
  ];

  // Obtenir toutes les universités
  Future<List<University>> getAllUniversities() async {
    // Simulation d'un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_universitiesData);
  }

  // Obtenir une université par ID
  Future<University?> getUniversityById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _universitiesData.firstWhere((univ) => univ.id == id);
    } catch (e) {
      return null;
    }
  }

  // Rechercher des universités par nom, ville ou domaine
  Future<List<University>> searchUniversities(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) return getAllUniversities();

    final queryLower = query.toLowerCase();
    return _universitiesData.where((univ) {
      return univ.name.toLowerCase().contains(queryLower) ||
          univ.city.toLowerCase().contains(queryLower) ||
          univ.programs.any(
            (program) =>
                program.name.toLowerCase().contains(queryLower) ||
                program.specialties.any(
                  (spec) => spec.name.toLowerCase().contains(queryLower),
                ),
          );
    }).toList();
  }

  // Filtrer les universités
  Future<List<University>> filterUniversities({
    String? city,
    String? type,
    String? domain,
    double? maxBudget,
    double? maxDistance,
    double? userLatitude,
    double? userLongitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    List<University> filtered = List.from(_universitiesData);

    if (city != null && city.isNotEmpty) {
      filtered = filtered
          .where((univ) => univ.city.toLowerCase() == city.toLowerCase())
          .toList();
    }

    if (type != null && type.isNotEmpty) {
      filtered = filtered.where((univ) => univ.type == type).toList();
    }

    if (domain != null && domain.isNotEmpty) {
      filtered = filtered
          .where(
            (univ) => univ.programs.any(
              (program) =>
                  program.name.toLowerCase().contains(domain.toLowerCase()),
            ),
          )
          .toList();
    }

    if (maxBudget != null) {
      filtered = filtered.where((univ) {
        final minPrice = univ.minPrice;
        return minPrice == null || minPrice <= maxBudget;
      }).toList();
    }

    if (maxDistance != null && userLatitude != null && userLongitude != null) {
      filtered = filtered.where((univ) {
        final distance = univ.distanceFrom(userLatitude, userLongitude);
        return distance <= maxDistance;
      }).toList();
    }

    return filtered;
  }

  // Obtenir la position actuelle de l'utilisateur
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Obtenir le nom de la ville à partir des coordonnées (simulation)
  Future<String?> getCityFromCoordinates() async {
    // Dans une vraie app, on utiliserait un service de géocodage inversé
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulation basée sur les coordonnées des principales villes du Burkina
    // Ici on retourne simplement "Ouagadougou" comme exemple
    return "Ouagadougou";
  }

  // Obtenir toutes les villes disponibles
  List<String> getAllCities() {
    return _universitiesData.map((univ) => univ.city).toSet().toList()..sort();
  }

  // Obtenir tous les types d'établissements
  List<String> getAllTypes() {
    return _universitiesData.map((univ) => univ.type).toSet().toList();
  }

  // Obtenir tous les domaines d'études
  List<String> getAllDomains() {
    final domains = <String>{};
    for (final univ in _universitiesData) {
      for (final program in univ.programs) {
        domains.add(program.name);
      }
    }
    return domains.toList()..sort();
  }
}
