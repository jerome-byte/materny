import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/patient_provider.dart';
import '../../../data/models/rendez_vous_model.dart';

class PatientHistoryScreen extends StatelessWidget {
  const PatientHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text("Historique Médical", style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<PatientProvider>(
        builder: (context, provider, child) {
          // Filtrer UNIQUEMENT les Effectués ET non masqués (le provider le fait déjà, mais on double-check)
          final historyRdvs = provider.patientRdvs.where((r) => r.statut == 'EFFECTUE').toList();

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          if (historyRdvs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: AppTheme.textTert),
                  const SizedBox(height: 12),
                  Text("Aucun historique disponible", style: AppTheme.bodyMd),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyRdvs.length,
            itemBuilder: (ctx, i) {
              final rdv = historyRdvs[i];
              return _HistoryCard(
                rdv: rdv,
                onDelete: () {
                  // Confirmation
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Supprimer ?"),
                      content: const Text("Voulez-vous supprimer ce rendez-vous de votre historique ? (L'agent gardera une copie)."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Annuler"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.hideRdvForPatient(rdv.id);
                          },
                          child: const Text("Supprimer"),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RendezVousModel rdv;
  final VoidCallback onDelete;
  const _HistoryCard({required this.rdv, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.successSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rdv.typeRdv,
                  style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy').format(rdv.dateHeure),
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSec),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}