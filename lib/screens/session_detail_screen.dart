import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/backend_service.dart';
import '../services/supabase_service.dart';
import '../theme/hardsync_theme.dart';
import '../theme/hardsync_assets.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  final bool autoAnalyze;
  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    this.autoAnalyze = false,
  });
  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Map<String, dynamic>? _report;
  String? _error;
  bool _requesting = false;
  String _tab = 'Insights';
  String _query = '';
  Timer? _poll;
  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool initial = false, bool renew = false}) async {
    try {
      Map<String, dynamic>? report;
      try {
        report = await BackendService.request('/api/sessions/detail', {
          'sessionId': widget.sessionId,
        });
      } catch (e) {
        if (SupabaseService.instance.isAuthenticated) {
          final cloudSession = await SupabaseService.instance
              .fetchSessionDetail(widget.sessionId);
          if (cloudSession != null) {
            final rep = cloudSession['report'] as Map<String, dynamic>? ?? {};
            final turns = (cloudSession['transcript'] as List? ?? [])
                .map(
                  (t) => {
                    'speaker': t['speaker_name'] ?? t['speaker'] ?? 'Speaker',
                    'role': t['speaker'] == 'user' ? 'user' : 'assistant',
                    'text': t['text'] ?? '',
                    'seconds': ((t['timestamp_ms'] as num? ?? 0) / 1000)
                        .round(),
                  },
                )
                .toList();

            report = {
              'id': cloudSession['id'],
              'title':
                  cloudSession['scenarios']?['title'] ??
                  rep['title'] ??
                  'Scenario',
              'completedAt': cloudSession['created_at'],
              'durationSeconds': cloudSession['duration_seconds'],
              'mode': rep['mode'] ?? 'video',
              'transcript': turns,
              'analysis': cloudSession['analysis'],
            };
          }
        }
        if (report == null) rethrow;
      }

      if (!mounted) return;
      setState(() {
        _report = report;
        _error = null;
      });
      if (initial && widget.autoAnalyze && report['analysis'] == null) {
        await _analyze();
      } else if (report['analysis']?['status'] == 'processing') {
        _schedule();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _schedule() {
    _poll?.cancel();
    _poll = Timer(const Duration(seconds: 3), () => _load());
  }

  Future<void> _analyze() async {
    if (_requesting) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      final value = await BackendService.request('/api/sessions/analyze', {
        'sessionId': widget.sessionId,
      });
      if (!mounted) return;
      setState(() {
        _report!['analysis'] = value;
      });
      if (value['status'] == 'processing') _schedule();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  String _time(dynamic seconds) {
    final n = (seconds as num? ?? 0).toInt();
    return '${(n ~/ 60).toString().padLeft(2, '0')}:${(n % 60).toString().padLeft(2, '0')}';
  }

  Widget _card(Widget child, {Color? color}) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: HardSyncColors.border),
    ),
    child: child,
  );
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
  );
  Widget _moment(Map item, {bool delivery = false}) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(onPressed: null, child: Text(_time(item['seconds']))),
            Expanded(
              child: Text(
                '${item[delivery ? 'area' : 'title'] ?? item['name'] ?? 'Conversation moment'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        if (item['quote'] != null)
          SelectableText(
            '"${item['quote']}"',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        const SizedBox(height: 10),
        Text('${item[delivery ? 'observation' : 'feedback'] ?? ''}'),
        if ((item[delivery ? 'suggestion' : 'suggestedPhrase'] ?? '')
            .toString()
            .isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '${delivery ? 'Try next time' : 'Suggested phrase'}: ${item[delivery ? 'suggestion' : 'suggestedPhrase']}',
              style: const TextStyle(color: HardSyncColors.primary),
            ),
          ),
      ],
    ),
  );
  List<Widget> _insights() {
    final a = _report!['analysis'] as Map?;
    if (_requesting || a?['status'] == 'processing') {
      return [
        _card(
          const Column(
            children: [
              AppIllustration(
                HardSyncAssets.aiAnalyticsPondering,
                height: 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(strokeWidth: 2.5),
              SizedBox(height: 16),
              Text(
                'Putting together your report...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Your transcript is available while AI analysis is prepared.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }
    if (a == null || a['status'] == 'failed') {
      return [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heading('Your practice report'),
              Text(
                a?['message'] ??
                    'Get feedback based on the session transcript.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _analyze,
                child: Text(a == null ? 'Analyze session' : 'Retry analysis'),
              ),
            ],
          ),
        ),
      ];
    }
    if (a['status'] == 'insufficient_data') return [_card(Text(a['summary']))];
    return [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Your practice report'),
            Text(a['summary'] ?? ''),
            const SizedBox(height: 14),
            Text(
              'AI feedback is based on your words. Audio and video are not recorded or analyzed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      if ((a['skills'] as List? ?? []).isNotEmpty)
        _heading('Core communication skills'),
      for (final item in a['skills'] as List? ?? []) _moment(item),
      if ((a['delivery'] as List? ?? []).isNotEmpty)
        _heading('Confidence & delivery'),
      for (final item in a['delivery'] as List? ?? [])
        _moment(item, delivery: true),
      if ((a['limitations'] as List? ?? []).isNotEmpty)
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _heading('What could be assessed'),
              for (final l in a['limitations'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(l.toString()),
                ),
            ],
          ),
        ),
      if ((a['moments'] as List? ?? []).isNotEmpty)
        _heading('Conversation moments'),
      for (final item in a['moments'] as List? ?? []) _moment(item),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_heading('Key takeaway'), Text(a['takeaway'] ?? '')],
        ),
        color: HardSyncColors.primarySubtle,
      ),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heading('Your next practice'),
            for (final step in a['nextSteps'] as List? ?? [])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(step.toString()),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _transcript() {
    final turns = (_report!['transcript'] as List)
        .where(
          (t) => '${t['speaker']} ${t['text']}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return [
      TextField(
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          labelText: 'Search transcript',
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: 18),
      if (turns.isEmpty) const Text('No matching conversation turns.'),
      for (final t in turns)
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${t['speaker']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(_time(t['seconds'])),
                  if (t['role'] != 'user' && t['speaker'] != 'You') ...[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Report this response',
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _reportTurn(t),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(t['text']),
            ],
          ),
          color: t['role'] == 'user' || t['speaker'] == 'You'
              ? HardSyncColors.primarySubtle
              : null,
        ),
    ];
  }

  Future<void> _reportTurn(Map<String, dynamic> turn) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report this response'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This flags the response for our team to review. Add any context that would help (optional).',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What was wrong with this response?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.instance.reportAiResponse(
        sessionId: widget.sessionId,
        reportedText: '${turn['text']}',
        speaker: '${turn['speaker']}',
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — we\'ll review this response.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not submit report: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final mode = report?['mode'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session review'),
        actions: [
          IconButton(
            tooltip: 'Copy report',
            icon: const Icon(Icons.copy),
            onPressed: report == null
                ? null
                : () async {
                    final copy = Map<String, dynamic>.from(report);
                    await Clipboard.setData(
                      ClipboardData(
                        text: const JsonEncoder.withIndent('  ').convert(copy),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report copied')),
                      );
                    }
                  },
          ),
          IconButton(
            tooltip: 'Refresh session',
            onPressed: () => _load(renew: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: report == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Text(_error!),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      report['title'] ?? 'Scenario',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${mode.toString().toUpperCase()}  /  ${_time(report['durationSeconds'])}  /  ${(report['completedAt'] ?? '').toString().replaceFirst('T', ' ').split('.').first}',
                    ),
                    const SizedBox(height: 22),
                    if (_error != null)
                      _card(
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SegmentedButton<String>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: HardSyncColors.violet,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: HardSyncColors.violet,
                        side: BorderSide(color: HardSyncColors.violet),
                      ),
                      segments: [
                        const ButtonSegment(
                          value: 'Insights',
                          label: Text('Insights'),
                        ),
                        ButtonSegment(
                          value: 'Transcript',
                          label: Text(mode == 'text' ? 'Chat' : 'Transcript'),
                        ),
                      ],
                      selected: {_tab},
                      onSelectionChanged: (v) => setState(() => _tab = v.first),
                    ),
                    const SizedBox(height: 24),
                    if (_tab == 'Insights') ..._insights(),
                    if (_tab == 'Transcript') ..._transcript(),
                  ],
                ),
              ),
            ),
    );
  }
}
