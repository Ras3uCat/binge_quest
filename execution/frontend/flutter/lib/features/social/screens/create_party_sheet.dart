import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/e_colors.dart';
import '../../../core/constants/e_sizes.dart';
import '../../../shared/models/friendship.dart';
import '../controllers/friend_controller.dart';
import '../controllers/watch_party_controller.dart';
import 'watch_party_screen.dart';

/// Bottom sheet for creating a new Watch Party.
/// Three steps: name → friend picker → confirm.
/// NOTE: Uses StatefulWidget to manage local state without Obx
/// (Obx inside bottom sheets causes dismissal during animation).
class CreatePartySheet extends StatefulWidget {
  final int tmdbId;
  final String mediaType;
  final String contentTitle;

  const CreatePartySheet({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.contentTitle,
  });

  /// Show the sheet via Get.bottomSheet.
  static Future<void> show({
    required int tmdbId,
    required String mediaType,
    required String contentTitle,
  }) {
    return Get.bottomSheet(
      CreatePartySheet(
        tmdbId: tmdbId,
        mediaType: mediaType,
        contentTitle: contentTitle,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<CreatePartySheet> createState() => _CreatePartySheetState();
}

class _CreatePartySheetState extends State<CreatePartySheet> {
  late final TextEditingController _nameController;
  final Set<String> _selectedFriendIds = {};
  bool _isCreating = false;

  static const int _maxGuests = 9; // 10 total including creator

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contentTitle);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<Friendship> get _activeFriends {
    try {
      return FriendController.to.friends.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Party name is required');
      return;
    }
    setState(() => _isCreating = true);

    final ctrl = WatchPartyController.to;
    final party = await ctrl.createParty(
      name: name,
      tmdbId: widget.tmdbId,
      mediaType: widget.mediaType,
    );

    if (party == null) {
      setState(() => _isCreating = false);
      return;
    }

    // Invite selected friends and send push notifications (C4a)
    for (final uid in _selectedFriendIds) {
      await ctrl.inviteAndNotify(party: party, inviteeUserId: uid);
    }

    Get.back(); // dismiss sheet

    await Get.to(
      () => WatchPartyScreen(
        partyId: party.id,
        tmdbId: party.tmdbId,
        mediaType: party.mediaType,
        partyName: party.name,
      ),
    );
  }

  void _toggleFriend(String userId) {
    setState(() {
      if (_selectedFriendIds.contains(userId)) {
        _selectedFriendIds.remove(userId);
      } else if (_selectedFriendIds.length < _maxGuests) {
        _selectedFriendIds.add(userId);
      } else {
        Get.snackbar('Limit reached', 'Max 10 members per party');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(ESizes.radiusLg)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + ESizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildTitle(),
          _buildNameField(),
          const Divider(color: EColors.divider, height: 1),
          _buildFriendList(),
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: ESizes.md),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: EColors.textTertiary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ESizes.md, vertical: ESizes.md),
      child: Row(
        children: [
          const Icon(Icons.groups, color: EColors.primary, size: ESizes.iconMd),
          const SizedBox(width: ESizes.sm),
          const Text(
            'New Watch Party',
            style: TextStyle(
              color: EColors.textPrimary,
              fontSize: ESizes.fontLg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, 0, ESizes.md, ESizes.md),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: EColors.textPrimary),
        decoration: InputDecoration(
          labelText: 'Party name',
          labelStyle: const TextStyle(color: EColors.textSecondary),
          filled: true,
          fillColor: EColors.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ESizes.radiusSm),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendList() {
    final friends = _activeFriends;
    if (friends.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(ESizes.md),
        child: Text(
          'Add friends to invite them to the party.',
          style: TextStyle(color: EColors.textSecondary, fontSize: ESizes.fontSm),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: ESizes.xs),
        itemCount: friends.length,
        itemBuilder: (_, i) => _buildFriendTile(friends[i]),
      ),
    );
  }

  Widget _buildFriendTile(Friendship f) {
    final friend = f.friend;
    final userId = friend?.id ?? f.addresseeId;
    final isSelected = _selectedFriendIds.contains(userId);
    final avatarUrl = friend?.avatarUrl;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: EColors.surfaceLight,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? const Icon(Icons.person, size: 16, color: EColors.textSecondary)
            : null,
      ),
      title: Text(
        friend?.displayLabel ?? 'User',
        style: const TextStyle(color: EColors.textPrimary, fontSize: ESizes.fontMd),
      ),
      trailing: Checkbox(
        value: isSelected,
        activeColor: EColors.primary,
        onChanged: (_) => _toggleFriend(userId),
      ),
      onTap: () => _toggleFriend(userId),
    );
  }

  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(ESizes.md, ESizes.md, ESizes.md, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isCreating ? null : _create,
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: ESizes.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ESizes.radiusSm),
            ),
          ),
          child: _isCreating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: EColors.textPrimary,
                  ),
                )
              : Text(
                  _selectedFriendIds.isEmpty
                      ? 'Create Party'
                      : 'Create & Invite ${_selectedFriendIds.length}',
                ),
        ),
      ),
    );
  }
}
