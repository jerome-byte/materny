import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../../core/theme/app_theme.dart';

class AddRdvScreen extends StatefulWidget {
  final PatientModel patient;
  const AddRdvScreen({super.key, required this.patient});

  @override
  State<AddRdvScreen> createState() => _AddRdvScreenState();
}

class _AddRdvScreenState extends State<AddRdvScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  bool _isLoading = false;

  final _typeRdvController = TextEditingController();
  final _vaccineController = TextEditingController();

  final Map<String, Map<String, String>> _vaccines = {
    'BCG': {'name': 'BCG (Tuberculose)', 'risk': 'Protège contre la tuberculose, une maladie grave des poumons.'},
    'PENTA': {'name': 'Pentavalent (DTP+Hib+HepB)', 'risk': 'Protège contre 5 maladies : Diphtérie, Tétanos, Coqueluche, Hépatite B, Méningite.'},
    'POLIO': {'name': 'Polio (Poliomyélite)', 'risk': 'Protège contre la paralysie définitive des membres.'},
    'ROUGEOLE': {'name': 'Rougeole', 'risk': 'Protège contre la rougeole, maladie très contagieuse et mortelle.'},
    'FIÈVRE JAUNE': {'name': 'Fièvre Jaune', 'risk': 'Protège contre la fièvre hémorragique mortelle.'},
    'ROR': {'name': 'ROR (Rougeole-Oreillons-Rubéole)', 'risk': 'Protège contre la rougeole, les oreillons et la rubéole.'},
  };

  @override
  void initState() {
    super.initState();
    if (widget.patient.genre == 'F') {
      _typeRdvController.text = "Consultation Prénatale (CPN)";
    } else {
      _typeRdvController.text = "Vaccination";
      _vaccineController.text = "BCG";
    }
  }

  @override
  void dispose() {
    _typeRdvController.dispose();
    _vaccineController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppTheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _saveRdv() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une date et heure.")),
      );
      return;
    }

    final typeRdvText = _typeRdvController.text.trim();
    final vaccineText = _vaccineController.text.trim();

    if (widget.patient.genre == 'M' && typeRdvText.toLowerCase().contains('vaccination') && vaccineText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir ou choisir un vaccin.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<PatientProvider>(context, listen: false);
    final success = await provider.addRendezVous(
      patientId: widget.patient.id,
      dateHeure: _selectedDate!,
      typeRdv: typeRdvText,
      nomVaccin: vaccineText.isNotEmpty ? vaccineText : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rendez-vous planifié avec succès")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isChild = widget.patient.genre == 'M';

    // Calcul de l'alerte active
    String? activeAlertKey;
    _vaccines.forEach((key, value) {
      if (_vaccineController.text.toUpperCase().contains(key)) {
        activeAlertKey = key;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(
          "RDV pour ${widget.patient.prenom}",
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient Info Card ──────────────────────────────
              Container(
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
                        color: isChild ? const Color(0xFFE6F0FB) : const Color(0xFFFCEAF0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isChild ? Icons.child_care_rounded : Icons.pregnant_woman_rounded,
                        color: isChild ? const Color(0xFF4A90D9) : const Color(0xFFD4649A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "${widget.patient.prenom} ${widget.patient.nom}",
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section RDV ─────────────────────────────────────
              _SectionLabel(label: 'PLANIFICATION'),
              const SizedBox(height: 10),
              _FormCard(
                children: [
                  // Date Picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: _inputDecoration(
                          _selectedDate == null
                              ? 'Date et heure *'
                              : DateFormat('dd/MM/yyyy à HH:mm').format(_selectedDate!),
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                        validator: (v) => _selectedDate == null ? "Requis" : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Type RDV
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _typeRdvController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      List<String> options = isChild
                          ? ['Vaccination', 'Autre']
                          : ['Consultation Prénatale (CPN)', 'Autre'];

                      if (textEditingValue.text.isEmpty) return options;
                      return options.where((opt) => opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      setState(() => _typeRdvController.text = selection);
                    },
                    fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: _inputDecoration('Type de RDV *'),
                        onChanged: (v) => setState(() => _typeRdvController.text = v),
                        validator: (v) => v!.isEmpty ? "Requis" : null,
                      );
                    },
                  ),

                  // Vaccine (Only if child + vaccination)
                  if (isChild && _typeRdvController.text.toLowerCase().contains('vaccination')) ...[
                    const SizedBox(height: 12),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _vaccineController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final options = _vaccines.keys.toList();
                        if (textEditingValue.text.isEmpty) return options;
                        return options.where((opt) => opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        setState(() => _vaccineController.text = selection);
                      },
                      fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                          decoration: _inputDecoration('Nom du vaccin', fillColor: const Color(0xFFE6F0FB)),
                          onChanged: (v) => setState(() => _vaccineController.text = v),
                        );
                      },
                    ),

                    // Alert
                    if (activeAlertKey != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.warningSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _vaccines[activeAlertKey]!['risk']!,
                                style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textSec),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // ── Save Button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _saveRdv,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          'ENREGISTRER',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---
  InputDecoration _inputDecoration(String label, {IconData? prefixIcon, Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textTert),
      filled: true,
      fillColor: fillColor ?? AppTheme.surface,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppTheme.textTert) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSec,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: children),
    );
  }
}