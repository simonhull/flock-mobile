import 'package:flutter/material.dart';

/// A circular avatar widget that displays a user's profile picture or initials.
///
/// If [imageUrl] is provided and loads successfully, the image is displayed.
/// Otherwise, initials are generated from [firstName] and [lastName],
/// or falls back to [email], or finally to "?" if no data is available.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.firstName,
    this.lastName,
    this.email,
    this.size = 40,
    this.onTap,
  });

  /// URL of the user's profile picture.
  final String? imageUrl;

  /// User's first name for generating initials.
  final String? firstName;

  /// User's last name for generating initials.
  final String? lastName;

  /// User's email as fallback for generating initials.
  final String? email;

  /// Size of the avatar (width and height).
  final double size;

  /// Callback when the avatar is tapped.
  final VoidCallback? onTap;

  String get _initials {
    final first = firstName?.trim();
    final last = lastName?.trim();

    if (first != null && first.isNotEmpty) {
      final firstInitial = first[0].toUpperCase();
      final lastInitial =
          (last != null && last.isNotEmpty) ? last[0].toUpperCase() : '';
      return '$firstInitial$lastInitial';
    }

    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }

    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: colorScheme.primary,
      backgroundImage:
          imageUrl != null && imageUrl!.isNotEmpty
              ? NetworkImage(imageUrl!)
              : null,
      onBackgroundImageError:
          imageUrl != null
              ? (_, __) {
                  // Image failed to load, fallback will be shown
                }
              : null,
      child:
          imageUrl == null || imageUrl!.isEmpty
              ? Text(
                  _initials,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
