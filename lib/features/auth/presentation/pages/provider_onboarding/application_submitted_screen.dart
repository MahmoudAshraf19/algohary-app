import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'application_status_screen.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  final String applicationId; // Internal Document ID (userId)
  final String shortAppId;    // Displayed ID (e.g. 5 digits)

  const ApplicationSubmittedScreen({super.key, required this.applicationId, required this.shortAppId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: colorScheme.primary,
                          child: Icon(Icons.check, size: 60, color: colorScheme.onPrimary),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text(
                        l10n.applicationSubmitted,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        l10n.applicationUnderReview,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 32),
                      
                      // Application ID Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              l10n.applicationId,
                              style: TextStyle(fontSize: 14, color: colorScheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  shortAppId,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.copy, color: colorScheme.primary, size: 20),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: shortAppId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.copiedToClipboard, textAlign: TextAlign.center),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        backgroundColor: colorScheme.onSurface.withOpacity(0.9),
                                        duration: const Duration(seconds: 2),
                                        elevation: 0,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.keepIdSafe,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Status Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.statusTitle, style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7))),
                                Row(
                                  children: [
                                    const Icon(Icons.circle, color: Colors.orange, size: 12),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.statusUnderReview,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(l10n.submittedDate, style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7))),
                                Text(
                                  DateFormat('d MMM yyyy').format(DateTime.now()),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      Text(
                        l10n.ourTeamWillReview,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => ApplicationStatusScreen(applicationId: applicationId)),
                          );
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
                              l10n.trackApplication,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: colorScheme.onPrimary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          l10n.backToHome,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
