import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/station_providers.dart';

final _sessionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('sessions')
      .where('userId', isEqualTo: uid)
      .orderBy('requestedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());
});

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_sessionsProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1C1E),
          ),
        ),
        backgroundColor: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFC6C6C8), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: sessionsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_sessionsProvider),
          ),
          data: (sessions) {
            if (sessions.isEmpty) return const _EmptyState();
            return _SessionList(sessions: sessions);
          },
        ),
      ),
    );
  }
}

class _SessionList extends StatefulWidget {
  const _SessionList({required this.sessions});
  final List<Map<String, dynamic>> sessions;

  @override
  State<_SessionList> createState() => _SessionListState();
}

class _SessionListState extends State<_SessionList> {
  static const _pageSize = 5;
  int _page = 0;
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(_SessionList old) {
    super.didUpdateWidget(old);
    // Reset to page 0 if list length changes (new session arrives / stream refresh)
    if (old.sessions.length != widget.sessions.length) {
      setState(() => _page = 0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.sessions.length / _pageSize).ceil();
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.sessions.length);
    final pageItems = widget.sessions.sublist(start, end);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      itemCount: pageItems.length + 1, // +1 for pagination bar
      itemBuilder: (_, i) {
        if (i < pageItems.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SessionCard(session: pageItems[i]),
          );
        }
        return _PaginationBar(
          page: _page,
          totalPages: totalPages,
          onPrevious: _page > 0 ? () => _goToPage(_page - 1) : null,
          onNext: _page < totalPages - 1 ? () => _goToPage(_page + 1) : null,
        );
      },
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(
            icon: CupertinoIcons.chevron_left,
            onPressed: onPrevious,
          ),
          const SizedBox(width: 20),
          Text(
            'Page ${page + 1} of $totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(width: 20),
          _PageButton(
            icon: CupertinoIcons.chevron_right,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: onPressed != null
          ? () {
              HapticFeedback.selectionClick();
              onPressed!();
            }
          : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF5A623) : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFFFFFFFF) : const Color(0xFFAEAEB2),
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status    = session['status'] as String? ?? 'unknown';
    final stationId = session['stationId'] as String? ?? '';
    final energyKwh = (session['energyKwh'] as num?)?.toDouble() ?? 0;
    final totalCost = (session['totalCost'] as num?)?.toDouble() ?? 0;
    final requestedAt = session['requestedAt'];

    String dateStr = '';
    if (requestedAt is Timestamp) {
      dateStr = DateFormat('MMM d, yyyy · h:mm a').format(requestedAt.toDate());
    }

    final (statusLabel, statusColor, statusBg) = _statusStyle(status);

    final stationNameAsync = ref.watch(stationNameProvider(stationId));
    final stationName = stationNameAsync.when(
      data: (name) => name,
      loading: () => stationId.isNotEmpty ? stationId : 'Charging Session',
      error: (_, __) => stationId.isNotEmpty ? stationId : 'Charging Session',
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/activity/session', extra: session);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [

            // ── Top row: icon + station name + status badge ──────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.bolt_fill,
                      size: 20,
                      color: Color(0xFFF5A623),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Station name + date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (dateStr.isNotEmpty)
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────
            Container(
              height: 0.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFE5E5EA),
            ),

            // ── Bottom row: energy + cost ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  _StatPill(
                    icon: CupertinoIcons.bolt_fill,
                    iconColor: const Color(0xFFF5A623),
                    label: '${energyKwh.toStringAsFixed(2)} kWh',
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    iconColor: const Color(0xFF34C759),
                    label: totalCost > 0
                        ? '₱${totalCost.toStringAsFixed(2)}'
                        : '₱0.00',
                  ),
                  const Spacer(),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: Color(0xFFC7C7CC),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, Color) _statusStyle(String status) => switch (status) {
    'active'        => ('Active',   const Color(0xFF34C759), const Color(0xFFE8F5E9)),
    'complete'      => ('Complete', const Color(0xFFF5A623), const Color(0xFFFFF3DC)),
    'idle_fee'      => ('Idle Fee', const Color(0xFFFF9500), const Color(0xFFFFF3DC)),
    'ended'         => ('Ended',    const Color(0xFF8E8E93), const Color(0xFFF2F2F7)),
    'pending_start' => ('Pending',  const Color(0xFF007AFF), const Color(0xFFE5F0FF)),
    _               => ('Unknown',  const Color(0xFF8E8E93), const Color(0xFFF2F2F7)),
  };
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.bolt_slash,
                size: 36,
                color: Color(0xFFAEAEB2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No sessions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your charging history will appear\nhere after your first session.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 36,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to load activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CupertinoButton(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(14),
                onPressed: onRetry,
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
