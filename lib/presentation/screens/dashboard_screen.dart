import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../../core/theme/app_theme.dart';
import 'patients/add_patient_screen.dart';
import 'perdus_de_vue_screen.dart';
import 'reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PatientProvider>(context, listen: false).reset();
      Provider.of<PatientProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Consumer<PatientProvider>(
        builder: (context, provider, _) {
          if (provider.errorMessage != null) {
            return _buildError(provider);
          }
          if (provider.isLoading) {
            return _buildSkeleton();
          }
          return _buildContent(context, provider);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dashboard',
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddPatientScreen())),
        backgroundColor: const Color(0xFF4A90E2),
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: Text(
          'Nouveau patient',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PatientProvider provider) {
    return RefreshIndicator(
      onRefresh: () => provider.fetchDashboardData(),
      color: AppTheme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            collapsedHeight: 60,
            pinned: true,
            backgroundColor: const Color(0xFF4A90E2),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_special_outlined,
                    color: Colors.white, size: 22),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined,
                    color: Colors.white, size: 22),
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromARGB(255, 74, 144, 226),Color.fromARGB(255, 32, 102, 182)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Bonjour,',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: Colors.white
                                      .withValues(alpha: 0.55),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                auth.agentName ?? 'Agent',
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.local_hospital_outlined,
                                      size: 13,
                                      color: Color.fromARGB(255, 228, 125, 219)
                                          .withValues(alpha: 0.8)),
                                  const SizedBox(width: 5),
                                  Text(
                                    auth.hospitalName ?? 'Centre de Santé',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      color: Colors.white
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Stats Row ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VUE D\'ENSEMBLE',
                      style: AppTheme.sectionLabel),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Patients',
                          value: provider.totalPatients.toString(),
                          icon: Icons.people_outline_rounded,
                          color: AppTheme.primary,
                          bgColor: const Color(0xFFEAF2EE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: "RDV aujourd'hui",
                          value: provider.rdvAujourdhui.toString(),
                          icon: Icons.calendar_today_outlined,
                          color: AppTheme.warning,
                          bgColor: AppTheme.warningSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const PerdusDeVueScreen())),
                    child: _StatCard(
                      label: 'Perdus de vue',
                      value: provider.perdusDeVue.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.danger,
                      bgColor: AppTheme.dangerSoft,
                      fullWidth: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Voir la liste',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.danger,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios,
                              size: 11, color: AppTheme.danger),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Upcoming RDV ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RENDEZ-VOUS À VENIR', style: AppTheme.sectionLabel),
                  Text(
                    '${provider.rdvDuJour.length} prévus',
                    style: AppTheme.labelSm,
                  ),
                ],
              ),
            ),
          ),

          if (provider.rdvDuJour.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _EmptyState(
                  icon: Icons.event_available_outlined,
                  message: 'Aucun rendez-vous prévu prochainement',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final rdv = provider.rdvDuJour[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RdvCard(
                        rdv: rdv,
                        onDone: () => Provider.of<PatientProvider>(ctx,
                                listen: false)
                            .markRdvAsDone(rdv.id),
                      ),
                    );
                  },
                  childCount: provider.rdvDuJour.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(PatientProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.danger, size: 30),
            ),
            const SizedBox(height: 16),
            Text('Erreur de chargement', style: AppTheme.displayTitle),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchDashboardData(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: AppTheme.primary),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShimmerBox(height: 80, radius: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool fullWidth;
  final Widget? trailing;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.fullWidth = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── RDV Card ───────────────────────────────────────────────────────────────────
class _RdvCard extends StatelessWidget {
  final dynamic rdv;
  final VoidCallback onDone;

  const _RdvCard({required this.rdv, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final bool isPlanifie = rdv.statut == 'PLANIFIE';
    final bool isManque = rdv.statut == 'MANQUE';

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isManque
                    ? AppTheme.dangerSoft
                    : isPlanifie
                        ? AppTheme.warningSoft
                        : AppTheme.successSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isManque
                    ? Icons.warning_amber_rounded
                    : isPlanifie
                        ? Icons.schedule_rounded
                        : Icons.check_circle_outline,
                color: isManque
                    ? AppTheme.danger
                    : isPlanifie
                        ? AppTheme.warning
                        : AppTheme.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rdv.patientPrenom} ${rdv.patientNom}',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${rdv.typeRdv}  ·  ${DateFormat('dd/MM HH:mm').format(rdv.dateHeure)}',
                    style: AppTheme.labelSm,
                  ),
                  if (rdv.nomVaccin != null && rdv.nomVaccin!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
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

            // Action
            if (isPlanifie || isManque)
              GestureDetector(
                onTap: onDone,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.successSoft,
                    borderRadius: BorderRadius.circular(11),
                    border:
                        Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppTheme.success, size: 20),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.successSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Fait',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppTheme.textTert),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMd,
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Box ────────────────────────────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;

  const _ShimmerBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVar,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
