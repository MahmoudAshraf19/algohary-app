import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(AppLocalizations.of(context)!.navExplore),
    );
  }
}
