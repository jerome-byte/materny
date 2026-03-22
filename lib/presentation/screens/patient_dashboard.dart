import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';
import '../../../data/models/rendez_vous_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../data/services/supabase_service.dart';
import 'patient_history_screen.dart';
import 'patient_missed_screen.dart';
import 'patient_profile_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  List<RendezVousModel> _rdvs = [];
  bool _isLoading = true;
  String _patientName = "Patiente";

  @override
  void initState() {
    super.initState();
    _loadData();
    _saveDeviceToken();
  }

  Future<void> _saveDeviceToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (token != null && userId != null) {
        await SupabaseService.client
            .from('patients')
            .update({'device_token': token})
            .eq('user_id', userId);
      }
    } catch (e) {
      debugPrint("Erreur token: $e");
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await Provider.of<PatientProvider>(context, listen: false).fetchMyRdvs();
    
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final patientInfo = await SupabaseService.client
            .from('patients')
            .select('prenom')
            .eq('user_id', user.id)
            .single();
        if (mounted) {
          setState(() => _patientName = patientInfo['prenom'] ?? "Patiente");
        }
      }
    } catch (e) {
      // Erreur silencieuse
    }

    if (mounted) {
      setState(() {
        _rdvs = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () async {
                  await SupabaseService.client.auth.signOut();
                  Navigator.pushReplacementNamed(context, '/patient-login');
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D3324), Color(0xFF0A2A1C)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue,',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        Text(
                          _patientName,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
                        // --- NOUVEAU : Section Statistiques ---
              if (!_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('VUE D\'ENSEMBLE', style: AppTheme.sectionLabel),
                        const SizedBox(height: 12),
                        
                        // Rangée 1
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<PatientProvider>(
                                builder: (ctx, p, _) => _StatCard(
                                  label: 'Total RDV',
                                  value: p.patientTotalRdvs.toString(),
                                  icon: Icons.calendar_today_outlined,
                                  color: AppTheme.primary,
                                  bgColor: const Color(0xFFEAF2EE),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Consumer<PatientProvider>(
                                builder: (ctx, p, _) => _StatCard(
                                  label: 'Effectués',
                                  value: p.patientRdvEffectues.toString(),
                                  icon: Icons.check_circle_outline_rounded,
                                  color: AppTheme.success,
                                  bgColor: AppTheme.successSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Rangée 2
                        Row(
                          children: [
                            Expanded(
                              child: Consumer<PatientProvider>(
                                builder: (ctx, p, _) => _StatCard(
                                  label: 'À venir',
                                  value: p.patientRdvAVenir.toString(),
                                  icon: Icons.schedule_outlined,
                                  color: AppTheme.warning,
                                  bgColor: AppTheme.warningSoft,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Consumer<PatientProvider>(
                                builder: (ctx, p, _) => _StatCard(
                                  label: 'Manqués',
                                  value: p.patientRdvManques.toString(),
                                  icon: Icons.cancel_outlined,
                                  color: AppTheme.danger,
                                  bgColor: AppTheme.dangerSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // ------------------------------------
                   // ── Content ────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else ...[
            // --- Titre de la section ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),               
                 child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RENDEZ-VOUS À VENIR', style: AppTheme.sectionLabel),
                    // Affiche le nombre
                    Text('${_rdvs.where((r) => r.statut == 'PLANIFIE' && r.dateHeure.isAfter(DateTime.now())).length} prévus', style: AppTheme.labelSm),
                  ],
                ),
              ),
            ),

            // --- Liste des RDV (Filtrée) ---
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: Builder(
                builder: (context) {
                  // Filtrer les RDV à venir
                  final upcomingRdvs = _rdvs.where((r) => 
                    r.statut == 'PLANIFIE' && r.dateHeure.isAfter(DateTime.now())
                  ).toList();

                  if (upcomingRdvs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_available_outlined, size: 40, color: AppTheme.textTert),
                            const SizedBox(height: 10),
                            Text("Aucun rendez-vous à venir", style: AppTheme.bodyMd),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final rdv = upcomingRdvs[i];
                        return _RdvPatientCard(rdv: rdv);
                      },
                      childCount: upcomingRdvs.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
              // NOUVEAU : Bouton Historique en bas
           // Barre de navigation basse (Story + Missed)
        persistentFooterButtons: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [

               // --- 2. Accueil (Dashboard) ---
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Rafraîchir les données si on clique sur Accueil
                    _loadData();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        "Accueil",
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- Bouton Story ---
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientHistoryScreen()),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        "Story",
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Bouton Missed ---
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PatientMissedScreen()),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
                      const SizedBox(height: 2),
                      Text(
                        "Missed",
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               // --- 4. Profil ---
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen())),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_rounded, color: AppTheme.textSec, size: 24),
                      const SizedBox(height: 2),
                      Text("Profil", style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSec)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
    );
  }
}

// ── Widget Card RDV Patient ────────────────────────────────────────
class _RdvPatientCard extends StatelessWidget {
  final RendezVousModel rdv;
  const _RdvPatientCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    final isVaccination = rdv.typeRdv == 'VACCINATION';
    final color = isVaccination ? AppTheme.success : AppTheme.warning;
    final bgColor = isVaccination ? AppTheme.successSoft : AppTheme.warningSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isVaccination ? Icons.vaccines_rounded : Icons.pregnant_woman_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rdv.typeRdv,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy à HH:mm').format(rdv.dateHeure),
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSec),
                ),
                if (rdv.nomVaccin != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rdv.nomVaccin!,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rdv.statut == 'EFFECTUE' ? AppTheme.successSoft : AppTheme.surfaceVar,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rdv.statut == 'EFFECTUE' ? 'Effectué' : 'À venir',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: rdv.statut == 'EFFECTUE' ? AppTheme.success : AppTheme.textSec,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ── Widget Stat Card Patient ────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: color.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}