import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../landing_screen.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen>
    with SingleTickerProviderStateMixin {
    final _phoneController = TextEditingController();
  final _codeController = TextEditingController(); // Changement : Code au lieu de OTP
  bool _isLoading = false;
    bool _isCodeVisible = false; // Variable pour l'œil

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

    Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (phone.length < 8 || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Vérifier si le couple Numéro + Code existe dans la table patients
      final responseList = await Supabase.instance.client
          .from('patients')
          .select('id, user_id')
          .eq('telephone', phone)
          .eq('access_code', code);
          
       if (responseList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Numéro ou Code incorrect.")),
        );
        setState(() => _isLoading = false);
        return;
      }
       // On prend le premier résultat (généralement la mère ou le propriétaire du compte)
      final patientData = responseList.first;

            final patientId = patientData['id'];
      final existingUserId = patientData['user_id'];
      
      // 2. Gestion de la connexion (Création de session)
      // Astuce : On utilise le numéro comme email unique pour Supabase Auth
      final fakeEmail = "$phone@materny.patient";
      
      if (existingUserId == null) {
        // PREMIÈRE CONNEXION : Création du compte utilisateur
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: fakeEmail,
          password: code, // Le mot de passe est le code d'accès
        );
        
        if (authResponse.user != null) {
          // Lier le user_id au dossier patient
          await Supabase.instance.client
              .from('patients')
              .update({'user_id': authResponse.user!.id})
              .eq('id', patientId);
        }
      } else {
        // CONNEXIONS SUIVANTES : Connexion simple
        await Supabase.instance.client.auth.signInWithPassword(
          email: fakeEmail,
          password: code,
        );
      }

      // 3. Redirection
      Navigator.pushReplacementNamed(context, '/patient-dashboard');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de connexion: $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D3324), Color(0xFF0A2A1C)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                          child: Center(
                            child: Text(
                              "M",
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        'Espace Patiente',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 38, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Retrouvez vos rendez-vous',
                        style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────────
          Expanded(
            flex: 9,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connexion',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entrez votre numéro de téléphone',
                      style: AppTheme.bodyMd,
                    ),
                    const SizedBox(height: 28),

                    // Phone Input
                                        // Phone Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Numéro de téléphone',
                        prefixIcon: Icon(Icons.phone_outlined, size: 19),
                      ),
                    ),

                    const SizedBox(height: 16), // Espace entre les champs

                    // Code Input
                    // Code Input
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      obscureText: !_isCodeVisible, // Utilisation de la variable
                      style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
                      decoration: InputDecoration( // Suppression du 'const'
                        hintText: 'Code d\'accès (donné par l\'agent)',
                        prefixIcon: const Icon(Icons.lock_outline, size: 19),
                        // Ajout de l'œil
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isCodeVisible ? Icons.visibility : Icons.visibility_off,
                            size: 19,
                            color: AppTheme.textTert,
                          ),
                          onPressed: () {
                            setState(() {
                              _isCodeVisible = !_isCodeVisible;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login, // Appel de la nouvelle fonction
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'SE CONNECTER', // Texte fixe
                                style: GoogleFonts.dmSans(
                                  fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                      const SizedBox(height: 15),

                        // --- NOUVEAU : Bouton Retour ---
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LandingScreen()),
                              );
                            },
                            child: Text(
                              "Retour",
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: const Color.fromARGB(255, 11, 46, 25),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}