import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patient_model.dart';
import '../../../data/models/rendez_vous_model.dart';
import '../../providers/patient_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'add_patient_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final PatientModel patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<RendezVousModel> _patientRdvs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientRdvs();
  }

  Future<void> _loadPatientRdvs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final rdvs = await Provider.of<PatientProvider>(context, listen: false)
          .fetchPatientRdvs(widget.patient.id);
      if (mounted) {
        setState(() {
          _patientRdvs = rdvs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFemme = widget.patient.genre == 'F';
    final activeRdvs = _patientRdvs
        .where((r) => r.statut == 'PLANIFIE' || r.statut == 'MANQUE')
        .toList();
    final historyRdvs =
        _patientRdvs.where((r) => r.statut == 'EFFECTUE').toList();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor:Color.fromARGB(255, 74, 144, 226),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${widget.patient.prenom} ${widget.patient.nom}',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromARGB(255, 74, 144, 226),Color.fromARGB(255, 38, 114, 201)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isFemme
                                    ? const Color(0xFFFCEAF0)
                                    : const Color(0xFFE6F0FB),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                isFemme
                                    ? Icons.pregnant_woman_rounded
                                    : Icons.child_care_rounded,
                                color: isFemme
                                    ? const Color(0xFFD4649A)
                                    : const Color(0xFF4A90D9),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.patient.prenom} ${widget.patient.nom}',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isFemme ? 'Femme Enceinte' : 'Enfant',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Info card ──────────────────────────────────────────
                  _SectionCard(
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: widget.patient.telephone,
                      ),
                      if (widget.patient.contactUrgenceNom != null &&
                          widget.patient.contactUrgenceNom!.isNotEmpty) ...[
                        Divider(height: 1, color: AppTheme.border, indent: 44),
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Personne de confiance',
                          value: widget.patient.contactUrgenceNom!,
                        ),
                        if (widget.patient.contactUrgenceTelephone != null) ...[
                          Divider(height: 1, color: AppTheme.border, indent: 44),
                          _InfoRow(
                            icon: Icons.phone_in_talk_outlined,
                            label: 'Tél. garant',
                            value: widget.patient.contactUrgenceTelephone!,
                            valueColor: AppTheme.success,
                          ),
                        ],
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Actions ──────────────────────────────────────────────
                  if (isFemme) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.child_care_rounded, size: 18),
                        label: const Text('Enregistrer une naissance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4649A),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddPatientScreen(mother: widget.patient),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Terminer',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppTheme.success,
                          bgColor: AppTheme.successSoft,
                          onTap: () async {
                            await Provider.of<PatientProvider>(context,
                                    listen: false)
                                .updatePatientStatus(
                                    widget.patient.id, 'TERMINE');
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Abandon',
                          icon: Icons.block_rounded,
                          color: AppTheme.warning,
                          bgColor: AppTheme.warningSoft,
                          onTap: () async {
                            await Provider.of<PatientProvider>(context,
                                    listen: false)
                                .updatePatientStatus(
                                    widget.patient.id, 'ABANDON');
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Planifier un rendez-vous'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                      ),
                      onPressed: () => Navigator.pushNamed(
                          context, '/add-rdv',
                          arguments: widget.patient),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Active RDVs ──────────────────────────────────────────
                  _SectionHeader(
                      title: 'Rendez-vous actifs',
                      count: activeRdvs.length),
                  const SizedBox(height: 10),

                  if (activeRdvs.isEmpty)
                    _EmptySection(message: 'Aucun rendez-vous actif')
                  else
                    ...activeRdvs.map((rdv) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RdvDetailCard(
                            rdv: rdv,
                            onDone: () async {
                              await Provider.of<PatientProvider>(context,
                                      listen: false)
                                  .markRdvAsDone(rdv.id);
                              _loadPatientRdvs();
                            },
                          ),
                        )),

                  const SizedBox(height: 24),

                  // ── History ──────────────────────────────────────────────
                  _SectionHeader(
                      title: 'Historique',                     
                      count: historyRdvs.length),
                  const SizedBox(height: 10),

                  if (historyRdvs.isEmpty)
                    _EmptySection(message: 'Aucun historique disponible')
                  else
                    ...historyRdvs.map((rdv) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _HistoryCard(rdv: rdv),
                        )),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: children),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color:AppTheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.labelSm),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
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
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTheme.sectionLabel,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVar,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSec,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty Section ─────────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTheme.bodyMd,
      ),
    );
  }
}

// ── RDV Detail Card ────────────────────────────────────────────────────────────
class _RdvDetailCard extends StatelessWidget {
  final RendezVousModel rdv;
  final VoidCallback onDone;
  const _RdvDetailCard({required this.rdv, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final isManque = rdv.statut == 'MANQUE';
    final color = isManque ? AppTheme.danger : AppTheme.warning;
    final bgColor = isManque ? AppTheme.dangerSoft : AppTheme.warningSoft;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isManque ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                color: color,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rdv.typeRdv,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(rdv.dateHeure),
                    style: AppTheme.labelSm,
                  ),
                  const SizedBox(height: 3),
                  _StatusChip(status: rdv.statut),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDone,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.successSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppTheme.success, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final RendezVousModel rdv;
  const _HistoryCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.successSoft,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.success, size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rdv.typeRdv,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Effectué le ${DateFormat('dd/MM/yyyy').format(rdv.dateHeure)}',
                    style: AppTheme.labelSm,
                  ),
                  if (rdv.nomVaccin != null && rdv.nomVaccin!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        rdv.nomVaccin!,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _StatusChip(status: rdv.statut),
          ],
        ),
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;

    switch (status) {
      case 'EFFECTUE':
        color = AppTheme.success;
        bg = AppTheme.successSoft;
        label = 'Effectué';
        break;
      case 'MANQUE':
        color = AppTheme.danger;
        bg = AppTheme.dangerSoft;
        label = 'Manqué';
        break;
      default:
        color = AppTheme.warning;
        bg = AppTheme.warningSoft;
        label = 'Planifié';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
