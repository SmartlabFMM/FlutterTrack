import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EpiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String           title;
  final String?          subtitle;
  final List<Widget>?    actions;
  final bool             showBack;

  const EpiAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: showBack,
    title: subtitle != null
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(subtitle!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary)),
          ])
      : Text(title),
    actions: actions,
  );
}
