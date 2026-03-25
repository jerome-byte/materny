import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/supabase_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isLoading = true;
  // Infos Mère
  String _prenom = "";
  String _nom = "";
  String _telephone = "";
   String _genre = "";
  // Liste des enfants
  List<Map<String, dynamic>> _children = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      // On récupère TOUS les profils liés à ce compte (Mère + Enfants)
      final response = await SupabaseService.client
          .from('patients')
          .select('id, prenom, nom, telephone, genre')
          .eq('user_id', userId);

      if (mounted) {
        // On sépare la mère des enfants
        final motherData = response.firstWhere(
          (p) => p['genre'] == 'F', 
          orElse: () => <String, dynamic>{}
        );

        final childrenData = response.where((p) => p['genre'] == 'M').toList();

        setState(() {
          if (motherData.isNotEmpty) {
            _prenom = motherData['prenom'] ?? 'Inconnu';
            _nom = motherData['nom'] ?? 'Inconnu';
            _telephone = motherData['telephone'] ?? 'Non renseigné';
            _genre = 'Femme Enceinte'; // On définit le genre
          }
          _children = childrenData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text("Mon Profil", style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _genre == 'Femme Enceinte' ? Icons.pregnant_woman_rounded : Icons.child_care_rounded,
                      size: 50,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Nom Complet
                  Text(
                    "$_prenom $_nom",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                                    // Genre Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      // Correction : Utilisation de couleurs standard
                      color: _genre == 'Femme Enceinte' 
                          ? Colors.pink.shade50 
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _genre,
                      style: GoogleFonts.dmSans(
                        color: _genre == 'Femme Enceinte' 
                            ? Colors.pink.shade700 
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Infos Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.person_outline_rounded,
                          label: "Prénom",
                          value: _prenom,
                        ),
                        Divider(height: 1, indent: 56, color: AppTheme.border),
                        _InfoTile(
                          icon: Icons.badge_outlined,
                          label: "Nom",
                          value: _nom,
                        ),
                        Divider(height: 1, indent: 56, color: AppTheme.border),
                        _InfoTile(
                          icon: Icons.phone_outlined,
                          label: "Téléphone",
                          value: _telephone,
                        ),
                      ],
                    ),
                                             
                  ),
                   // --- NOUVEAU : Section Enfant
                if (_children.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    _SectionLabel(label: "MES ENFANTS"),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: _children.map((child) {
                          return _ChildTile(
                            prenom: child['prenom'] ?? 'Inconnu',
                            nom: child['nom'] ?? '',
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),

                  // Bouton Déconnexion
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: const BorderSide(color: AppTheme.danger, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      onPressed: () async {
                        await SupabaseService.client.auth.signOut();
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/patient-login', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text("Déconnexion", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textTert, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textTert)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSec,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  final String prenom;
  final String nom;

  const _ChildTile({required this.prenom, required this.nom});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.child_care_rounded, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "$prenom $nom",
              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}