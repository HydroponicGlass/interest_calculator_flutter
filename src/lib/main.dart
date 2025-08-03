import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'services/onboarding_service.dart';
import 'providers/account_provider.dart';

void main() {
  runApp(const InterestCalculatorApp());
}

class InterestCalculatorApp extends StatelessWidget {
  const InterestCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
      ],
      child: MaterialApp(
        title: 'Interest Calculator',
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
            return hasCompleted ? const MainScreen() : const OnboardingScreen();
          },
        ),
      ),
    );
  }
}
