import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'home_navigation_screen.dart';

class WelcomeLandingScreen extends StatelessWidget {
  final LanguageController languageController;

  const WelcomeLandingScreen({
    super.key,
    required this.languageController,
  });

  void _openHome(BuildContext context, {int initialIndex = 0}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HomeNavigationScreen(
          languageController: languageController,
          initialTabIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageController,
      builder: (context, _) {
        final s = AppStrings.of(languageController.langCode);
        return Scaffold(
          backgroundColor: AppTheme.backgroundObsidian,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Bar: Pro Badge + 1-Tap Language Switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accentGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: AppTheme.accentGreen,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.get('proUnlockedBadge'),
                              style: const TextStyle(
                                color: AppTheme.accentGreen,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: ['es', 'en', 'pt'].map((code) {
                          final active = languageController.langCode == code;
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => languageController.setLanguage(code),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.accentCyan.withValues(alpha: 0.2)
                                      : AppTheme.surfaceSlate,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active
                                        ? AppTheme.accentCyan
                                        : AppTheme.borderColor,
                                  ),
                                ),
                                child: Text(
                                  code.toUpperCase(),
                                  style: TextStyle(
                                    color: active
                                        ? AppTheme.accentCyan
                                        : AppTheme.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Hero Radar + Thermal Emblem
                  Center(
                    child: Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.accentGreen.withValues(alpha: 0.28),
                            AppTheme.accentCyan.withValues(alpha: 0.12),
                            AppTheme.surfaceSlate,
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.accentGreen.withValues(alpha: 0.65),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentGreen.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.wifi_tethering_rounded,
                            size: 62,
                            color: AppTheme.accentGreen,
                          ),
                          Positioned(
                            right: 18,
                            bottom: 18,
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 26,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  Text(
                    s.get('appTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.get('appSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Feature Highlights
                  _FeatureHighlightCard(
                    icon: Icons.grid_view_rounded,
                    accentColor: AppTheme.accentGreen,
                    title: s.get('featureFloorplan'),
                    subtitle: s.get('featureFloorplanSub'),
                  ),
                  const SizedBox(height: 12),
                  _FeatureHighlightCard(
                    icon: Icons.graphic_eq_rounded,
                    accentColor: AppTheme.accentCyan,
                    title: s.get('featureSpectrum'),
                    subtitle: s.get('featureSpectrumSub'),
                  ),
                  const SizedBox(height: 12),
                  _FeatureHighlightCard(
                    icon: Icons.radar_rounded,
                    accentColor: AppTheme.accentAmber,
                    title: s.get('featureEmf'),
                    subtitle: s.get('featureEmfSub'),
                  ),
                  const SizedBox(height: 30),

                  // Primary Enter Button (Required Key: btnWelcomeEnter)
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      key: const Key('btnWelcomeEnter'),
                      onPressed: () => _openHome(context, initialIndex: 0),
                      icon: const Icon(Icons.radar_rounded),
                      label: Text(s.get('btnEnter')),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Secondary Action: Channel & EMF Radar
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const Key('btnWelcomeRadar'),
                      onPressed: () => _openHome(context, initialIndex: 1),
                      icon: const Icon(Icons.network_check_rounded, size: 20),
                      label: Text(s.get('btnNewSurvey')),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tertiary Action: Saved Floorplan PDF Surveys
                  TextButton.icon(
                    key: const Key('btnWelcomeSavedSurveys'),
                    onPressed: () => _openHome(context, initialIndex: 2),
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                    label: Text(
                      s.get('btnSavedSurveys'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureHighlightCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;

  const _FeatureHighlightCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
