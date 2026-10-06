import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/core/network/firebase_config.dart';
import 'application_approved_screen.dart';
import 'application_rejected_screen.dart';

class ApplicationStatusScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationStatusScreen({super.key, required this.applicationId});

  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseConfig.firestore.collection('provider_applications').doc(widget.applicationId).snapshots(),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: Text(AppLocalizations.of(context)!.applicationNotFound ?? 'Application not found.')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final status = data['status'] as String? ?? 'under_review';
        final reason = data['reason'] as String?;

        if (status == 'approved') {
          return const ApplicationApprovedScreen();
        } else if (status == 'rejected' || status == 'info_required') {
          return ApplicationRejectedScreen(
            reason: reason ?? (status == 'rejected' ? 'Application did not meet our requirements.' : 'Please provide additional information.'),
          );
        }

        // Default to under review
        return _buildUnderReviewUI(context, theme, 2); // 2 = background review step
      },
    );
  }

  Widget _buildUnderReviewUI(BuildContext context, ThemeData theme, int currentStep) {
    final l10n = AppLocalizations.of(context)!;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.applicationStatusTitle ?? 'Application Status',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              
              Text(
                l10n.applicationStatusDesc ?? 'Here is the current status of your application.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 32),
              
              // Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.applicationId ?? 'Application ID',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.applicationId,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.statusTitle ?? 'Status',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.orange, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          l10n.statusUnderReview ?? 'Under Review',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    
                    // Timeline
                    _buildTimelineStep(
                      theme: theme,
                      title: l10n.stepAppSubmitted ?? 'Application Submitted',
                      date: DateFormat('dd MMM yyyy').format(DateTime.now().subtract(const Duration(days: 1))),
                      isCompleted: currentStep >= 0,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      theme: theme,
                      title: l10n.stepIdentityVerification ?? 'Identity Verification',
                      date: DateFormat('dd MMM yyyy').format(DateTime.now()),
                      isCompleted: currentStep >= 1,
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      theme: theme,
                      title: l10n.stepBackgroundReview ?? 'Background Review',
                      date: currentStep > 2 ? DateFormat('dd MMM yyyy').format(DateTime.now()) : (l10n.statusInProgress ?? 'In Progress'),
                      isCompleted: currentStep >= 2,
                      isLast: false,
                      isInProgress: currentStep == 2,
                    ),
                    _buildTimelineStep(
                      theme: theme,
                      title: l10n.stepFinalDecision ?? 'Final Decision',
                      date: l10n.statusPending ?? 'Pending',
                      isCompleted: currentStep >= 3,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.reviewTimeInfo ?? 'We are reviewing your application. This may take 1-2 business days.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  // Mock support action, maybe navigate to support chat
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
                      l10n.contactSupport ?? 'Contact Support',
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

  Widget _buildTimelineStep({
    required ThemeData theme,
    required String title,
    required String date,
    required bool isCompleted,
    required bool isLast,
    bool isInProgress = false,
  }) {
    final colorScheme = theme.colorScheme;
    final color = isCompleted ? colorScheme.primary : (isInProgress ? Colors.orange : colorScheme.onSurface.withOpacity(0.3));
    final icon = isCompleted ? Icons.check_circle : (isInProgress ? Icons.access_time_filled : Icons.circle_outlined);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: color, size: 24),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted && !isInProgress ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.2),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCompleted || isInProgress ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted || isInProgress ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
                    color: isInProgress ? Colors.orange : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
