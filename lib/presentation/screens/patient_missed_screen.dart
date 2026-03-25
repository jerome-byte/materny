import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';
import '../../../data/models/rendez_vous_model.dart';

class PatientMissedScreen extends StatelessWidget {
  const PatientMissedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text("Rendez-vous Manqués", style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppTheme.danger, // Couleur rouge pour l'alerte
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<PatientProvider>(
        builder: (context, provider, child) {
          // Filtrer : MANQUE ou PLANIFIE avec date passée
          final missedRdvs = provider.patientRdvs.where((r) => 
            r.statut == 'MANQUE' || (r.statut == 'PLANIFIE' && r.dateHeure.isBefore(DateTime.now()))
          ).toList();

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.danger));
          }

          if (missedRdvs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text("Aucun rendez-vous manqué", style: AppTheme.displayTitle),
                  const SizedBox(height: 8),
                  Text("Bravo ! Vous avez respecté tous vos RDV.", style: AppTheme.bodyMd),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missedRdvs.length,
            itemBuilder: (ctx, i) {
              final rdv = missedRdvs[i];
              return _MissedCard(rdv: rdv);
            },
          );
        },
      ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  final RendezVousModel rdv;
  const _MissedCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    // On récupère le nom (Mère ou Enfant)
    final patientName = "${rdv.patientPrenom} ${rdv.patientNom}".trim();
    final displayTitle = patientName.isNotEmpty ? patientName : "Patient";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.danger.withValues(alpha: 0.05),
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
              color: AppTheme.dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- NOUVEAU : On affiche le nom du patient (Mère ou Enfant) ---
                Text(
                  displayTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(height: 2),
                // -----------------------------------------------------------------
                Text(
                  rdv.typeRdv,
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy à HH:mm').format(rdv.dateHeure),
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSec),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.dangerSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Manqué",
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
  }
}