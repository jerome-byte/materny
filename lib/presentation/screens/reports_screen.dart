import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../providers/patient_provider.dart';
import '../../data/models/patient_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PatientModel> _terminatedList = [];
  List<PatientModel> _abandonedList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<PatientProvider>(context, listen: false);
    _terminatedList = await provider.fetchArchivedPatients('TERMINE');
    _abandonedList = await provider.fetchArchivedPatients('ABANDON');
    setState(() => _isLoading = false);
  }

  Future<void> _generateListPdf(
      List<PatientModel> patients, String title) async {
    try {
      if (patients.isEmpty) return;
      final provider = Provider.of<PatientProvider>(context, listen: false);
      final pdf = pw.Document();
      List<pw.Widget> allContent = [];

      allContent.add(pw.Center(
        child: pw.Text(
          'RAPPORT GLOBAL: $title',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
      ));
      allContent.add(pw.SizedBox(height: 30));

      for (var patient in patients) {
        final rdvs = await provider.fetchPatientRdvs(patient.id);
        allContent.add(pw.Container(
          width: double.infinity,
          color: title == 'TERMINE' ? PdfColors.green : PdfColors.orange,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            '${patient.prenom} ${patient.nom} - STATUT: $title',
            style: pw.TextStyle(
                fontSize: 16,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold),
          ),
        ));
        allContent.add(pw.SizedBox(height: 10));
        allContent.add(pw.Text('Téléphone: ${patient.telephone}'));
        allContent.add(pw.Text(
            'Genre: ${patient.genre == 'F' ? 'Femme' : 'Enfant'}'));
        if (patient.contactUrgenceNom != null)
          allContent.add(pw.Text(
              'Contact: ${patient.contactUrgenceNom} (${patient.contactUrgenceTelephone})'));
        allContent.add(pw.SizedBox(height: 15));
        allContent.add(pw.Text('Historique des Rendez-vous:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
        allContent.add(pw.SizedBox(height: 5));

        if (rdvs.isEmpty) {
          allContent.add(pw.Text('Aucun rendez-vous enregistré.'));
        } else {
          allContent.add(pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Date',
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Type',
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Statut',
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Détails',
                          style: const pw.TextStyle(fontSize: 10))),
                ],
              ),
              ...rdvs.map((rdv) => pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              DateFormat('dd/MM/yy HH:mm')
                                  .format(rdv.dateHeure),
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(rdv.typeRdv,
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(rdv.statut,
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(rdv.nomVaccin ?? '-',
                              style: const pw.TextStyle(fontSize: 9))),
                    ],
                  )),
            ],
          ));
        }
        allContent.add(pw.Divider(color: PdfColors.grey, thickness: 2.0));
        allContent.add(pw.SizedBox(height: 20));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => allContent,
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/Rapport_Complet_$title.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primary,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Archives & Rapports',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: AppTheme.primary,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Terminés'),
                    Tab(text: 'Abandonnés'),
                  ],
                  labelStyle: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: AppTheme.accent,
                  indicatorWeight: 3,
                  dividerColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_terminatedList, 'TERMINE'),
                  _buildList(_abandonedList, 'ABANDON'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<PatientModel> list, String status) {
    final isTermine = status == 'TERMINE';
    final color = isTermine ? AppTheme.success : AppTheme.warning;
    final bgColor = isTermine ? AppTheme.successSoft : AppTheme.warningSoft;

    return Column(
      children: [
        // Header bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${list.length} dossier${list.length > 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _generateListPdf(list, status),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          size: 15, color: AppTheme.danger),
                      const SizedBox(width: 5),
                      Text(
                        'Exporter PDF',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined,
                          size: 40, color: AppTheme.textTert),
                      const SizedBox(height: 12),
                      Text('Aucun dossier archivé', style: AppTheme.bodyMd),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final patient = list[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.archive_rounded,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${patient.prenom} ${patient.nom}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(patient.telephone,
                                        style: AppTheme.labelSm),
                                  ],
                                ),
                              ),
                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Text(
                                  isTermine ? 'Terminé' : 'Abandon',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete
                              GestureDetector(
                                onTap: () =>
                                    _showDeleteConfirmation(patient),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerSoft,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: AppTheme.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(PatientModel patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Suppression définitive',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Supprimer ${patient.prenom} de l\'application ?\n\n'
          'NOTE : Le fichier PDF reste sauvegardé sur votre téléphone.',
          style: AppTheme.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await Provider.of<PatientProvider>(context, listen: false)
                  .deletePatient(patient.id);
              if (mounted) {
                Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}
