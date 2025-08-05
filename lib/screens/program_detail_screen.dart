import 'package:flutter/material.dart';
import '../models/program.dart';

class ProgramDetailScreen extends StatelessWidget {
  final Program program;
  final String universityName;
  final String specialtyName;

  const ProgramDetailScreen({
    super.key,
    required this.program,
    required this.universityName,
    required this.specialtyName,
  });

  @override
  Widget build(BuildContext context) {
    // Trouver la filière spécifique
    final specialty = program.specialties.firstWhere(
      (s) => s.name == specialtyName,
      orElse: () => program.specialties.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.name,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              universityName,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec niveau et prix
            _buildHeader(context, specialty),
            
            const SizedBox(height: 24),
            
            // Description
            _buildSection(
              'Description',
              Text(
                program.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informations pratiques
            _buildSection(
              'Informations pratiques',
              _buildPracticalInfo(specialty),
            ),
            
            const SizedBox(height: 24),

            // Conditions d'admission
            if (program.admissionRequirements.isNotEmpty) ...[
              _buildSection(
                'Conditions d\'admission',
                _buildAdmissionRequirements(),
              ),
              const SizedBox(height: 24),
            ],

            // Débouchés
            if (program.career != null && program.career!.isNotEmpty) ...[
              _buildSection(
                'Débouchés professionnels',
                _buildCareerProspects(),
              ),
              const SizedBox(height: 24),
            ],

            // Bouton d'action
            _buildActionButton(context),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Specialty specialty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Niveau disponible',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialtyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${program.durationYears} an(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Coûts pour ${specialty.name}:',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Utiliser les prix de la filière spécifique si disponibles, sinon ceux du programme
                ...(specialty.priceByLevel?.entries ?? program.priceByLevel.entries).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          specialty.getLevelLabel(entry.key),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          specialty.getFormattedPrice(entry.key) ?? 
                              program.getFormattedPrice(entry.key) ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildPracticalInfo(Specialty specialty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.school,
            'Niveaux disponibles',
            (specialty.availableLevels.isNotEmpty 
                ? specialty.availableLevels 
                : program.availableLevels).join(", "),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.schedule,
            'Durée',
            '${program.durationYears} année(s)',
          ),
          const SizedBox(height: 12),
          
          // Coûts détaillés par niveau pour cette filière spécifique
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coûts pour ${specialty.name}:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ...(specialty.priceByLevel?.entries ?? program.priceByLevel.entries).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${specialty.getLevelLabel(entry.key)}: ${specialty.getFormattedPrice(entry.key) ?? program.getFormattedPrice(entry.key)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdmissionRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: program.admissionRequirements.map((requirement) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    requirement,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCareerProspects() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.work, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Métiers possibles',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Afficher les carrières depuis le champ career (string)
          if (program.career != null && program.career!.isNotEmpty)
            Text(
              program.career!,
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showInterestDialog(context);
        },
        icon: const Icon(Icons.info_outline),
        label: const Text(
          'Plus d\'informations',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showInterestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Intéressé par ce programme ?'),
        content: const Text(
          'Pour plus d\'informations détaillées sur ce programme, nous vous recommandons de contacter directement l\'université.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Ici on pourrait ajouter une fonctionnalité pour contacter l'université
            },
            child: const Text('Contacter l\'université'),
          ),
        ],
      ),
    );
  }
}
