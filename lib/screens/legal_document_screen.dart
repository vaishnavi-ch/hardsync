import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/env_config.dart';
import '../theme/hardsync_theme.dart';
import 'web_viewer_screen.dart';

enum LegalDocument { terms, privacy }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    final webUrl = privacy ? EnvConfig.privacyPolicyUrl : EnvConfig.termsOfServiceUrl;
    final titleText = privacy ? 'Privacy Policy' : 'Terms of Service';

    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      appBar: AppBar(
        backgroundColor: HardSyncColors.cream,
        title: Text(titleText),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewerScreen(
                  title: titleText,
                  url: webUrl,
                  fallbackWidget: this,
                ),
              ),
            ),
            icon: const Icon(Icons.language, size: 18),
            label: const Text('Live Web'),
          ),
        ],
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    privacy
                        ? 'HardSync Privacy Policy'
                        : 'HardSync Terms of Service',
                    style: GoogleFonts.newsreader(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: HardSyncColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Effective 28 September 2026', style: _body(13)),
                  const SizedBox(height: 24),
                  ...(privacy ? _privacySections : _termsSections).map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(section.$1, style: _heading),
                          const SizedBox(height: 7),
                          Text(section.$2, style: _body(15)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle get _heading => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: HardSyncColors.ink,
  );

  static TextStyle _body(double size) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    height: 1.55,
    color: HardSyncColors.inkMuted,
  );
}

const _privacySections = <(String, String)>[
  (
    'What HardSync collects',
    'We process account details, profile choices, course progress, practice text and transcripts, session results, subscription status, and technical diagnostics. During a live voice or video practice, your microphone or camera stream is sent to the call provider so the session can work. HardSync never records or stores that stream. Session transcripts and reports may be saved to your account.',
  ),
  (
    'How information is used',
    'We use information to authenticate you, deliver courses and AI practice, generate feedback, maintain progress, verify subscriptions, prevent abuse, provide support, and improve reliability.',
  ),
  (
    'Service providers',
    'HardSync uses Supabase for authentication and application data, Google Gemini for text practice, live voice, and analysis, Tavus (running on Daily) for live video avatar calls, and RevenueCat for subscriptions. Live call media is processed by Google Gemini or Tavus/Daily, depending on the mode you choose, under their own terms and privacy policies. HardSync asks for your permission before your first session shares data with these providers. Tavus, which runs speech recognition for video calls, may keep a call transcript under its own policy.',
  ),
  (
    'Microphone and camera',
    'Microphone and camera access is requested only when you start a voice or video feature. Audio and video are streamed live to the call provider and are never recorded or stored by HardSync. Your transcript and session report may still be saved to your account.',
  ),
  (
    'Purchases',
    'Apple, Google, and RevenueCat process store purchase and subscription information. HardSync receives product, entitlement, transaction, renewal, and expiration status; it does not receive your full payment card details.',
  ),
  (
    'Retention and security',
    'We retain account data while your account is active and only as long as needed to provide the service, meet legal obligations, resolve disputes, prevent fraud, and enforce agreements. Data is encrypted in transit. Access controls restrict private application data to its owner and authorized service processes.',
  ),
  (
    'Your choices and deletion',
    'You can manage permissions in device settings, manage subscriptions through the store, and delete your HardSync account from Profile. Account deletion removes associated application data, except information that must be retained for security, fraud prevention, financial records, or legal compliance.',
  ),
  (
    'Children',
    'HardSync is a professional communication training service and is not directed to children. Do not create an account if you are below the minimum age required to consent to online services in your country.',
  ),
  (
    'Contact',
    'Questions and deletion requests can be submitted by email to vaishnavi26ch@gmail.com, or through our web portal: https://vaishnavi-ch.github.io/hardsync/privacy.html and https://vaishnavi-ch.github.io/hardsync/account-deletion.html.',
  ),
];

const _termsSections = <(String, String)>[
  (
    'Using HardSync',
    'You may use HardSync for lawful personal or professional communication practice. You are responsible for your account, the content you submit, and ensuring you have permission to record or upload any other person.',
  ),
  (
    'AI-generated content',
    'AI responses and coaching may be incomplete or inaccurate. Treat them as practice guidance rather than professional, legal, medical, employment, or financial advice. Do not rely on HardSync to make high-impact decisions about another person.',
  ),
  (
    'Subscriptions',
    'Paid digital features are purchased through the applicable store and are subject to the terms shown before purchase. You can restore purchases and manage or cancel a subscription through the store. Deleting a HardSync account does not itself cancel store billing.',
  ),
  (
    'Acceptable use',
    'Do not misuse the service, attempt unauthorized access, interfere with other users, submit unlawful or abusive material, impersonate others, reverse engineer protected services, or use generated content to deceive or harm people.',
  ),
  (
    'Your content',
    'You retain rights in content you submit. You grant HardSync and its service providers permission to process that content only as needed to operate, secure, and improve the service and provide requested AI feedback.',
  ),
  (
    'Availability',
    'Features may depend on network access and third-party providers. We may change or discontinue features, but active subscriptions remain subject to applicable store rules and consumer law.',
  ),
  (
    'Account termination',
    'You may delete your account in Profile. We may restrict accounts that materially violate these terms, threaten service security, or create legal risk.',
  ),
  (
    'Contact',
    'Questions about these terms can be submitted by email to vaishnavi26ch@gmail.com, or viewed online at https://vaishnavi-ch.github.io/hardsync/terms.html.',
  ),
];
