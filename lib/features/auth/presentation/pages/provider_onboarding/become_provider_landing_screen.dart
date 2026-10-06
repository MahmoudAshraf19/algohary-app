import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/features/auth/presentation/pages/provider_onboarding/provider_application_screen.dart';
import 'package:algohary_project/features/auth/presentation/pages/provider_onboarding/check_application_screen.dart';

class BecomeProviderLandingScreen extends StatelessWidget {
  const BecomeProviderLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Logo or Icon at the top
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.handyman_outlined, size: 40, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.becomeProvider ?? 'Become a Provider',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.becomeProviderDesc ?? 'Join us and start your journey as a verified provider.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),
              
              _buildBenefitItem(
                context: context,
                icon: Icons.monetization_on_outlined,
                title: l10n.earnIncome ?? 'Earn Income',
                description: l10n.earnIncomeDesc ?? 'Turn your skills into a steady source of income.',
                theme: theme,
              ),
              const SizedBox(height: 20),
              
              _buildBenefitItem(
                context: context,
                icon: Icons.people_outline,
                title: l10n.reachMoreCustomers ?? 'Reach More Customers',
                description: l10n.reachMoreCustomersDesc ?? 'Connect with trusted customers looking for your services.',
                theme: theme,
              ),
              const SizedBox(height: 20),
              
              _buildBenefitItem(
                context: context,
                icon: Icons.support_agent_outlined,
                title: l10n.getSupport ?? 'Get Full Support',
                description: l10n.getSupportDesc ?? "We're with you at every step of your journey.",
                theme: theme,
              ),
              
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProviderApplicationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.startApplication ?? 'Start Application',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckApplicationScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.checkStatus ?? 'Check Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
