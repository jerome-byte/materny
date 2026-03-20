import 'package:flutter/material.dart';
import 'package:materny/data/services/supabase_service.dart';
import 'package:materny/presentation/providers/auth_provider.dart';
import 'package:materny/presentation/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/patient_provider.dart';
import 'presentation/screens/patients/add_patient_screen.dart';
import 'presentation/screens/rdv/add_rdv_screen.dart';
import 'data/models/patient_model.dart';
import 'presentation/screens/auth/patient_login_screen.dart';
import 'presentation/screens/patient_dashboard.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
      ],
      child: MaterialApp(
        title: 'Materny',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
        routes: {
          '/add-patient': (context) => const AddPatientScreen(),
          '/add-rdv': (context) => AddRdvScreen(
              patient: ModalRoute.of(context)!.settings.arguments as PatientModel),
          '/patient-login': (context) => const PatientLoginScreen(),
          '/patient-dashboard': (context) => const PatientDashboard(),
        },
      ),
    );
  }
}
