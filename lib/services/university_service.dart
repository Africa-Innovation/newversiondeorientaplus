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
              priceByLevel: {
                'licence': 150000, // Plus cher que la moyenne
                'master': 200000,
                'doctorat': 300000,
              },
            ),
            Specialty(
              id: 'spec_chirurgie',
              name: 'Chirurgie',
              description: 'Spécialisation en chirurgie générale',
              specificRequirements: [
                'Diplôme de médecine',
                'Concours de spécialisation',
              ],
              priceByLevel: {
                'master': 250000, // Très cher pour spécialisation
                'doctorat': 350000,
              },
            ),
            Specialty(
              id: 'spec_pharmacie',
              name: 'Pharmacie',
              description: 'Formation en sciences pharmaceutiques',
              specificRequirements: ['BAC série D ou C', 'Concours d\'entrée'],
              priceByLevel: {
                'licence': 120000, // Moins cher que médecine
                'master': 180000,
                'doctorat': 250000,
              },
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
              priceByLevel: {
                'licence': 50000, // Moins cher, filière classique
                'master': 70000,
              },
            ),
            Specialty(
              id: 'spec_reseaux',
              name: 'Réseaux et Télécommunications',
              description: 'Spécialisation en infrastructure réseau',
              priceByLevel: {
                'licence': 65000, // Plus cher, équipements spécialisés
                'master': 85000,
              },
            ),
            Specialty(
              id: 'spec_cybersecurite',
              name: 'Cybersécurité',
              description:
                  'Formation en sécurité informatique et protection des données',
              priceByLevel: {
                'licence': 75000, // Le plus cher, haute technologie
                'master': 100000,
              },
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
      imageUrl: 'https://images.unsplash.com/photo-1607013251379-e6eecfffe234?w=800&h=600&fit=crop&crop=faces',
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
      imageUrl: 'https://images.unsplash.com/photo-1580537659466-0a9bfa916a54?w=800&h=600&fit=crop&crop=faces',
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
      imageUrl: 'https://images.unsplash.com/photo-1541829070764-84a7d30dd3f3?w=800&h=600&fit=crop&crop=faces',
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

    University(
      id: 'univ_004',
      name: 'École Nationale d\'Administration et de Magistrature',
      city: 'Ouagadougou',
      type: 'public',
      programs: [
        Program(
          id: 'prog_administration',
          name: 'Administration Publique',
          description: 'Formation des cadres de l\'administration publique',
          priceByLevel: {
            'licence': 150000,
            'master': 200000,
          },
          durationYears: 3,
          admissionRequirements: [
            'BAC toutes séries',
            'Concours d\'entrée',
            'Aptitudes physiques',
          ],
          career: 'Fonctionnaire, Administrateur, Gestionnaire public, Magistrat',
          specialties: [
            Specialty(
              id: 'spec_admin_generale',
              name: 'Administration Générale',
              description: 'Formation polyvalente en administration',
              specificRequirements: [
                'Aptitudes organisationnelles',
                'Sens des responsabilités',
              ],
            ),
            Specialty(
              id: 'spec_magistrature',
              name: 'Magistrature',
              description: 'Formation des magistrats',
              priceByLevel: {
                'master': 250000,
              },
              specificRequirements: [
                'Licence en Droit',
                'Concours très sélectif',
              ],
            ),
          ],
        ),
      ],
      website: 'https://www.enam.gov.bf',
      contact: '+226 25 32 48 95',
      email: 'contact@enam.gov.bf',
      address: 'Secteur 4, Ouagadougou',
      imageUrl: 'https://images.unsplash.com/photo-1589578527966-fdac0f44566c?w=800&h=600&fit=crop&crop=faces',
      description: 'École prestigieuse formant les cadres de l\'administration et de la justice.',
      generalAdmissionRequirements: [
        'Réussite au concours d\'entrée',
        'Aptitudes physiques et morales',
      ],
      hasScholarships: true,
      hasAccommodation: true,
      latitude: 12.3676,
      longitude: -1.5144,
    ),

    University(
      id: 'univ_005',
      name: 'Institut Supérieur d\'Informatique et de Gestion',
      city: 'Ouagadougou',
      type: 'private',
      programs: [
        Program(
          id: 'prog_informatique',
          name: 'Sciences Informatiques',
          description: 'Formation complète en informatique et nouvelles technologies',
          priceByLevel: {
            'licence': 650000,
            'master': 850000,
          },
          durationYears: 3,
          admissionRequirements: [
            'BAC série C, D ou F',
            'Bases en mathématiques',
          ],
          career: 'Développeur, Ingénieur logiciel, Chef de projet IT, Administrateur réseau',
          specialties: [
            Specialty(
              id: 'spec_dev_logiciel',
              name: 'Développement Logiciel',
              description: 'Conception et développement d\'applications',
              specificRequirements: [
                'Logique algorithmique',
                'Créativité technique',
              ],
            ),
            Specialty(
              id: 'spec_reseaux',
              name: 'Réseaux et Télécommunications',
              description: 'Administration et sécurité des réseaux',
              priceByLevel: {
                'licence': 600000,
                'master': 800000,
              },
              specificRequirements: [
                'Intérêt pour les infrastructures',
                'Rigueur technique',
              ],
            ),
          ],
        ),
        Program(
          id: 'prog_gestion_moderne',
          name: 'Gestion et Management Digital',
          description: 'Management moderne avec outils numériques',
          priceByLevel: {
            'licence': 550000,
            'master': 750000,
          },
          durationYears: 3,
          admissionRequirements: [
            'BAC toutes séries',
            'Créativité et sens commercial',
          ],
          career: 'Community manager, Expert e-commerce, Consultant digital',
          specialties: [
            Specialty(
              id: 'spec_marketing_digital',
              name: 'Marketing Digital',
              description: 'Stratégies marketing à l\'ère numérique',
              specificRequirements: [
                'Créativité',
                'Maîtrise des réseaux sociaux',
              ],
            ),
          ],
        ),
      ],
      website: 'https://www.isig-bf.com',
      contact: '+226 25 37 42 18',
      email: 'info@isig-bf.com',
      address: 'Zone du Bois, Ouagadougou',
      imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800&h=600&fit=crop&crop=faces',
      description: 'Institut moderne spécialisé dans les technologies de l\'information et la gestion digitale.',
      generalAdmissionRequirements: [
        'BAC selon filière',
        'Motivation pour le numérique',
        'Capacité de financement',
      ],
      hasScholarships: false,
      hasAccommodation: false,
      latitude: 12.3892,
      longitude: -1.4875,
    ),
  ];

  // Obtenir toutes les universités (données statiques uniquement)
  Future<List<University>> getAllUniversities() async {
    // Simulation d'un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Retourner seulement les universités codées en dur
    final allUniversities = [..._universitiesData];
    
    // Debug
    print('📚 Universités codées en dur: ${_universitiesData.length}');
    print('📋 Total universités: ${allUniversities.length}');
    
    return allUniversities;
  }

  // Obtenir une université par ID (données statiques uniquement)
  Future<University?> getUniversityById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Chercher dans les universités codées en dur
    try {
      return _universitiesData.firstWhere((univ) => univ.id == id);
    } catch (e) {
      return null; // Pas trouvé
    }
  }

  // Rechercher des universités par nom, ville ou domaine (données statiques uniquement)
  Future<List<University>> searchUniversities(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) return getAllUniversities();

    final queryLower = query.toLowerCase();
    final allUniversities = await getAllUniversities();
    
    return allUniversities.where((univ) {
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
