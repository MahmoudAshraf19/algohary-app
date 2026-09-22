import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/core/theme/app_colors.dart';
import 'package:algohary_project/core/bloc/settings_cubit/settings_cubit.dart';
import 'package:algohary_project/core/bloc/settings_cubit/settings_state.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Using white background as per the design screenshot
    final bgColor = theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppColors.primaryBlue, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.settings ?? 'Settings',
          style: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.account ?? 'Account', theme),
            _buildSettingsRow(
              icon: Icons.lock,
              title: l10n.settingsChangePassword ?? 'Change Password',
              theme: theme,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                );
              },
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.notificationsTitle ?? 'Notifications', theme),
            _buildSettingsRow(
              icon: Icons.notifications,
              title: l10n.settingsPushNotifications ?? 'Push Notifications',
              theme: theme,
              trailing: CupertinoSwitch(
                value: _pushNotificationsEnabled,
                activeColor: AppColors.primaryBlue,
                onChanged: (value) {
                  setState(() {
                    _pushNotificationsEnabled = value;
                  });
                },
              ),
              onTap: null, // Tap handled by switch
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.settingsAppSettings ?? 'App Settings', theme),
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                final isDark = state.themeMode == ThemeMode.dark;
                return _buildSettingsRow(
                  icon: Icons.nightlight_round,
                  title: l10n.settingsDarkMode ?? 'Dark Mode',
                  theme: theme,
                  trailing: CupertinoSwitch(
                    value: isDark,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (value) {
                      context.read<SettingsCubit>().toggleTheme(value);
                    },
                  ),
                  onTap: null, // Tap handled by switch
                );
              },
            ),
            _buildDivider(),
            BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, state) {
                final isEnglish = state.locale.languageCode == 'en';
                final languageText = isEnglish ? (l10n.settingsEnglish ?? 'English') : (l10n.settingsArabic ?? 'العربية');
                final isRtl = Directionality.of(context) == TextDirection.rtl;
                return _buildSettingsRow(
                  icon: Icons.language,
                  title: l10n.settingsLanguage ?? 'Language',
                  theme: theme,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        languageText,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppColors.primaryBlue.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isRtl ? Icons.chevron_left : Icons.chevron_right,
                        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppColors.primaryBlue,
                        size: 20,
                      ),
                    ],
                  ),
                  onTap: () {
                    _showLanguagePicker(context, state.locale.languageCode, l10n);
                  },
                );
              },
            ),
            
            const SizedBox(height: 32),
            _buildSectionTitle(l10n.settingsSupport ?? 'Support', theme),
            _buildSettingsRow(
              icon: Icons.help_outline,
              title: l10n.settingsHelpAndSupport ?? 'Help & Support',
              theme: theme,
              onTap: () {},
            ),
            _buildDivider(),
            _buildSettingsRow(
              icon: Icons.info_outline,
              title: l10n.settingsAboutApp ?? 'About App',
              theme: theme,
              onTap: () {},
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required ThemeData theme,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.lightYellow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) 
              trailing
            else
              Icon(
                isRtl ? Icons.chevron_left : Icons.chevron_right,
                color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : AppColors.primaryBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: EdgeInsets.only(
        left: isRtl ? 24.0 : 84.0,
        right: isRtl ? 84.0 : 24.0,
      ),
      child: Divider(
        height: 1,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, String currentCode, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.settingsSelectLanguage ?? 'Select Language',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(l10n.settingsEnglish ?? 'English'),
                trailing: currentCode == 'en' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  context.read<SettingsCubit>().changeLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.settingsArabic ?? 'العربية'),
                trailing: currentCode == 'ar' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                onTap: () {
                  context.read<SettingsCubit>().changeLanguage('ar');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
