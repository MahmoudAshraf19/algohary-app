import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/subscriptions/presentation/pages/subscription_plan_screen.dart';

class ProviderSettingsTab extends StatelessWidget {
  const ProviderSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navProviderSettings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business_center),
            title: Text(l10n.chooseBusinessPlan),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPlanScreen(),
                ),
              );
            },
          ),
          // Other settings...
        ],
      ),
    );
  }
}
