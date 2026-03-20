import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:materny/presentation/screens/auth/login_screen.dart';
import 'main_container.dart';
import '../../data/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import 'patient_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _contentController;
  late Animation<double> _bgScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bgScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeOutCubic),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
      ),
    );
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _bgController.forward();
    _contentController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      try {
        final response = await SupabaseService.client
            .from('agents')
            .select('id')
            .eq('id', session.user.id)
            .maybeSingle();
        if (mounted) {
          if (response != null) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MainContainer()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const PatientDashboard()));
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgController, _contentController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background with subtle pattern
              ScaleTransition(
                scale: _bgScale,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D3324),
                        Color(0xFF0A2A1C),
                        Color(0xFF061810),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Decorative circle top-right
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
                top: 40,
                right: 20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Bottom decorative arc
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

              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo mark
                    FadeTransition(
                      opacity: _logoFade,
                      child: SlideTransition(
                        position: _logoSlide,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.favorite_rounded,
                              color: AppTheme.accent,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    FadeTransition(
                      opacity: _textFade,
                      child: Text(
                        'Materny',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.0,
                          height: 1.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          'SANTÉ MATERNELLE & INFANTILE',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.55),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Loader
                    FadeTransition(
                      opacity: _loaderFade,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.accent.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
