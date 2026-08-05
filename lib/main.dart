import 'package:civicfic/screens/splash_screen.dart';
import 'package:civicfic/firebase_options.dart';
import 'package:civicfic/providers/settings_provider.dart';
import 'package:civicfic/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CivicFix',
          
          // 👇 Full App Dark Mode - Settings il ninnu value edukkunnu
          theme: settings.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          
          locale: settings.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ml', 'IN'),
            Locale('hi', 'IN'),
            Locale('ta', 'IN'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home:SplashScreen(),
        );
      },
    );
  }
}