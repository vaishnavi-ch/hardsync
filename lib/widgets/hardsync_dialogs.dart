import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/sign_in_screen.dart';
import '../services/supabase_service.dart';

class MicPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback? onDismiss;

  const MicPermissionDialog({super.key, required this.onAllow, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFBF9F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF1F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_outlined,
                size: 28,
                color: Color(0xFF335C6D),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enable Microphone Access',
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2522),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'HardSync needs microphone access to run realistic practice conversations and score your speech as you talk.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF5C6661),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52725D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onAllow();
                },
                child: Text(
                  'Allow Microphone',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss?.call();
              },
              child: Text(
                'Not Now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF8A8E89),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineErrorDialog extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineErrorDialog({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFBF9F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF2EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_outlined,
                size: 28,
                color: Color(0xFF844335),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Connection Detected',
              textAlign: TextAlign.center,
              style: GoogleFonts.newsreader(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2522),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection to continue your practice session.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF5C6661),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52725D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(
                  'Retry Connection',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInBottomSheet extends StatefulWidget {
  const SignInBottomSheet({super.key});

  @override
  State<SignInBottomSheet> createState() => _SignInBottomSheetState();
}

class _SignInBottomSheetState extends State<SignInBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.addListener(_onAuthStatusChanged);
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_onAuthStatusChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStatusChanged() {
    if (SupabaseService.instance.isAuthenticated && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Welcome! Authenticated as ${SupabaseService.instance.currentUserName}',
          ),
          backgroundColor: const Color(0xFF597E66),
        ),
      );
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your work email')),
      );
      return;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.instance.signInWithEmail(email, password);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Signed in as $email! Sessions synced to Supabase.',
            ),
            backgroundColor: const Color(0xFF597E66),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication note: $e'),
            backgroundColor: const Color(0xFF844335),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoSignIn() async {
    setState(() => _isLoading = true);
    await SupabaseService.instance.signInAsDemo(
      name: 'Sarah Chen',
      email: 'sarah.chen@leadership.io',
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Signed in as Sarah Chen!'),
          backgroundColor: Color(0xFF597E66),
        ),
      );
    }
  }

  Future<void> _handleOAuth(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    final providerName = provider == OAuthProvider.apple ? 'Apple' : 'Google';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text('Connecting to $providerName... Redirecting to sign-in.'),
            ],
          ),
          backgroundColor: const Color(0xFF2C3E50),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    try {
      await SupabaseService.instance.signInWithOAuth(provider);
      // On Web, the browser will navigate to Google's consent screen.
      // On Mobile, the external browser will open.
      // Modal will pop once user actually authenticates via _onAuthStatusChanged.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final err = e.toString();
        if (err.contains('provider is not enabled') ||
            err.contains('validation_failed')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notice: Google OAuth is not enabled yet in your Supabase project dashboard. Use 1-Click Demo or Email below!',
              ),
              backgroundColor: Color(0xFF844335),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign-in note: $e'),
              backgroundColor: const Color(0xFF844335),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF8F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDCD7CC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Logo & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 24, color: Color(0xFF52745E)),
              const SizedBox(width: 6),
              Text(
                'HardSync',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF152721),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sign In to Save Your Scenarios',
            style: GoogleFonts.newsreader(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E2522),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sync your practice results across your devices.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),

          // 1-Click Demo Sign-In
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A43), // Terracotta accent
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.flash_on,
                size: 18,
                color: Color(0xFFF9D689),
              ),
              label: Text(
                '1-Click Demo Sign-In',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onPressed: _isLoading ? null : _handleDemoSignIn,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2DDCF))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'or sign in with email',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2DDCF))),
            ],
          ),
          const SizedBox(height: 14),

          // Email Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2DDCF)),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your work email...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 13.5,
                ),
                border: InputBorder.none,
                icon: const Icon(
                  Icons.mail_outline,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF597E66),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isLoading ? null : _handleEmailAuth,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Continue with Email',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          if (defaultTargetPlatform != TargetPlatform.iOS) ...[
            // Google Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2DDCF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () => _handleOAuth(OAuthProvider.google),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Color(0xFF4285F4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 0),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SignInScreen(initialIsSignUp: true),
                ),
              );
            },
            child: Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
                children: const [
                  TextSpan(
                    text: 'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF597E66),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
