import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env_config.dart';
import '../services/supabase_service.dart';
import '../services/revenuecat_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';
import 'legal_document_screen.dart';
import 'profile_screen.dart';
import 'web_viewer_screen.dart';

const _navy = HardSyncColors.ink;
const _paper = HardSyncColors.cream;
const _line = HardSyncColors.lilacBorder;
const _red = Color(0xFFFF3F46);

// Google sign-in is not offered on iOS.
bool get _showGoogleSignIn => defaultTargetPlatform != TargetPlatform.iOS;

TextStyle _title(double size) => GoogleFonts.newsreader(
  fontSize: size,
  height: .98,
  fontWeight: FontWeight.w700,
  color: _navy,
);
TextStyle _body({
  double size = 14,
  FontWeight weight = FontWeight.w500,
  Color color = _navy,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  height: 1.4,
  fontWeight: weight,
  color: color,
);
Route<T> _route<T>(Widget page) => MaterialPageRoute<T>(builder: (_) => page);

class SignInScreen extends StatefulWidget {
  final bool initialIsSignUp;
  const SignInScreen({super.key, this.initialIsSignUp = false});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  void initState() {
    super.initState();
    SupabaseService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (SupabaseService.instance.isAuthenticated) return const AccountScreen();
    return widget.initialIsSignUp
        ? const AuthFormScreen(signUp: true)
        : const AuthWelcomeScreen();
  }
}

class _AuthPage extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;
  const _AuthPage({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 20),
    this.maxWidth = 440,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    ),
  );
}

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) => _AuthPage(
    maxWidth: 920,
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final visual = Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF0E9FF),
            child: const AppIllustration(
              HardSyncAssets.illusBetterResponse,
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        );
        final actions = Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 42 : 24,
              wide ? 42 : 12,
              wide ? 42 : 24,
              wide ? 34 : 16,
            ),
            child: Column(
              children: [
                Text(
                  'HardSync',
                  textAlign: TextAlign.center,
                  style: _title(38),
                ),
                const SizedBox(height: 4),
                Text(
                  'Practice today.\nLead with confidence tomorrow.',
                  textAlign: TextAlign.center,
                  style: _body(size: 15),
                ),
                const Spacer(),
                if (_showGoogleSignIn) ...[
                  _SocialButton(
                    icon: const _GoogleMark(),
                    label: 'Continue with Google',
                    onPressed: () => _oauth(context, OAuthProvider.google),
                  ),
                  const SizedBox(height: 9),
                ],
                _SocialButton(
                  icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                  label: 'Continue with Apple',
                  onPressed: () => _appleSignIn(context),
                ),
                const SizedBox(height: 9),
                _SocialButton(
                  icon: const Icon(Icons.mail_outline, color: _navy, size: 20),
                  label: 'Continue with Email',
                  onPressed: () =>
                      Navigator.push(context, _route(const AuthFormScreen())),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HardSyncColors.violetDark,
                      side: const BorderSide(color: HardSyncColors.lilacBorder),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      _route(const AuthFormScreen(signUp: true)),
                    ),
                    child: Text(
                      'Create an account',
                      style: _body(size: 14, weight: FontWeight.w700),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'By continuing, you agree to our',
                  style: _body(size: 11.5, color: const Color(0xFF60627A)),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        _route(
                          const WebViewerScreen(
                            title: 'Terms of Service',
                            url: EnvConfig.termsOfServiceUrl,
                            fallbackWidget: LegalDocumentScreen(
                              document: LegalDocument.terms,
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Terms of Service'),
                    ),
                    Text(
                      'and',
                      style: _body(size: 11.5, color: const Color(0xFF60627A)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        _route(
                          const WebViewerScreen(
                            title: 'Privacy Policy',
                            url: EnvConfig.privacyPolicyUrl,
                            fallbackWidget: LegalDocumentScreen(
                              document: LegalDocument.privacy,
                            ),
                          ),
                        ),
                      ),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          children: [visual, actions],
        );
      },
    ),
  );
  Future<void> _oauth(BuildContext context, OAuthProvider provider) async {
    try {
      await SupabaseService.instance.signInWithOAuth(provider);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _appleSignIn(BuildContext context) async {
    try {
      await SupabaseService.instance.signInWithApple();
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }
}

class AuthFormScreen extends StatefulWidget {
  final bool signUp;
  const AuthFormScreen({super.key, this.signUp = false});
  @override
  State<AuthFormScreen> createState() => _AuthFormScreenState();
}

class _AuthFormScreenState extends State<AuthFormScreen> {
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _hidden = true,
      _hiddenConfirm = true,
      _remember = true,
      _loading = false;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide the decorative illustration once the keyboard is up so the fields
    // and the primary button below them still fit above it without the user
    // having to hunt for a scroll position that reveals the button.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return _AuthPage(
    child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onTap: () => Navigator.maybePop(context)),
          const SizedBox(height: 14),
          Text(
            widget.signUp ? 'Create your account' : 'Welcome back!',
            style: _title(29),
          ),
          const SizedBox(height: 5),
          Text(
            widget.signUp
                ? 'Start building your communication superpowers.'
                : 'Good conversations start here.',
            style: _body(size: 13, color: const Color(0xFF555A91)),
          ),
          if (!widget.signUp && !keyboardOpen) ...[
            const SizedBox(height: 8),
            const SizedBox(
              height: 190,
              width: double.infinity,
              child: AppIllustration(HardSyncAssets.illusManager11),
            ),
          ] else if (!widget.signUp)
            const SizedBox(height: 14)
          else
            const SizedBox(height: 30),
          if (widget.signUp) ...[
            _Field(
              controller: _name,
              hint: 'Full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 11),
          ],
          _Field(
            controller: _email,
            hint: 'Email address',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 11),
          _Field(
            controller: _password,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscure: _hidden,
            suffix: IconButton(
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(
                _hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
                color: const Color(0xFF565C89),
              ),
            ),
          ),
          if (widget.signUp) ...[
            const SizedBox(height: 11),
            _Field(
              controller: _confirm,
              hint: 'Confirm password',
              icon: Icons.lock_outline,
              obscure: _hiddenConfirm,
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _hiddenConfirm = !_hiddenConfirm),
                icon: Icon(
                  _hiddenConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: const Color(0xFF565C89),
                ),
              ),
            ),
          ],
          if (!widget.signUp)
            Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: _remember,
                    activeColor: HardSyncColors.violet,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => setState(() => _remember = v ?? true),
                  ),
                ),
                Text(
                  'Remember me',
                  style: _body(size: 11, color: const Color(0xFF666A87)),
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    _route(const ResetPasswordScreen()),
                  ),
                  child: Text(
                    'Forgot password?',
                    style: _body(
                      size: 11,
                      color: HardSyncColors.violetDark,
                    ).copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ],
            )
          else
            const SizedBox(height: 12),
          _PrimaryButton(
            label: widget.signUp ? 'Create account' : 'Log in',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 14),
          _OrDivider(label: widget.signUp ? 'or sign up with' : 'or'),
          const SizedBox(height: 14),
          if (_showGoogleSignIn) ...[
            _SocialButton(
              icon: const _GoogleMark(),
              label: widget.signUp ? 'Sign up with Google' : 'Continue with Google',
              onPressed: () => _oauth(OAuthProvider.google),
            ),
            const SizedBox(height: 9),
          ],
          _SocialButton(
            icon: const Icon(Icons.apple, color: Colors.black, size: 21),
            label: widget.signUp ? 'Sign up with Apple' : 'Continue with Apple',
            onPressed: _appleSignIn,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                _route(AuthFormScreen(signUp: !widget.signUp)),
              ),
              child: Text.rich(
                TextSpan(
                  text: widget.signUp
                      ? 'Already have an account? '
                      : "Don't have an account? ",
                  children: [
                    TextSpan(
                      text: widget.signUp ? 'Log in' : 'Sign up',
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: HardSyncColors.violetDark,
                      ),
                    ),
                  ],
                ),
                style: _body(size: 11.5, color: const Color(0xFF60627A)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty ||
        _password.text.isEmpty ||
        (widget.signUp && _name.text.trim().isEmpty)) {
      _showError(context, 'Please complete every field.');
      return;
    }
    if (widget.signUp) {
      if (_password.text.length < 8) {
        _showError(context, 'Password must be at least 8 characters.');
        return;
      }
      if (_password.text != _confirm.text) {
        _showError(context, 'Passwords do not match. Please re-enter them.');
        return;
      }
    }
    setState(() => _loading = true);
    try {
      if (widget.signUp) {
        await SupabaseService.instance.signUpWithEmail(
          _email.text.trim(),
          _password.text,
          fullName: _name.text.trim(),
        );
        if (!mounted) return;
        if (SupabaseService.instance.isAuthenticated) {
          // Signed in already: the launch gate shows the avatar picker next.
          final messenger = ScaffoldMessenger.of(context);
          Navigator.popUntil(context, (route) => route.isFirst);
          messenger.showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF1F8A5B),
              content: Text('Account created successfully. Welcome!'),
            ),
          );
        } else {
          // Email confirmation is required before a session exists.
          Navigator.pushReplacement(
            context,
            _route(SignUpSuccessScreen(email: _email.text.trim())),
          );
        }
      } else {
        await SupabaseService.instance.signInWithEmail(
          _email.text.trim(),
          _password.text,
        );
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauth(OAuthProvider provider) async {
    try {
      await SupabaseService.instance.signInWithOAuth(provider);
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }

  Future<void> _appleSignIn() async {
    try {
      await SupabaseService.instance.signInWithApple();
    } catch (e) {
      if (mounted) _showError(context, e);
    }
  }
}

class SignUpSuccessScreen extends StatelessWidget {
  final String email;
  const SignUpSuccessScreen({super.key, required this.email});
  @override
  Widget build(BuildContext context) => _AuthPage(
    child: Column(
      children: [
        const SizedBox(height: 24),
        const Expanded(
          child: AppIllustration(HardSyncAssets.aiWhisperCoachAssist),
        ),
        const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFF1F8A5B),
          child: Icon(Icons.check, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 14),
        Text('Account created!', style: _title(28)),
        const SizedBox(height: 8),
        Text(
          "We've sent a confirmation link to\n$email\nOpen it, then log in to choose your avatar and get started.",
          textAlign: TextAlign.center,
          style: _body(size: 13, color: const Color(0xFF555A91)),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 49,
          child: _PrimaryButton(
            label: 'Go to log in',
            onPressed: () => Navigator.pushReplacement(
              context,
              _route(const AuthFormScreen()),
            ),
          ),
        ),
        const Spacer(),
      ],
    ),
  );
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onTap: () => Navigator.pop(context)),
        const SizedBox(height: 24),
        Text('Reset your password', style: _title(27)),
        const SizedBox(height: 7),
        Text(
          "Enter your email and we'll send you\nreset instructions.",
          style: _body(size: 13, color: const Color(0xFF555A91)),
        ),
        const SizedBox(height: 22),
        const Expanded(
          child: AppIllustration(HardSyncAssets.illusScriptBuilder),
        ),
        _Field(
          controller: _email,
          hint: 'Email address',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _PrimaryButton(
          label: 'Send reset link',
          loading: _loading,
          onPressed: _send,
        ),
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to log in'),
          ),
        ),
      ],
    ),
  );
  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      _showError(context, 'Enter your email address.');
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.sendPasswordReset(_email.text.trim());
      if (mounted) {
        Navigator.push(
          context,
          _route(EmailSentScreen(email: _email.text.trim())),
        );
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class EmailSentScreen extends StatelessWidget {
  final String email;
  const EmailSentScreen({super.key, required this.email});
  @override
  Widget build(BuildContext context) => _AuthPage(
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _BackButton(onTap: () => Navigator.pop(context)),
        ),
        const SizedBox(height: 24),
        const Expanded(
          child: AppIllustration(HardSyncAssets.aiWhisperCoachAssist),
        ),
        Text('Check your email', style: _title(28)),
        const SizedBox(height: 8),
        Text(
          "We've sent a password reset link to\n$email",
          textAlign: TextAlign.center,
          style: _body(size: 13, color: const Color(0xFF555A91)),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: HardSyncColors.lilacMist,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.mail_outline, color: HardSyncColors.violet),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Didn't receive the email?\nCheck your spam folder or try again.",
                  style: _body(size: 11.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Resend email'),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          child: const Text('Back to log in'),
        ),
      ],
    ),
  );
}

class AccountScreen extends StatelessWidget {
  final bool embedded;
  const AccountScreen({super.key, this.embedded = false});
  @override
  Widget build(BuildContext context) {
    return ProfileScreen(embedded: embedded);
  }
}

class LogoutDialog extends StatefulWidget {
  final bool showSignedOut;
  const LogoutDialog({super.key, this.showSignedOut = true});
  @override
  State<LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  bool loading = false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 31,
          backgroundColor: Color(0xFFFFECEC),
          child: Icon(Icons.logout, color: _red, size: 29),
        ),
        const SizedBox(height: 16),
        Text('Log out?', style: _title(23)),
        const SizedBox(height: 7),
        Text(
          "You'll need to sign in again\nto access your progress.",
          textAlign: TextAlign.center,
          style: _body(size: 13, color: const Color(0xFF555A91)),
        ),
        const SizedBox(height: 18),
        _DangerButton(label: 'Log out', loading: loading, onPressed: _logout),
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF5F3F6),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _navy)),
          ),
        ),
      ],
    ),
  );
  Future<void> _logout() async {
    setState(() => loading = true);
    await SupabaseService.instance.signOut();
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.showSignedOut && context.mounted) {
      Navigator.push(context, _route(const SignedOutScreen()));
    }
  }
}

class SignedOutScreen extends StatelessWidget {
  const SignedOutScreen({super.key});
  @override
  Widget build(BuildContext context) => _AuthPage(
    child: Column(
      children: [
        const Spacer(),
        const Expanded(
          flex: 4,
          child: AppIllustration(HardSyncAssets.illusPracticeReflectImprove),
        ),
        Text("You're signed out", style: _title(27)),
        const SizedBox(height: 8),
        Text(
          'Thanks for being part of HardSync.\nSee you soon!',
          textAlign: TextAlign.center,
          style: _body(size: 13, color: const Color(0xFF555A91)),
        ),
        const Spacer(),
        _PrimaryButton(
          label: 'Sign in again',
          onPressed: () => Navigator.pushReplacement(
            context,
            _route(const AuthWelcomeScreen()),
          ),
        ),
      ],
    ),
  );
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool loading = false;
  @override
  Widget build(BuildContext context) => _AuthPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onTap: () => Navigator.pop(context)),
        const SizedBox(height: 22),
        Text('Delete your account', style: _title(27)),
        const SizedBox(height: 6),
        Text(
          "We're sorry to see you go. This action\ncannot be undone.",
          style: _body(size: 12.5, color: const Color(0xFF555A91)),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F7),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Column(
            children: [
              _DeleteFact(
                icon: Icons.inventory_2_outlined,
                title: 'Your progress and data',
                detail: 'will be permanently deleted',
              ),
              _DeleteFact(
                icon: Icons.history,
                title: "You'll lose access to your",
                detail: 'practice history',
              ),
              _DeleteFact(
                icon: Icons.verified_user_outlined,
                title: 'Store subscription (if any)',
                detail: 'must be canceled separately before deletion',
              ),
            ],
          ),
        ),
        const Spacer(),
        if (!kIsWeb && RevenueCatService.instance.isConfigured) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => RevenueCatUI.presentCustomerCenter(),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage store subscription'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _DangerButton(
          label: 'Delete account',
          loading: loading,
          onPressed: _delete,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              _route(
                const WebViewerScreen(
                  title: 'Account Deletion Portal',
                  url: EnvConfig.accountDeletionUrl,
                ),
              ),
            ),
            icon: const Icon(Icons.open_in_browser_rounded, size: 16),
            label: const Text(
              'Online Data Deletion Instructions',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
  Future<void> _delete() async {
    setState(() => loading = true);
    try {
      await SupabaseService.instance.deleteAccount();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          _route(const AccountDeletedScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) _showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});
  @override
  Widget build(BuildContext context) => _AuthPage(
    child: Column(
      children: [
        const Spacer(),
        const Expanded(
          flex: 4,
          child: AppIllustration(HardSyncAssets.illusExecutiveChallenge),
        ),
        Text('Account deleted', style: _title(28)),
        const SizedBox(height: 8),
        Text(
          'Your account has been permanently\ndeleted.\nThanks for giving HardSync a try.',
          textAlign: TextAlign.center,
          style: _body(size: 13, color: const Color(0xFF555A91)),
        ),
        const Spacer(),
        _PrimaryButton(
          label: 'Back to home',
          onPressed: () => Navigator.pushReplacement(
            context,
            _route(const AuthWelcomeScreen()),
          ),
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 51,
    child: TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: _body(size: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF565C89)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: .72),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: HardSyncColors.violet,
            width: 1.4,
          ),
        ),
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 51,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: HardSyncColors.violet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const _DangerButton({
    required this.label,
    this.onPressed,
    this.loading = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .78),
        side: const BorderSide(color: _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      onPressed: onPressed,
      icon: icon,
      label: Text(label, style: _body(size: 13, weight: FontWeight.w600)),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => Text(
    'G',
    style: GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF4285F4),
    ),
  );
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    padding: EdgeInsets.zero,
    alignment: Alignment.centerLeft,
    icon: const Icon(Icons.arrow_back_ios_new, size: 19, color: _navy),
  );
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({this.label = 'OR'});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: _line)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          label.toUpperCase(),
          style: _body(size: 10, color: const Color(0xFF696C82)),
        ),
      ),
      const Expanded(child: Divider(color: _line)),
    ],
  );
}

class _DeleteFact extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  const _DeleteFact({
    required this.icon,
    required this.title,
    required this.detail,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: Colors.white,
          child: Icon(icon, color: _navy, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: '$title\n',
              style: _body(size: 12, weight: FontWeight.w700),
              children: [
                TextSpan(
                  text: detail,
                  style: _body(size: 11.5, color: const Color(0xFF666A87)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

void _showError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _red,
      ),
    );
