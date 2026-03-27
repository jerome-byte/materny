import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:materny/presentation/providers/auth_provider.dart';
import '../main_container.dart';
import 'signup_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 74, 144, 226),
                    Color.fromARGB(255, 228, 125, 219),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      top: -30,
                      right: -20,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromARGB(255, 243, 237, 237).withValues(alpha: 0.04),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 30,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:  Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Logo mark
                           Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: const Color.fromARGB(255, 224, 114, 215).withValues(alpha: 0.6),
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
                          const SizedBox(height: 16),
                          Text(
                            'Materny',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Espace Agent de Santé',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────────────
          Expanded(
            flex: 9,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connexion',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Accédez à votre tableau de bord',
                          style: AppTheme.bodyMd,
                        ),
                        const SizedBox(height: 28),

                        // Email
                        _FieldLabel(label: 'Adresse Email'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'agent@hopital.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 19),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Email requis' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        _FieldLabel(label: 'Mot de passe'),
                        const SizedBox(height: 7),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon:
                                const Icon(Icons.lock_outline, size: 19),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 19,
                                color: AppTheme.textTert,
                              ),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Mot de passe requis' : null,
                        ),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7F8C8D),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Error + CTA
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return Column(
                              children: [
                                if (auth.errorMessage != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.dangerSoft,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.danger
                                              .withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: AppTheme.danger, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.errorMessage!,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              color: AppTheme.danger,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        auth.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A90E2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Se connecter',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                         const SizedBox(height: 10),

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
                                color: const Color(0xFF4A90E2),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: AppTheme.border)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('ou',
                                  style: AppTheme.labelSm),
                            ),
                            Expanded(
                                child: Divider(color: AppTheme.border)),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Sign up
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pas encore de compte ? ',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppTheme.textSec,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpScreen()),
                                ),
                                child: Text(
                                  "S'inscrire",
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9B59B6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.loginAgent(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (auth.isAuthenticated && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainContainer()));
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Entrez votre email pour réinitialiser le mot de passe.')),
      );
      return;
    }
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .resetPassword(email);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de réinitialisation envoyé !')),
      );
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTheme.sectionLabel.copyWith(color: const Color(0xFF1A237E),));
  }
}
