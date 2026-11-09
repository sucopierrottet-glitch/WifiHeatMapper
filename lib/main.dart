import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_strings.dart';
import 'screens/welcome_landing_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.configureOfflineFonts();
  final langController = LanguageController();
  await langController.loadSavedLanguage();
  runApp(WifiHeatMapperApp(languageController: langController));
}

class WifiHeatMapperApp extends StatelessWidget {
  final LanguageController languageController;

  const WifiHeatMapperApp({
    super.key,
    required this.languageController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) {
        return MaterialApp(
          title: 'WiFi HeatMapper Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          locale: languageController.locale,
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
            Locale('pt'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: WelcomeLandingScreen(languageController: languageController),
        );
      },
    );
  }
}
