import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
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
        home: const MainScreen(),
      ),
    );
  }
}
