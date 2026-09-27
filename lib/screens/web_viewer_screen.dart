import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/hardsync_theme.dart';

/// Reusable in-app web viewer that renders GitHub-hosted HTML pages
/// (Privacy Policy, Terms of Service, Account Deletion, FAQs, Landing Page).
class WebViewerScreen extends StatefulWidget {
  final String title;
  final String url;
  final Widget? fallbackWidget;

  const WebViewerScreen({
    super.key,
    required this.title,
    required this.url,
    this.fallbackWidget,
  });

  @override
  State<WebViewerScreen> createState() => _WebViewerScreenState();
}

class _WebViewerScreenState extends State<WebViewerScreen> {
  WebViewController? _controller;
  double _progress = 0.0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initWebView();
    } else {
      _isLoading = false;
    }
  }

  void _initWebView() {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _progress = progress / 100.0;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
      _controller = controller;
    } catch (_) {
      _hasError = true;
      _isLoading = false;
    }
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: widget.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Link copied: ${widget.url}',
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
        ),
        backgroundColor: HardSyncColors.violet,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback && widget.fallbackWidget != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            TextButton.icon(
              onPressed: () => setState(() => _showFallback = false),
              icon: const Icon(Icons.language, size: 18),
              label: const Text('Live Web'),
            ),
          ],
        ),
        body: widget.fallbackWidget!,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: HardSyncColors.ink,
              ),
            ),
            Text(
              widget.url.replaceFirst('https://', ''),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: HardSyncColors.inkMuted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: _copyUrl,
          ),
          if (_controller != null)
            IconButton(
              tooltip: 'Reload',
              icon: const Icon(Icons.refresh_rounded, size: 20),
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _controller?.reload();
              },
            ),
          if (widget.fallbackWidget != null)
            IconButton(
              tooltip: 'Offline Document',
              icon: const Icon(Icons.article_outlined, size: 20),
              onPressed: () => setState(() => _showFallback = true),
            ),
        ],
        bottom: _isLoading && _progress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: HardSyncColors.lilacBorder,
                  color: HardSyncColors.violet,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_browser_rounded, size: 48, color: HardSyncColors.violet),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: GoogleFonts.newsreader(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SelectableText(
                widget.url,
                style: GoogleFonts.plusJakartaSans(color: HardSyncColors.violet, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _copyUrl,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy URL'),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: HardSyncColors.inkMuted),
              const SizedBox(height: 16),
              Text(
                'Unable to load live page',
                style: GoogleFonts.newsreader(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: HardSyncColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection or view the offline version.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: HardSyncColors.inkMuted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isLoading = true;
                      });
                      _controller?.reload();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                  if (widget.fallbackWidget != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showFallback = true),
                      icon: const Icon(Icons.article_outlined, size: 18),
                      label: const Text('View Offline Text'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HardSyncColors.violet,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return WebViewWidget(controller: _controller!);
  }
}
