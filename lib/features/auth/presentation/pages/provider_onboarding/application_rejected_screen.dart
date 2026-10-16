import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';

class ApplicationRejectedScreen extends StatelessWidget {
  final String reason;

  const ApplicationRejectedScreen({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.error_outline, size: 60, color: colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                l10n.actionRequired,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              
              Text(
                l10n.needAdditionalInfo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 32),
              
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.statusTitle, style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withValues(alpha: 0.7))),
                        Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.deepOrange, size: 12),
                            const SizedBox(width: 8),
                            Text(
                              l10n.statusNotApproved,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      l10n.reasonTitle,
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              Text(
                'Please update your application or contact our support team for further assistance.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () {
                  // Mock update application
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
                      'Update Application',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {
                  // Mock support
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  l10n.contactSupport,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
