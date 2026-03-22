import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../../core/theme/app_theme.dart';

class AddPatientScreen extends StatefulWidget {
  final PatientModel? mother;
  const AddPatientScreen({super.key, this.mother});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _garantNomController = TextEditingController();
  final _garantTelephoneController = TextEditingController();
  final _typeRdvController = TextEditingController();
  final _vaccineController = TextEditingController();

  late String _genre;
  DateTime? _selectedDateRdv;
  bool _acceptPrivacy = false;
  String _selectedChannel = 'SMS';
  String _selectedLanguage = 'Kabiyè';
  String? activeAlertKey;

  final Map<String, Map<String, String>> _vaccines = {
    'BCG': {
      'name': 'BCG (Tuberculose)',
      'risk': 'Protège contre la tuberculose, une maladie grave des poumons.',
    },
    'PENTA': {
      'name': 'Pentavalent (DTP+Hib+HepB)',
      'risk': 'Protège contre 5 maladies : Diphtérie, Tétanos, Coqueluche, Hépatite B, Méningite.',
    },
    'POLIO': {
      'name': 'Polio (Poliomyélite)',
      'risk': 'Protège contre la paralysie définitive des membres.',
    },
    'ROUGEOLE': {
      'name': 'Rougeole',
      'risk': 'Protège contre la rougeole, maladie très contagieuse et mortelle.',
    },
    'FIÈVRE JAUNE': {
      'name': 'Fièvre Jaune',
      'risk': 'Protège contre la fièvre hémorragique mortelle.',
    },
    'ROR': {
      'name': 'ROR (Rougeole-Oreillons-Rubéole)',
      'risk': 'Protège contre la rougeole, les oreillons et la rubéole.',
    },
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _genre = widget.mother != null ? 'M' : 'F';

    if (widget.mother != null) {
      _nomController.text = widget.mother!.nom;
      _telephoneController.text = widget.mother!.telephone;
      _typeRdvController.text = "Vaccination";
      _vaccineController.text = "BCG";
    } else {
      _typeRdvController.text = "Consultation Prénatale (CPN)";
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _garantNomController.dispose();
    _garantTelephoneController.dispose();
    _typeRdvController.dispose();
    _vaccineController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime.now(),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
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

      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDateRdv = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  Future<void> _savePatientAndRdv() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez accepter la politique de confidentialité.")),
      );
      return;
    }

    if (_selectedDateRdv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une date de rendez-vous.")),
      );
      return;
    }

    final typeRdvText = _typeRdvController.text.trim();
    final vaccineText = _vaccineController.text.trim();
    final bool isChildMode = widget.mother != null;

    if (isChildMode && typeRdvText.toLowerCase().contains('vaccination') && vaccineText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir ou choisir un vaccin.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = Provider.of<PatientProvider>(context, listen: false);

    // MODIFICATION ICI : On récupère un Map (ID + Code)
    final result = await provider.addPatient(
      prenom: _prenomController.text.trim(),
      nom: _nomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      genre: _genre,
      motherId: widget.mother?.id,
      contactUrgenceNom: _garantNomController.text.trim(),
      contactUrgenceTel: _garantTelephoneController.text.trim(),
    );

    if (result != null) {
      final patientId = result['id'] as int;
      final accessCode = result['access_code'] as String;

      await provider.addRendezVous(
        patientId: patientId,
        dateHeure: _selectedDateRdv!,
        typeRdv: typeRdvText,
        nomVaccin: vaccineText.isNotEmpty ? vaccineText : null,
      );

      if (mounted) {
        // Affichage du code à l'agent
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 10),
                const Text("Succès"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _genre == 'M' 
                      ? "Enfant enregistré avec succès !" 
                      : "Patiente enregistrée avec succès !",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Code d'accès à transmettre à la patiente :",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    accessCode,
                    style: GoogleFonts.dmSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  onPressed: () {
                    Navigator.pop(ctx); // Fermer la boîte
                    Navigator.pop(context); // Retour à la liste
                  },
                  child: const Text("TERMINER", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de l'enregistrement.")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isChildMode = widget.mother != null;

    // Calcul de l'alerte active
    activeAlertKey = null;
    _vaccines.forEach((key, value) {
      if (_vaccineController.text.toUpperCase().contains(key)) {
        activeAlertKey = key;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(
          isChildMode ? "Enregistrer un Enfant" : "Nouvelle Patiente",
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
              // ── Mother Card ──────────────────────────────────────
              if (isChildMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEAF0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4649A).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.pregnant_woman_rounded, color: const Color(0xFFD4649A)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mère : ${widget.mother!.prenom} ${widget.mother!.nom}",
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Section Info Patient ───────────────────────────────
              _SectionLabel(label: 'INFORMATIONS PERSONNELLES'),
              const SizedBox(height: 10),
              _FormCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StyledTextFormField(
                          controller: _prenomController,
                          label: 'Prénom *',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StyledTextFormField(
                          controller: _nomController,
                          label: 'Nom *',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StyledTextFormField(
                    controller: _telephoneController,
                    label: 'Téléphone *',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Section Garant ───────────────────────────────────────
              _SectionLabel(label: 'PERSONNE DE CONFIANCE'),
              const SizedBox(height: 10),
              _FormCard(
                children: [
                  _StyledTextFormField(
                    controller: _garantNomController,
                    label: 'Nom du garant',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _StyledTextFormField(
                    controller: _garantTelephoneController,
                    label: 'Téléphone garant',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_in_talk_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Section RDV ─────────────────────────────────────────
              _SectionLabel(label: 'RENDEZ-VOUS'),
              const SizedBox(height: 10),
              _FormCard(
                children: [
                  // Type RDV
                  Autocomplete<String>(
                    initialValue: TextEditingValue(text: _typeRdvController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      List<String> options = isChildMode
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
                        onChanged: (v) => _typeRdvController.text = v,
                        validator: (v) => v!.isEmpty ? "Requis" : null,
                      );
                    },
                  ),

                  // Vaccine (Only if child)
                  if (isChildMode && _typeRdvController.text.toLowerCase().contains('vaccination')) ...[
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

                  const SizedBox(height: 12),

                  // Date Picker
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                        decoration: _inputDecoration(
                          _selectedDateRdv == null
                              ? 'Date et heure *'
                              : DateFormat('dd/MM/yyyy à HH:mm').format(_selectedDateRdv!),
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                        validator: (v) => _selectedDateRdv == null ? "Requis" : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Section Settings ────────────────────────────────────
              _SectionLabel(label: 'PRÉFÉRENCES'),
              const SizedBox(height: 10),
              _FormCard(
                children: [
                  // Privacy Checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "J'accepte que mes informations soient enregistrées et utilisées pour les rappels.",
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSec),
                    ),
                    value: _acceptPrivacy,
                    activeColor: AppTheme.primary,
                    onChanged: (v) => setState(() => _acceptPrivacy = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  
                  const Divider(height: 24),

                  // Channel Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedChannel,
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: _inputDecoration('Canaux de rappel'),
                    items: const [
                      DropdownMenuItem(value: 'SMS', child: Text("SMS")),
                      DropdownMenuItem(value: 'Notification', child: Text("Notification")),
                      DropdownMenuItem(value: 'Appel', child: Text("Appel téléphonique")),
                    ],
                    onChanged: (v) => setState(() => _selectedChannel = v!),
                  ),
                  
                  const SizedBox(height: 12),

                  // Language Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                    decoration: _inputDecoration('Langue de rappel'),
                    items: const [
                      DropdownMenuItem(value: 'Kabiyè', child: Text("Kabiyè")),
                      DropdownMenuItem(value: 'EWE', child: Text("EWE")),
                      DropdownMenuItem(value: 'Losso', child: Text("Losso")),
                      DropdownMenuItem(value: 'Ife', child: Text("Ife")),
                      DropdownMenuItem(value: 'Tem', child: Text("Tem")),
                      DropdownMenuItem(value: 'Moba', child: Text("Moba")),
                      DropdownMenuItem(value: 'Ouatchi', child: Text("Ouatchi")),
                      DropdownMenuItem(value: 'Lama', child: Text("Lama")),
                      DropdownMenuItem(value: 'Français', child: Text("Français")),
                      DropdownMenuItem(value: 'Anglais', child: Text("Anglais")),
                    ],
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
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
                  onPressed: _isLoading ? null : _savePatientAndRdv,
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

  // --- Helper Widgets for Styling ---

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

class _StyledTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  const _StyledTextFormField({
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textTert),
        filled: true,
        fillColor: AppTheme.surface,
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
      ),
      validator: (v) => v!.isEmpty ? "Requis" : null,
    );
  }
}