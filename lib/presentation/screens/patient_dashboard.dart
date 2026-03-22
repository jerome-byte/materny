import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';
import '../../../data/models/rendez_vous_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../data/services/supabase_service.dart';

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

          // ── Content ────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (_rdvs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available_outlined, size: 48, color: AppTheme.textTert),
                    const SizedBox(height: 12),
                    Text("Aucun rendez-vous programmé", style: AppTheme.bodyMd),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final rdv = _rdvs[i];
                    return _RdvPatientCard(rdv: rdv);
                  },
                  childCount: _rdvs.length,
                ),
              ),
            ),
        ],
      ),
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