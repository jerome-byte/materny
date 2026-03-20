import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/patient_provider.dart';
import '../../data/models/rendez_vous_model.dart';
import '../../core/theme/app_theme.dart';

class PerdusDeVueScreen extends StatefulWidget {
  const PerdusDeVueScreen({super.key});

  @override
  State<PerdusDeVueScreen> createState() => _PerdusDeVueScreenState();
}

class _PerdusDeVueScreenState extends State<PerdusDeVueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: FutureBuilder<List<RendezVousModel>>(
        future: Provider.of<PatientProvider>(context, listen: false)
            .fetchPerdusDeVueDetails(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.danger,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  'Perdus de vue',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (snapshot.hasData)
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${snapshot.data!.length} patients',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              // ── Content ──────────────────────────────────────────────
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.danger),
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.successSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded,
                              color: AppTheme.success, size: 30),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun patient perdu de vue',
                          style: AppTheme.displayTitle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tous les patients suivent leurs rendez-vous.',
                          style: AppTheme.bodyMd,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final rdv = snapshot.data![i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PerdusCard(
                            rdv: rdv,
                            onCall: () => _showCallOptions(rdv),
                            onDone: () async {
                              await Provider.of<PatientProvider>(context,
                                      listen: false)
                                  .markRdvAsDone(rdv.id);
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PerdusDeVueScreen(),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showCallOptions(RendezVousModel rdv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Qui souhaitez-vous appeler ?',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _CallOption(
              icon: Icons.person_rounded,
              iconColor: const Color(0xFFD4649A),
              bgColor: const Color(0xFFFCEAF0),
              name: rdv.patientPrenom,
              phone: rdv.patientTelephone,
              onTap: () => _makeCall(rdv.patientTelephone),
            ),
            if (rdv.patientContactUrgenceTel != null &&
                rdv.patientContactUrgenceTel!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _CallOption(
                icon: Icons.people_rounded,
                iconColor: AppTheme.warning,
                bgColor: AppTheme.warningSoft,
                name: rdv.patientContactUrgenceNom ?? 'Garant',
                phone: rdv.patientContactUrgenceTel!,
                onTap: () => _makeCall(rdv.patientContactUrgenceTel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible d'appeler $phoneNumber")),
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }
}

// ── Perdus Card ───────────────────────────────────────────────────────────────
class _PerdusCard extends StatelessWidget {
  final RendezVousModel rdv;
  final VoidCallback onCall;
  final VoidCallback onDone;

  const _PerdusCard({
    required this.rdv,
    required this.onCall,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.danger.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Alert icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.dangerSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.danger, size: 22),
            ),
            const SizedBox(width: 12),

            // Info
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
                    'RDV prévu le ${DateFormat('dd/MM/yyyy').format(rdv.dateHeure)}',
                    style: AppTheme.labelSm,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerSoft,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      rdv.typeRdv,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                _IconAction(
                  icon: Icons.phone_rounded,
                  color: AppTheme.primaryMid,
                  bgColor: const Color(0xFFE6F0EA),
                  onTap: onCall,
                ),
                const SizedBox(height: 6),
                _IconAction(
                  icon: Icons.check_rounded,
                  color: AppTheme.success,
                  bgColor: AppTheme.successSoft,
                  onTap: onDone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon Action ───────────────────────────────────────────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Call Option ───────────────────────────────────────────────────────────────
class _CallOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String name;
  final String phone;
  final VoidCallback onTap;

  const _CallOption({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.name,
    required this.phone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(phone, style: AppTheme.labelSm),
                ],
              ),
            ),
            Icon(Icons.phone_forwarded_rounded, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}
