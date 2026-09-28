import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/debrief_report.dart';
import '../models/scenario.dart';
import '../services/session_history.dart';
import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import 'session_detail_screen.dart';

class SessionReplayScreen extends StatefulWidget {
  final DebriefReport? report;
  const SessionReplayScreen({super.key, this.report});

  @override
  State<SessionReplayScreen> createState() => _SessionReplayScreenState();
}

class _SessionReplayScreenState extends State<SessionReplayScreen> {
  late Future<Map<String, dynamic>> _history;

  @override
  void initState() {
    super.initState();
    _history = _fetchHistory();
    SupabaseService.instance.addListener(_reload);
  }

  Future<Map<String, dynamic>> _fetchHistory() async {
    final rows = await SessionHistoryService.fetchAll();
    return {
      'reports': rows.map((r) {
        final scenario = r['scenarios'] is Map ? r['scenarios'] as Map : {};
        return {
          'id': r['id'],
          'scenarioId': r['scenario_id'],
          'title': scenario['title'] ?? 'Scenario',
          'completedAt': r['created_at'],
          'durationSeconds': r['duration_seconds'],
          'mode': 'video',
          'overallScore': r['overall_score'],
          'executiveTier': r['executive_tier'],
        };
      }).toList(),
    };
  }

  void _reload() {
    setState(() {
      _history = _fetchHistory();
    });
  }

  @override
  void dispose() {
    SupabaseService.instance.removeListener(_reload);
    super.dispose();
  }

  String _formatDuration(dynamic seconds) {
    final s = (seconds as num? ?? 0).toInt();
    final m = s ~/ 60;
    final rem = s % 60;
    return '$m min ${rem.toString().padLeft(2, '0')}s';
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'Recent';
    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return dateString.toString().split('T').first;
    }
  }

  String _getModeIcon(String mode) {
    switch (mode) {
      case 'video':
        return HardSyncAssets.iconLaptopComputer;
      case 'audio':
        return HardSyncAssets.iconHeartbeatPulseHealth;
      default:
        return HardSyncAssets.iconChatBubbles;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.report != null
              ? 'Transcript Inspection'
              : 'Scenarios',
          style: GoogleFonts.newsreader(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1B1715),
          ),
        ),
        actions: [
          if (widget.report == null)
            IconButton(
              onPressed: _reload,
              icon: const AppIcon(
                HardSyncAssets.iconSlidersSettingsTune,
                size: 18,
              ),
              tooltip: 'Refresh logs',
            ),
        ],
      ),
      body: widget.report != null
          ? _buildTranscriptView(widget.report!)
          : _buildHistoryView(),
    );
  }

  Widget _buildTranscriptView(DebriefReport report) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      itemCount: report.transcript.length,
      itemBuilder: (context, index) {
        final t = report.transcript[index];
        final isUser = t.isUser;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF224838) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUser
                  ? null
                  : Border.all(color: const Color(0xFFE5DFD5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.speakerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUser
                            ? const Color(0xFF76D8A2)
                            : const Color(0xFF7A726C),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      t.formattedTimestamp,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isUser
                            ? Colors.white60
                            : const Color(0xFF9E968D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isUser ? Colors.white : const Color(0xFF1B1715),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load history. ${snapshot.error}',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFC75438),
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF224838),
            ),
          );
        }

        final reports = snapshot.data!['reports'] as List;
        if (reports.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIllustration(
                    HardSyncAssets.reflectiveJournalGrowth,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Leadership Journey Begins Here',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.newsreader(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B1715),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Complete your first practice session to see how calm, clear, and firm you were.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF7A726C),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'PAST PRACTICE SESSIONS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF7A726C),
                ),
              ),
            ),
            ...reports.map((report) {
              final mode = report['mode']?.toString() ?? 'video';
              final score = report['overallScore'];
              final scenarioId = report['scenarioId']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5DFD5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(
                        sessionId: report['id'],
                        autoAnalyze: true,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3ECE0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: (scenarioId == null || scenarioId.isEmpty)
                              ? AppIcon(_getModeIcon(mode), size: 20)
                              : AppIllustration(
                                  Scenario.illustrationFor(scenarioId),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report['title'] ?? 'Leadership Scenario',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1715),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${mode.toUpperCase()} · ${_formatDuration(report['durationSeconds'])} · ${_formatDate(report['completedAt'])}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF7A726C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (score != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1EC),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '$score%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF224838),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
