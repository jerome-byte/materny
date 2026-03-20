import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/patient_provider.dart';
import '../../../data/models/patient_model.dart';
import '../../../core/theme/app_theme.dart';
import 'patient_detail_screen.dart';
import 'add_patient_screen.dart';

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientModel> _filteredPatients = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Provider.of<PatientProvider>(context, listen: false).fetchPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients(String query, List<PatientModel> all) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredPatients = all;
      });
    } else {
      setState(() {
        _isSearching = true;
        _filteredPatients = all
            .where((p) =>
                p.prenom.toLowerCase().contains(query.toLowerCase()) ||
                p.nom.toLowerCase().contains(query.toLowerCase()) ||
                p.telephone.contains(query))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Consumer<PatientProvider>(
        builder: (context, provider, _) {
          final displayList =
              _isSearching ? _filteredPatients : provider.patients;

          return CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.primary,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'Patients',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${provider.patients.length} patients',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    color: AppTheme.primary,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher (nom, prénom, tél)…',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppTheme.textTert,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppTheme.textTert),
                        suffixIcon: _isSearching
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: AppTheme.textTert),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterPatients('', provider.patients);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryLight, width: 1.5),
                        ),
                      ),
                      onChanged: (v) =>
                          _filterPatients(v, provider.patients),
                    ),
                  ),
                ),
              ),

              // ── Loading ────────────────────────────────────────────────
              if (provider.isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )

              // ── Empty ──────────────────────────────────────────────────
              else if (displayList.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSearching
                              ? Icons.search_off_rounded
                              : Icons.people_outline_rounded,
                          size: 48,
                          color: AppTheme.textTert,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isSearching
                              ? 'Aucun résultat trouvé'
                              : 'Aucun patient enregistré',
                          style: AppTheme.bodyMd,
                        ),
                      ],
                    ),
                  ),
                )

              // ── List ───────────────────────────────────────────────────
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final patient = displayList[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PatientCard(
                            patient: patient,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PatientDetailScreen(patient: patient),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: displayList.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_patients',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddPatientScreen()),
        ),
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }
}

// ── Patient Card ───────────────────────────────────────────────────────────────
class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFemme = patient.genre == 'F';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isFemme
                      ? const Color(0xFFFCEAF0)
                      : const Color(0xFFE6F0FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isFemme
                      ? Icons.pregnant_woman_rounded
                      : Icons.child_care_rounded,
                  color: isFemme
                      ? const Color(0xFFD4649A)
                      : const Color(0xFF4A90D9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${patient.prenom} ${patient.nom}',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 12, color: AppTheme.textTert),
                        const SizedBox(width: 4),
                        Text(patient.telephone, style: AppTheme.labelSm),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isFemme
                                ? const Color(0xFFFCEAF0)
                                : const Color(0xFFE6F0FB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFemme ? 'Femme' : 'Enfant',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isFemme
                                  ? const Color(0xFFD4649A)
                                  : const Color(0xFF4A90D9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppTheme.textTert),
            ],
          ),
        ),
      ),
    );
  }
}
