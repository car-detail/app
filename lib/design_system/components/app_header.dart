import 'package:flutter/material.dart';
import '../../Common/ModernDesignSystem.dart';
import 'car_wash_icon.dart';

/// Standard gradient page header — back button, title, optional subtitle,
/// optional trailing actions, with the same decorative "blob" texture and
/// brand gradient used across the app. Every screen was previously building
/// its own slightly-different version of this; use this instead so
/// navigation/headers look identical everywhere.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.leading,
    this.decorative = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? leading;
  final bool decorative;

  // preferredSize has no BuildContext, so the status bar height is read
  // directly from the platform (not MediaQuery) -- without this, Scaffold
  // only reserves kToolbarHeight + 24 for the appBar slot, and the status
  // bar padding added in build() below overflows past the bottom of it.
  @override
  Size get preferredSize {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final statusBarHeight = view.padding.top / view.devicePixelRatio;
    return Size.fromHeight(kToolbarHeight + 24 + statusBarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, statusBarHeight + 16, 16, 22),
        decoration: BoxDecoration(gradient: ModernDesignSystem.brandGradient),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (decorative) ...[
              Positioned(
                top: -30,
                right: -40,
                child: _blob(120),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _blob(90),
              ),
              // faint car-wash watermark -- front-facing car + sparkles,
              // matching the reference icon style. Kept subtle (12%
              // opacity) so it reads as texture, not decoration fighting
              // the title for attention.
              Positioned(
                right: 4,
                bottom: -10,
                child: CarWashIcon(size: 90, opacity: 0.12),
              ),
            ],
            Row(
              children: [
                leading ??
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack ?? () => Navigator.maybePop(context),
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

/// Same circular glass-style icon button used for header actions
/// (e.g. logout, edit) so trailing icons match the back button.
class AppHeaderAction extends StatelessWidget {
  const AppHeaderAction({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _CircleIconButton(icon: icon, onTap: onTap);
}
