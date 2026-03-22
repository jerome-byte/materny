import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'auth/patient_login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration de l'animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    // Démarrage automatique
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Gradient (Animé si souhaité, ici statique pour performance) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3324), Color(0xFF0A2A1C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative Circles ──
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── Contenu Principal ──
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                             // --- NOUVEAU : Phrase de bienvenue ---
                        Text(
                          "Bienvenue ",
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Logo "M" ──
                        Container(
                          width: 90,
                          height: 90,
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
                                fontSize: 50,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // ── Titres ──
                        Text(
                          'MATERNY',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Santé Maternelle & Infantile',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Images Section ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Image 1: Femme Enceinte
                              _buildImageCard('assets/femme_enceinte.jpg'),
                              
                              // Image 2: Maman et Bébé
                              _buildImageCard('assets/maman_bebe.png'),
                              
                              // Image 3: Sage Femme
                              _buildImageCard('assets/sage_femme.jpg'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 50),

                        // ── Boutons ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              // Bouton Agent
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 5,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    );
                                  },
                                  child: Text(
                                    "Je suis Agent de Santé",
                                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Bouton Patiente
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white54, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
                                    );
                                  },
                                  child: Text(
                                    "Je suis une Patiente",
                                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
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

  // Widget helper pour les images avec style arrondi
  Widget _buildImageCard(String assetPath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        assetPath,
        height: 150,
        width: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            width: 110,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.image, color: Colors.white30, size: 30),
          );
        },
      ),
    );
  }
}