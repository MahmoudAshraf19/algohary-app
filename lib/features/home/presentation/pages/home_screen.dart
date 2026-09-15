import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get translations from AppLocalizations
    final l10n = AppLocalizations.of(context)!;
    
    // 2. Get current theme settings (colors & text styles) to adapt to Light/Dark modes
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language,
              size: 80,
              color: colorScheme.primary, // Adapts based on theme
            ),
            const SizedBox(height: 24),
            // Example of using localized text and theme text style
            Text(
              l10n.welcomeMessage,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Using theme colors for the container
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.secondary),
              ),
              child: Text(
                l10n.themeHint,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface, // Adapts based on theme
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Button action
              },
              icon: const Icon(Icons.thumb_up),
              label: Text(l10n.helloWorld),
            ),
          ],
        ),
      ),
    );
  }
}
