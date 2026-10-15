import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_event.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../../profile/presentation/pages/edit_profile_screen.dart';
import '../../../../notifications/presentation/pages/notifications_screen.dart';
import '../../../../profile/presentation/pages/settings_screen.dart';
import '../../../../../core/theme/app_colors.dart';
import 'package:algohary_project/features/dashboard/presentation/pages/provider_dashboard_screen.dart';
import 'package:algohary_project/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algohary_project/features/auth/presentation/pages/provider_onboarding/become_provider_landing_screen.dart';

class ProfileTab extends StatelessWidget {
  final bool showBackButton;

  const ProfileTab({
    super.key,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    
    // Use the specific background color from the design (off-white)
    final bgColor = theme.brightness == Brightness.light ? const Color(0xFFFAFAFA) : colorScheme.surface;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          final user = state.user;
          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              centerTitle: true,
              leading: (showBackButton && Navigator.canPop(context))
                  ? IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryBlue, size: 20),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              automaticallyImplyLeading: false,
              title: Text(
                l10n.navProfile,
                style: TextStyle(
                  color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileHeader(context, user, theme, l10n),
                  const SizedBox(height: 32),
                  
                  // Personal Information Section
                  Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? Colors.white : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.personalInformation ?? 'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          icon: Icons.mail_outline, 
                          label: l10n.email, 
                          value: user.email, 
                          iconBgColor: AppColors.lightYellow,
                          iconColor: AppColors.primaryBlue,
                          theme: theme,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        ),
                        _buildInfoRow(
                          icon: Icons.phone_in_talk, 
                          label: l10n.phone ?? 'Phone', 
                          value: user.phone.isNotEmpty ? user.phone : '+20 123 456 7890', 
                          iconBgColor: AppColors.lightYellow,
                          iconColor: AppColors.primaryBlue,
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Account Section
                  Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light ? Colors.white : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.account ?? 'Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildActionRow(
                          context: context,
                          icon: Icons.person, 
                          title: l10n.editProfile ?? 'Edit Profile', 
                          theme: theme, 
                          onTap: () => _navigateToEditProfile(context, user),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        ),
                        _buildActionRow(
                          context: context,
                          icon: Icons.settings, 
                          title: l10n.settings ?? 'Settings', 
                          theme: theme, 
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                          },
                        ),
                        if (user.userType != 'provider') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                          ),
                          _buildActionRow(
                            context: context,
                            icon: Icons.business_center,
                            title: l10n.joinAsProvider ?? 'Join as Provider',
                            theme: theme,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BecomeProviderLandingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  if (user.userType == 'provider') ...[
                    _buildSwitchModeButton(context, l10n, theme),
                    const SizedBox(height: 16),
                  ],
                  _buildLogoutButton(context, l10n, theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        }
        
        // Fallback for non-authenticated state or loading
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _navigateToEditProfile(BuildContext context, UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user, ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightYellow, width: 3),
            ),
            child: user.imageUrl.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${user.firstName} ${user.lastName}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.brightness == Brightness.dark ? Colors.white : AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _navigateToEditProfile(context, user),
          icon: Icon(Icons.edit, size: 16, color: AppColors.primaryBlue),
          label: Text(
            l10n.editProfile ?? 'Edit Profile',
            style: TextStyle(
              color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.9) : AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: BorderSide(color: AppColors.primaryBlue, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String label, 
    required String value, 
    required Color iconBgColor,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon, 
    required String title, 
    required ThemeData theme, 
    required VoidCallback onTap,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? theme.colorScheme.onSurfaceVariant.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.8) : theme.colorScheme.onSurfaceVariant, size: 20),
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
            Icon(
              isRtl ? Icons.chevron_left : Icons.chevron_right,
              color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.5) : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return InkWell(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isUserModeOverride');
        
        if (context.mounted) {
          context.read<AuthBloc>().add(LogoutRequested());
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.red[300]!.withOpacity(0.15) : AppColors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: theme.brightness == Brightness.dark ? Colors.red[300] : AppColors.red, size: 20),
            const SizedBox(width: 12),
            Text(
              l10n.logOut ?? 'Log Out',
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.red[300] : AppColors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchModeButton(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    // Check which dashboard we are currently in
    final bool isInProviderMode = context.findAncestorWidgetOfExactType<ProviderDashboardScreen>() != null;
    
    // Using localization strings from app.arb
    final String buttonText = isInProviderMode 
        ? l10n.switchToUserMode
        : l10n.switchToProviderMode;

    return InkWell(
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        
        if (isInProviderMode) {
          // Switch to User mode
          await prefs.setBool('isUserModeOverride', true);
          
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false,
            );
          }
        } else {
          // Switch to Provider mode
          await prefs.remove('isUserModeOverride');
          
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
              (route) => false,
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? AppColors.primaryBlue.withOpacity(0.15) 
              : AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInProviderMode ? Icons.person_outline : Icons.business_center_outlined, 
              color: AppColors.primaryBlue, 
              size: 20
            ),
            const SizedBox(width: 12),
            Text(
              buttonText,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.white : AppColors.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
