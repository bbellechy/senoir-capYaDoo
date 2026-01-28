import 'package:flutter/material.dart';
import 'package:capyadoo/core/constants/app_colors.dart';

class AppListCard extends StatelessWidget {
  final Widget? leading;
  final Widget? badge; // แสดงด้านบน (เช่น "ระดับ 5/10")
  final String? title;
  final Widget? titleWidget; // สำหรับ custom title
  final Widget? subtitle;
  final Widget? content; // เนื้อหาเพิ่มเติมด้านล่าง
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final List<Widget>? customActions; // ปุ่มเพิ่มเติม
  final Color? backgroundColor;
  final double? leadingSize;
  final EdgeInsets? padding;
  final bool showEditButton;
  final bool showDeleteButton;

  const AppListCard({
    super.key,
    this.leading,
    this.badge,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.content,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.customActions,
    this.backgroundColor,
    this.leadingSize = 80,
    this.padding,
    this.showEditButton = true,
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge (ถ้ามี)
              if (badge != null) ...[badge!, const SizedBox(height: 8)],

              // Main content row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading (รูป/ไอคอน)
                  if (leading != null) ...[
                    SizedBox(
                      width: leadingSize,
                      height: leadingSize,
                      child: leading!,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        if (titleWidget != null)
                          titleWidget!
                        else if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        // Subtitle
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          subtitle!,
                        ],

                        // Additional content
                        if (content != null) ...[
                          const SizedBox(height: 8),
                          content!,
                        ],
                      ],
                    ),
                  ),

                  // Action buttons
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      // Edit button
                      if (showEditButton && onEdit != null)
                        _ActionButton(
                          icon: Icons.edit,
                          onTap: onEdit,
                          color: AppColors.primaryBlue,
                        ),

                      // Delete button
                      if (showDeleteButton && onDelete != null) ...[
                        if (showEditButton && onEdit != null)
                          const SizedBox(width: 8),
                        _ActionButton(
                          icon: Icons.delete,
                          onTap: onDelete,
                          color: Colors.red,
                        ),
                      ],

                      // Custom actions
                      if (customActions != null)
                        ...customActions!.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// Badge components สำหรับใช้กับ AppListCard
class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.yellow[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor ?? Colors.black87),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget สำหรับ subtitle ที่มี icon
class AppListSubtitle extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? color;
  final int? maxLines;

  const AppListSubtitle({
    super.key,
    this.icon,
    required this.text,
    this.color,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: color ?? Colors.grey[600]),
            maxLines: maxLines ?? 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
