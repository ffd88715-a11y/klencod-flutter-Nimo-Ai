import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:talkora_ai/app/theme/app_theme.dart';

/// Authentic iOS 18 Inset Grouped Section with subtle header, hairline dividers, and footer.
class IosGroupedSection extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const IosGroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: 22),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? TalkoraColors.darkSurface : TalkoraColors.lightSurface;
    final dividerColor = isDark ? TalkoraColors.darkSeparator : TalkoraColors.lightSeparator;
    final labelColor = isDark ? TalkoraColors.darkSecondaryText : TalkoraColors.lightSecondaryText;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null && header!.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 7),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: labelColor,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 56),
                      child: Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: dividerColor.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null && footer!.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 7, 16, 0),
              child: Text(
                footer!,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: labelColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Authentic iOS Squircle Icon Badge (29x29 rounded square like Apple Settings).
class IosIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IosIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.58),
    );
  }
}

/// Authentic iOS Settings Row with squircle icon, title, subtitle/value, and chevron.
class IosSettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingValue;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const IosSettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingValue,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark ? TalkoraColors.darkSecondaryText : TalkoraColors.lightSecondaryText;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            IosIconBadge(icon: icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: destructive ? TalkoraColors.iosRed : null,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingValue != null) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: Text(
                  trailingValue!,
                  style: TextStyle(fontSize: 14.5, color: secondaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: secondaryColor.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// iOS Status Pill Badge (e.g., Active AI Model indicator).
class IosStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  const IosStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
