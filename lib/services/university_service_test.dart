import 'package:geolocator/geolocator.dart';
import '../models/university.dart';
import '../models/program.dart';

class UniversityService {
  // Version simplifiée pour test
  Future<List<University>> getAllUniversities() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }

  Future<Position?> getCurrentLocation() async {
    return null;
  }

  Future<String?> getCityFromCoordinates() async {
    return "Ouagadougou";
  }

  List<String> getAllCities() {
    return ['Ouagadougou', 'Bobo-Dioulasso'];
  }

  List<String> getAllTypes() {
    return ['public', 'private'];
  }

  List<String> getAllDomains() {
    return ['Sciences de la Santé', 'Droit'];
  }
}
