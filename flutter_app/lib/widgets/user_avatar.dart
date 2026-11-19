import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UserAvatar extends StatefulWidget {
  const UserAvatar({super.key, this.name, this.photo, this.radius = 20});

  final String? name;
  final String? photo;
  final double radius;

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  late Uint8List? _bytes = _decode(widget.photo);

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo != widget.photo) _bytes = _decode(widget.photo);
  }

  static Uint8List? _decode(String? photo) {
    if (photo == null || photo.isEmpty) return null;
    try {
      return UriData.parse(photo).contentAsBytes();
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.name?.trim().characters.firstOrNull?.toUpperCase();
    final bytes = _bytes;
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppTheme.blue,
      foregroundColor: Colors.white,
      foregroundImage: bytes == null ? null : MemoryImage(bytes),
      onForegroundImageError: bytes == null ? null : (_, _) {},
      child: letter == null
          ? Icon(Icons.person_rounded, size: widget.radius * 1.2)
          : Text(
              letter,
              style: TextStyle(
                fontSize: widget.radius * .9,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
