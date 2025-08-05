import 'package:flutter/material.dart';
import '../services/university_service.dart';

class FilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterDialog({
    super.key,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  final UniversityService _universityService = UniversityService();
  
  String? _selectedCity;
  String? _selectedType;
  String? _selectedDomain;
  double? _maxBudget;
  double _maxDistance = 50.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ville
                    _buildSectionTitle('Ville'),
                    _buildDropdown(
                      value: _selectedCity,
                      hint: 'Toutes les villes',
                      items: _universityService.getAllCities(),
                      onChanged: (value) => setState(() => _selectedCity = value),
                    ),

                    const SizedBox(height: 20),

                    // Type d'établissement
                    _buildSectionTitle('Type d\'établissement'),
                    _buildDropdown(
                      value: _selectedType,
                      hint: 'Tous les types',
                      items: _universityService.getAllTypes(),
                      onChanged: (value) => setState(() => _selectedType = value),
                      labelMapper: (type) {
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
                      },
                    ),

                    const SizedBox(height: 20),

                    // Domaine
                    _buildSectionTitle('Domaine'),
                    _buildDropdown(
                      value: _selectedDomain,
                      hint: 'Tous les domaines',
                      items: _universityService.getAllDomains(),
                      onChanged: (value) => setState(() => _selectedDomain = value),
                    ),

                    const SizedBox(height: 20),

                    // Budget maximum
                    _buildSectionTitle('Budget maximum (FCFA/an)'),
                    _buildBudgetSlider(),

                    const SizedBox(height: 20),

                    // Distance maximum
                    _buildSectionTitle('Distance maximum (km)'),
                    _buildDistanceSlider(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCity = null;
                        _selectedType = null;
                        _selectedDomain = null;
                        _maxBudget = null;
                        _maxDistance = 50.0;
                      });
                      widget.onClearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Effacer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters({
                        'city': _selectedCity,
                        'type': _selectedType,
                        'domain': _selectedDomain,
                        'maxBudget': _maxBudget,
                        'maxDistance': _maxDistance,
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    String Function(String)? labelMapper,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(labelMapper?.call(item) ?? item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _maxBudget ?? 500000,
          min: 0,
          max: 500000,
          divisions: 10,
          label: _maxBudget != null 
              ? '${_maxBudget!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA'
              : 'Illimité',
          onChanged: (value) {
            setState(() {
              _maxBudget = value == 500000 ? null : value;
            });
          },
        ),
        Text(
          _maxBudget != null 
              ? 'Maximum: ${_maxBudget!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA/an'
              : 'Pas de limite de budget',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Slider(
          value: _maxDistance,
          min: 5,
          max: 200,
          divisions: 39,
          label: '${_maxDistance.toInt()} km',
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
        Text(
          'Rayon: ${_maxDistance.toInt()} km',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
