import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/patient_provider.dart';
import '../../core/theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PatientProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Consumer<PatientProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final total = provider.rdvEffectues +
              provider.rdvManques +
              provider.rdvPlanifies;

          final successRate = total > 0
              ? ((provider.rdvEffectues / total) * 100).toStringAsFixed(0)
              : '0';

          return CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                 backgroundColor:Color.fromARGB(255, 74, 144, 226),
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Text(
                  'Statistiques',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$total RDV au total',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Success rate hero ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color.fromARGB(255, 51, 114, 185),Color.fromARGB(255, 39, 112, 196)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TAUX DE RÉUSSITE',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white
                                        .withValues(alpha: 0.55),
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$successRate%',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 52,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider.rdvEffectues} effectués sur $total',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _CircularRateIndicator(
                            rate: total > 0
                                ? provider.rdvEffectues / total
                                : 0.0,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Quick stats row ────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Effectués',
                            value: provider.rdvEffectues.toString(),
                            color:   const Color(0xFF1A237E),
                            bgColor: AppTheme.successSoft,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Manqués',
                            value: provider.rdvManques.toString(),
                            color: AppTheme.danger,
                            bgColor: AppTheme.dangerSoft,
                            icon: Icons.cancel_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStatCard(
                            label: 'Planifiés',
                            value: provider.rdvPlanifies.toString(),
                            color: AppTheme.warning,
                            bgColor: AppTheme.warningSoft,
                            icon: Icons.schedule_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Chart section ──────────────────────────────────
                    Text('RÉPARTITION DES RDV', style: AppTheme.sectionLabel),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: total == 0
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(Icons.bar_chart_rounded,
                                      size: 40,
                                      color: AppTheme.textTert),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucune donnée disponible',
                                    style: AppTheme.bodyMd,
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 55,
                                      pieTouchData: PieTouchData(
                                        touchCallback: (event, response) {
                                          setState(() {
                                            if (!event
                                                    .isInterestedForInteractions ||
                                                response == null ||
                                                response.touchedSection ==
                                                    null) {
                                              _touchedIndex = -1;
                                            } else {
                                              _touchedIndex = response
                                                  .touchedSection!
                                                  .touchedSectionIndex;
                                            }
                                          });
                                        },
                                      ),
                                      sections: [
                                        _buildPieSection(
                                          value: provider.rdvEffectues
                                              .toDouble(),
                                          color:Color.fromARGB(255, 31, 44, 185),
                                          index: 0,
                                        ),
                                        _buildPieSection(
                                          value:
                                              provider.rdvManques.toDouble(),
                                          color: AppTheme.danger,
                                          index: 1,
                                        ),
                                        _buildPieSection(
                                          value: provider.rdvPlanifies
                                              .toDouble(),
                                          color: AppTheme.warning,
                                          index: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Legend
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _ChartLegend(
                                        color: const Color(0xFF1A237E),
                                        label: 'Effectués',
                                        count: provider.rdvEffectues),
                                    _ChartLegend(
                                        color: AppTheme.danger,
                                        label: 'Manqués',
                                        count: provider.rdvManques),
                                    _ChartLegend(
                                        color: AppTheme.warning,
                                        label: 'Planifiés',
                                        count: provider.rdvPlanifies),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PieChartSectionData _buildPieSection({
    required double value,
    required Color color,
    required int index,
  }) {
    final isTouched = index == _touchedIndex;
    return PieChartSectionData(
      value: value,
      color: color,
      radius: isTouched ? 70 : 58,
      title: value > 0 ? value.toInt().toString() : '',
      titleStyle: GoogleFonts.dmSans(
        fontSize: isTouched ? 18 : 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

// ── Mini Stat Card ────────────────────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
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
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.75),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Chart Legend Item ─────────────────────────────────────────────────────────
class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _ChartLegend({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSec,
              ),
            ),
            Text(
              count.toString(),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Circular Rate Indicator ───────────────────────────────────────────────────
class _CircularRateIndicator extends StatelessWidget {
  final double rate;
  const _CircularRateIndicator({required this.rate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: rate,
            strokeWidth: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
          Text(
            '${(rate * 100).toInt()}%',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
