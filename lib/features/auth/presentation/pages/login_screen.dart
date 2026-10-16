import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:algohary_project/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:algohary_project/features/dashboard/presentation/pages/provider_dashboard_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'signup_screen.dart';
import '../../../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final bool isProvider;
  
  const LoginScreen({
    super.key,
    this.isProvider = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    // Determine if Apple login should be shown
    // Note: Theme.of(context).platform gets the current platform safely (even on web)
    final bool isIOS = theme.platform == TargetPlatform.iOS;
    final bool showAppleLogin = kIsWeb || isIOS;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo
              Center(
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              
              // Texts
              Text(
                l10n.loginWelcomeBack,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.brightness == Brightness.dark ? AppColors.lightYellow : const Color(0xFF325A65),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginSubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              
              // Email Field
              _buildTextField(
                hintText: l10n.loginEmailOrPhone,
                icon: Icons.email_outlined,
                theme: theme,
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              
              // Password Field
              _buildTextField(
                hintText: l10n.loginPassword,
                icon: Icons.lock_outline,
                theme: theme,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 12),
              
              // Forgot Password
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(l10n),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.brightness == Brightness.dark ? AppColors.lightYellow : const Color(0xFF325A65),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.loginForgotPassword,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Login Button
              SizedBox(
                height: 56,
                child: BlocConsumer<AuthBloc, AuthState>(
                  // Only react to the result of a login attempt, and only on the
                  // screen that is currently visible. Otherwise stacked login
                  // screens (user -> provider) / any later AuthSuccess emission
                  // would trigger duplicate navigation and duplicate snackbars.
                  listenWhen: (previous, current) =>
                      previous is AuthLoading &&
                      (current is AuthSuccess || current is AuthFailure),
                  listener: (context, state) async {
                    if (ModalRoute.of(context)?.isCurrent == false) return;
                      if (state is AuthSuccess) {
                      final prefs = await SharedPreferences.getInstance();
                      
                      if (!widget.isProvider && state.user.userType == 'provider') {
                        // Provider logging in from User Login
                        await prefs.setBool('isUserModeOverride', true);
                      } else {
                        await prefs.remove('isUserModeOverride');
                      }
                      
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => (state.user.userType == 'provider' && widget.isProvider)
                                ? const ProviderDashboardScreen()
                                : const DashboardScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } else if (state is AuthFailure) {
                      debugPrint('Login Error: ${state.message}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.message == 'user-not-found' || state.message == 'wrong-password' || state.message == 'invalid-credential'
                                ? (l10n.errorInvalidCredential)
                                : state.message == 'invalid-email'
                                    ? l10n.errorInvalidEmail
                                : state.message == 'user-blocked'
                                    ? l10n.errorUserBlocked
                                    : state.message == 'not-a-provider'
                                        ? l10n.errorNotProvider
                                        : l10n.errorGeneric,
                          ),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text;
                              if (email.isNotEmpty && password.isNotEmpty) {
                                context.read<AuthBloc>().add(
                                      LoginSubmitted(
                                        email: email, 
                                        password: password,
                                        isProvider: widget.isProvider,
                                      ),
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF325A65),
                        foregroundColor: Colors.white,
                        elevation: 0, // No shadows
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: state is AuthLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(l10n.loginButton),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              // OR Divider
              Row(
                children: [
                  Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.loginOr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))),
                ],
              ),
              const SizedBox(height: 32),
              
              // Social Login Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildSocialButton('assets/icons/google.png', theme)),
                  if (showAppleLogin) ...[
                    const SizedBox(width: 16),
                    Expanded(child: _buildSocialButton('assets/icons/apple-logo.png', theme)),
                  ],
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Create Account or Provider Login
              if (widget.isProvider)
                const SizedBox.shrink()
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.loginNoAccount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.dark ? AppColors.lightYellow : const Color(0xFF325A65),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.loginCreateAccount,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Login as Provider Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(isProvider: true),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade700,
                  ),
                  child: Text(
                    l10n.loginAsProvider,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    required ThemeData theme,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
      autofillHints: isPassword ? const [AutofillHints.password] : const [AutofillHints.email],
      autocorrect: false,
      enableSuggestions: !isPassword,
      style: TextStyle(color: theme.brightness == Brightness.dark ? AppColors.lightYellow : theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.brightness == Brightness.dark ? AppColors.lightYellow.withValues(alpha: 0.5) : theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: theme.brightness == Brightness.dark ? AppColors.lightYellow : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: theme.brightness == Brightness.dark ? AppColors.lightYellow : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog(AppLocalizations l10n) async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        l10n: l10n,
      ),
    );
    if (email == null || email.isEmpty) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!Validators.isValidEmail(email)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorInvalidEmail)));
      return;
    }

    try {
      await AuthRepository().sendPasswordResetEmail(email);
      messenger.showSnackBar(SnackBar(content: Text(l10n.forgotPasswordSent)));
    } catch (e) {
      final error = e.toString();
      // Do not reveal whether an account exists for this e-mail.
      final message = error.contains('user-not-found')
          ? l10n.forgotPasswordSent
          : error.contains('invalid-email')
              ? l10n.errorInvalidEmail
              : l10n.errorGeneric;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildSocialButton(String assetPath, ThemeData theme) {
    // Note: No shadows, as requested by the user.
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Image.asset(
          assetPath,
          height: 24,
          width: 24,
        ),
      ),
    );
  }
}

/// Dialog that owns its [TextEditingController] so it is disposed only after
/// the dialog route has completely left the tree.
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final AppLocalizations l10n;

  const _ForgotPasswordDialog({required this.initialEmail, required this.l10n});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.forgotPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.forgotPasswordMessage),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
            decoration: InputDecoration(
              hintText: l10n.loginEmailOrPhone,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.btnCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n.forgotPasswordSend),
        ),
      ],
    );
  }
}
