import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/onboarding_service.dart';
import 'providers/account_provider.dart';
import 'providers/ad_provider.dart';
import 'gdpr/gdpr_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: Google Mobile Ads is initialized in GdprHelper after GDPR consent
  runApp(const InterestCalculatorApp());
}

class InterestCalculatorApp extends StatelessWidget {
  const InterestCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
      ],
      child: MaterialApp(
        title: '올인원 이자계산기',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: FutureBuilder<bool>(
          future: OnboardingService.hasCompletedOnboarding(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            final hasCompleted = snapshot.data ?? false;
            final targetScreen = hasCompleted ? const MainScreen() : const OnboardingScreen();
            
            // Always go through GDPR screen first to initialize AdMob properly
            return GdprScreen(nextScreen: targetScreen);
          },
        ),
      ),
    );
  }
}
