import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/social_models.dart';
import '../services/api_service.dart';

/// Friends + gamification leaderboard. Friends compare Health Shield points and
/// logging streaks — no health data is shared. Styled to match the app's dark
/// design system (same palette/cards as the dashboard + Health Shield screens).
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsData {
  final List<LeaderboardEntry> leaderboard;
  final List<Friend> friends;
  final List<Friend> incoming;
  final List<Friend> outgoing;

  const _FriendsData({
    required this.leaderboard,
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });
}

class _FriendsScreenState extends State<FriendsScreen> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _accent = Color(0xFF5B8DEF);
  static const _green = Color(0xFF5FB878);
  static const _orange = Color(0xFFD4956A);
  static const _danger = Color(0xFFFF6B6B);
  static const _gold = Color(0xFFE3B341);
  static const _silver = Color(0xFFAAB4BE);
  static const _bronze = Color(0xFFCD7F32);

  final ApiService _api = ApiService.instance;
  late Future<_FriendsData> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FriendsData> _load() async {
    final results = await Future.wait([
      _api.getLeaderboard(),
      _api.getFriends(),
      _api.getIncomingRequests(),
      _api.getOutgoingRequests(),
    ]);
    return _FriendsData(
      leaderboard: results[0] as List<LeaderboardEntry>,
      friends: results[1] as List<Friend>,
      incoming: results[2] as List<Friend>,
      outgoing: results[3] as List<Friend>,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _primaryText)),
        backgroundColor: _surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
      ),
    );
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Add a friend',
            style: TextStyle(color: _primaryText, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: _primaryText),
          cursorColor: _accent,
          decoration: InputDecoration(
            labelText: "Their email",
            labelStyle: const TextStyle(color: _secondaryText),
            hintText: 'friend@example.com',
            hintStyle: TextStyle(color: _secondaryText.withValues(alpha: 0.6)),
            filled: true,
            fillColor: _bg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: _secondaryText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Send request'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    final error = await _api.sendFriendRequest(email);
    _snack(error ?? 'Friend request sent to $email');
    if (error == null) await _refresh();
  }

  Future<void> _respond(Friend f, bool accept) async {
    final ok = await _api.respondToFriendRequest(f.friendshipId, accept);
    if (ok) {
      _snack(
          accept ? 'You are now friends with ${f.name}' : 'Request declined');
      await _refresh();
    } else {
      _snack('Something went wrong');
    }
  }

  Future<void> _remove(Friend f) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _border),
        ),
        title: const Text('Remove friend?',
            style: TextStyle(color: _primaryText, fontWeight: FontWeight.w800)),
        content: Text('Remove ${f.name} from your friends?',
            style: const TextStyle(color: _secondaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: _secondaryText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _api.removeFriend(f.friendshipId);
    if (ok) {
      _snack('Removed ${f.name}');
      await _refresh();
    } else {
      _snack('Could not remove friend');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _topBar(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _segmented(),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: FutureBuilder<_FriendsData>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: _accent, strokeWidth: 2),
                    );
                  }
                  final data = snap.data;
                  if (data == null) {
                    return const Center(
                      child: Text('Could not load friends',
                          style: TextStyle(color: _secondaryText)),
                    );
                  }
                  return RefreshIndicator(
                    color: _accent,
                    backgroundColor: _surface,
                    onRefresh: _refresh,
                    child: _tab == 0
                        ? _leaderboardView(data.leaderboard)
                        : _friendsView(data),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('home');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: _primaryText,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _border),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Friends',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _primaryText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Add friend',
          onPressed: _addFriend,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          color: _primaryText,
          style: IconButton.styleFrom(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _segItem('Leaderboard', 0),
          _segItem('Friends', 1),
        ],
      ),
    );
  }

  Widget _segItem(String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _secondaryText,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  // ---- Leaderboard -------------------------------------------------------

  Widget _leaderboardView(List<LeaderboardEntry> entries) {
    if (entries.length <= 1) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const SizedBox(height: 70),
          _emptyIcon(Icons.emoji_events_rounded, _gold),
          const SizedBox(height: 18),
          const Text(
            'Add friends to compete',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _primaryText, fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Health Shield points and streak go head-to-head with friends. No health data is shared.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _secondaryText, height: 1.4),
          ),
          const SizedBox(height: 22),
          Center(child: _addButton()),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _leaderboardRow(entries[i]),
    );
  }

  Widget _leaderboardRow(LeaderboardEntry e) {
    final medal = switch (e.rank) {
      1 => _gold,
      2 => _silver,
      3 => _bronze,
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: e.isMe ? _accent.withValues(alpha: 0.10) : _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: e.isMe
              ? _accent.withValues(alpha: 0.55)
              : (medal ?? _border)
                  .withValues(alpha: medal != null ? 0.5 : 0.85),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: medal != null
                ? Icon(Icons.emoji_events_rounded, color: medal, size: 24)
                : Text(
                    '${e.rank}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _secondaryText,
                        fontWeight: FontWeight.w800,
                        fontSize: 16),
                  ),
          ),
          const SizedBox(width: 10),
          _avatar(e.name, e.profilePhotoBase64, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _primaryText,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
                      ),
                    ),
                    if (e.isMe) ...[
                      const SizedBox(width: 6),
                      _youPill(),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Lvl ${e.level} · ${e.levelName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${e.points}',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1,
                ),
              ),
              const Text('pts',
                  style: TextStyle(color: _secondaryText, fontSize: 11)),
              if (e.streak > 0) ...[
                const SizedBox(height: 4),
                Text('🔥 ${e.streak}',
                    style: const TextStyle(
                        color: _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ---- Friends -----------------------------------------------------------

  Widget _friendsView(_FriendsData data) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        if (data.incoming.isNotEmpty) ...[
          _sectionLabel('Requests'),
          ...data.incoming.map(_incomingCard),
          const SizedBox(height: 18),
        ],
        _sectionLabel('Your friends'),
        if (data.friends.isEmpty)
          _friendsEmpty()
        else
          ...data.friends.map(_friendCard),
        if (data.outgoing.isNotEmpty) ...[
          const SizedBox(height: 18),
          _sectionLabel('Pending'),
          ...data.outgoing.map(_pendingCard),
        ],
      ],
    );
  }

  Widget _incomingCard(Friend f) {
    return _personCard(
      f,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circleAction(Icons.check_rounded, _green, () => _respond(f, true)),
          const SizedBox(width: 8),
          _circleAction(Icons.close_rounded, _danger, () => _respond(f, false)),
        ],
      ),
    );
  }

  Widget _friendCard(Friend f) {
    return _personCard(
      f,
      trailing: _circleAction(
          Icons.person_remove_alt_1_outlined, _secondaryText, () => _remove(f)),
    );
  }

  Widget _pendingCard(Friend f) {
    return _personCard(
      f,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _border),
        ),
        child: const Text('Pending',
            style: TextStyle(color: _secondaryText, fontSize: 11.5)),
      ),
    );
  }

  Widget _personCard(Friend f, {required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.85)),
      ),
      child: Row(
        children: [
          _avatar(f.name, f.profilePhotoBase64, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(f.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: _secondaryText, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  Widget _friendsEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
          const Text('No friends yet',
              style:
                  TextStyle(color: _primaryText, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Add someone by their email to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryText, fontSize: 13)),
          const SizedBox(height: 14),
          _addButton(),
        ],
      ),
    );
  }

  // ---- Small shared pieces ----------------------------------------------

  Widget _addButton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _addFriend,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text('Add a friend'),
    );
  }

  Widget _circleAction(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _youPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text('You',
          style: TextStyle(
              color: _accent, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 11.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _emptyIcon(IconData icon, Color color) => Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 40),
        ),
      );

  Widget _avatar(String name, String? photoBase64, {double size = 42}) {
    ImageProvider? image;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photoBase64));
      } catch (_) {
        image = null;
      }
    }
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _surfaceAlt,
        border: Border.all(color: _border),
        image: image != null
            ? DecorationImage(image: image, fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: image == null
          ? Text(initials,
              style: const TextStyle(
                  color: _primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14))
          : null,
    );
  }
}
