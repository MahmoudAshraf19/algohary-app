import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/core/network/firebase_config.dart';

enum HtmlScreenType { aboutApp, privacyPolicy, termsAndConditions }

class DynamicHtmlScreen extends StatelessWidget {
  final HtmlScreenType type;

  const DynamicHtmlScreen({super.key, required this.type});

  String _getTitle(AppLocalizations l10n) {
    switch (type) {
      case HtmlScreenType.aboutApp:
        return l10n.settingsAboutApp ?? 'About App';
      case HtmlScreenType.privacyPolicy:
        return l10n.settingsPrivacyPolicy ?? 'Privacy Policy';
      case HtmlScreenType.termsAndConditions:
        return l10n.settingsTermsConditions ?? 'Terms and Conditions';
    }
  }

  String _getDocumentId() {
    switch (type) {
      case HtmlScreenType.aboutApp:
        return 'about_app';
      case HtmlScreenType.privacyPolicy:
        return 'privacyPolicy';
      case HtmlScreenType.termsAndConditions:
        return 'termsAndConditions';
    }
  }

  String _getFieldName() {
    switch (type) {
      case HtmlScreenType.aboutApp:
        return 'about_app';
      case HtmlScreenType.privacyPolicy:
        return 'privacy_policy';
      case HtmlScreenType.termsAndConditions:
        return 'termsAndConditions';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final bgColor = theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surface;
    final textColor = theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(l10n),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
            height: 1.0,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseConfig.firestore.collection('settings').doc(_getDocumentId()).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
          }
          
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'Content not available.',
                style: TextStyle(color: textColor),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final htmlContent = data?[_getFieldName()] as String? ?? '<p>No content available.</p>';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Html(
              data: htmlContent,
              style: {
                "body": Style(
                  color: textColor,
                  fontSize: FontSize(15.0),
                ),
                "h1": Style(color: AppColors.primaryBlue),
                "h2": Style(color: AppColors.primaryBlue),
                "strong": Style(fontWeight: FontWeight.bold),
                "a": Style(color: AppColors.primaryBlue, textDecoration: TextDecoration.none),
              },
            ),
          );
        },
      ),
    );
  }
}
