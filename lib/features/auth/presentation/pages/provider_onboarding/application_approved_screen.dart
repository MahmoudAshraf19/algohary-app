import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';

class ApplicationApprovedScreen extends StatelessWidget {
  const ApplicationApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.verified, size: 60, color: colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                l10n.youAreApproved,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              
              Text(
                '${l10n.welcomeToHostCommunity}\n${l10n.proceedToCreateProperties}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),
              
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.hostStatus, style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7))),
                        Row(
                          children: [
                            Text(
                              l10n.statusActive,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.circle, color: colorScheme.primary, size: 12),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.verification, style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7))),
                        Row(
                          children: [
                            Text(
                              l10n.statusCompleted,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.circle, color: colorScheme.primary, size: 12),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.backToHome,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
