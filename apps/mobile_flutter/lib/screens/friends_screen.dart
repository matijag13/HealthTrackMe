import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/social_models.dart';
import '../services/api_service.dart';

/// Friends + gamification leaderboard. Friends compare Health Shield points and
/// logging streaks — no health data is shared. Two tabs: the ranked leaderboard,
/// and friend management (add by email, accept/decline requests, remove).
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
  final ApiService _api = ApiService.instance;
  late Future<_FriendsData> _future;

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a friend'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Their email',
            hintText: 'friend@example.com',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
        title: const Text('Remove friend?'),
        content: Text('Remove ${f.name} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Leaderboard'),
              Tab(text: 'Friends'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Add friend',
              icon: const Icon(Icons.person_add_alt_1_rounded),
              onPressed: _addFriend,
            ),
          ],
        ),
        body: FutureBuilder<_FriendsData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data;
            if (data == null) {
              return const Center(child: Text('Could not load friends'));
            }
            return TabBarView(
              children: [
                _LeaderboardTab(entries: data.leaderboard, onRefresh: _refresh),
                _FriendsTab(
                  data: data,
                  onRefresh: _refresh,
                  onRespond: _respond,
                  onRemove: _remove,
                  onAdd: _addFriend,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final Future<void> Function() onRefresh;

  const _LeaderboardTab({required this.entries, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: entries.length <= 1
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Icon(Icons.emoji_events_outlined,
                    size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Center(
                    child: Text('Add friends to compete',
                        style: theme.textTheme.titleMedium)),
                const SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your Health Shield points and streak go head-to-head with your friends. No health data is shared.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _LeaderboardRow(entry: entries[i]),
            ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  Color? _medalColor() {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFD4AF37);
      case 2:
        return const Color(0xFFAAB4BE);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medal = _medalColor();
    final highlight = entry.isMe;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: medal != null
                ? Icon(Icons.emoji_events_rounded, color: medal, size: 24)
                : Text(
                    '${entry.rank}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.hintColor),
                  ),
          ),
          const SizedBox(width: 8),
          _Avatar(name: entry.name, photoBase64: entry.profilePhotoBase64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMe ? '${entry.name} (you)' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lvl ${entry.level} · ${entry.levelName}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text('pts',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
              if (entry.streak > 0) ...[
                const SizedBox(height: 2),
                Text('🔥 ${entry.streak}', style: theme.textTheme.labelSmall),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendsTab extends StatelessWidget {
  final _FriendsData data;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Friend, bool) onRespond;
  final Future<void> Function(Friend) onRemove;
  final VoidCallback onAdd;

  const _FriendsTab({
    required this.data,
    required this.onRefresh,
    required this.onRespond,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data.incoming.isNotEmpty) ...[
            _sectionTitle(theme, 'Requests'),
            ...data.incoming.map((f) => _RequestRow(
                  friend: f,
                  onAccept: () => onRespond(f, true),
                  onDecline: () => onRespond(f, false),
                )),
            const SizedBox(height: 16),
          ],
          _sectionTitle(theme, 'Your friends'),
          if (data.friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Text('No friends yet', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text('Add someone by their email to get started.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onAdd,
                      icon:
                          const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('Add a friend'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...data.friends.map((f) => _FriendRow(
                  friend: f,
                  onRemove: () => onRemove(f),
                )),
          if (data.outgoing.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle(theme, 'Pending'),
            ...data.outgoing.map((f) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      _Avatar(name: f.name, photoBase64: f.profilePhotoBase64),
                  title: Text(f.name),
                  subtitle: const Text('Request sent'),
                  trailing:
                      Text('Pending', style: TextStyle(color: theme.hintColor)),
                )),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.hintColor,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _RequestRow extends StatelessWidget {
  final Friend friend;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestRow({
    required this.friend,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          _Avatar(name: friend.name, photoBase64: friend.profilePhotoBase64),
      title: Text(friend.name),
      subtitle: Text(friend.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Accept',
            icon: const Icon(Icons.check_circle, color: Color(0xFF5FB878)),
            onPressed: onAccept,
          ),
          IconButton(
            tooltip: 'Decline',
            icon: const Icon(Icons.cancel, color: Color(0xFFE25555)),
            onPressed: onDecline,
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Friend friend;
  final VoidCallback onRemove;

  const _FriendRow({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading:
          _Avatar(name: friend.name, photoBase64: friend.profilePhotoBase64),
      title: Text(friend.name),
      subtitle: Text(friend.email),
      trailing: IconButton(
        tooltip: 'Remove',
        icon: const Icon(Icons.person_remove_alt_1_outlined),
        onPressed: onRemove,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoBase64;

  const _Avatar({required this.name, this.photoBase64});

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    final photo = photoBase64;
    if (photo != null && photo.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photo));
      } catch (_) {
        image = null;
      }
    }
    final initials = name.isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0]).join()
        : '?';
    return CircleAvatar(
      radius: 20,
      backgroundImage: image,
      child: image == null
          ? Text(initials.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700))
          : null,
    );
  }
}
