// lib/widgets/hearth_ui.dart
import 'package:flutter/material.dart';
import '../theme.dart';

class HearthAvatar extends StatelessWidget {
  final String name;
  final Color? color;
  final double size;
  final String? avatar;

  const HearthAvatar({
    super.key,
    required this.name,
    this.color,
    this.size = 32,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = color ?? AppTheme.muted;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget content;
    if (avatar != null && avatar!.trim().isNotEmpty) {
      final av = avatar!.trim();
      if (av.startsWith('http://') || av.startsWith('https://')) {
        content = ClipOval(
          child: Image.network(
            av,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initial,
                style: AppTheme.titleStyle(
                  color: Colors.white,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      } else {
        content = Center(
          child: Text(
            av,
            style: TextStyle(
              fontSize: size * 0.52,
            ),
          ),
        );
      }
    } else {
      content = Center(
        child: Text(
          initial,
          style: AppTheme.titleStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.normal,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: content,
    );
  }
}

class ResidentBadge extends StatelessWidget {
  final String name;
  final Color? color;
  final String? avatar;
  final VoidCallback? onTap;

  const ResidentBadge({
    super.key,
    required this.name,
    this.color,
    this.avatar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.muted;

    final content = Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (avatar != null && avatar!.trim().isNotEmpty && !avatar!.startsWith('http')) ...[
            Text(avatar!.trim(), style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.sansSmall.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: content,
      );
    }
    return content;
  }
}

class HearthProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double dangerThreshold;

  const HearthProgressBar({
    super.key,
    required this.value,
    this.color,
    this.dangerThreshold = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final isDanger = value > dangerThreshold;
    final barColor = isDanger ? AppTheme.danger : (color ?? AppTheme.moss);

    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.stone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              width: constraints.maxWidth * clamped,
              height: 6,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? sub;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.sub,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sub != null) ...[
                  Text(sub!.toUpperCase(), style: AppTheme.microStyle),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  style: AppTheme.titleStyle(fontSize: isDesktop ? 28 : 24),
                ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class HearthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? label;
  final Widget? action;

  const HearthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.label,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null || action != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Expanded(
                    child: Text(
                      label!.toUpperCase(),
                      style: AppTheme.microStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ?action,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class FormCard extends StatefulWidget {
  final String title;
  final String? sub;
  final Widget child;

  const FormCard({
    super.key,
    required this.title,
    this.sub,
    required this.child,
  });

  @override
  State<FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<FormCard> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 600;

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop) ...[
            InkWell(
              onTap: () => setState(() => _isOpen = !_isOpen),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppTheme.moss,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isOpen ? Icons.remove : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.sub != null)
                          Text(widget.sub!.toUpperCase(), style: AppTheme.microStyle),
                        Text(
                          widget.title,
                          style: AppTheme.titleStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isOpen) ...[
              const SizedBox(height: 20),
              widget.child,
            ],
          ] else ...[
            if (widget.sub != null)
              Text(widget.sub!.toUpperCase(), style: AppTheme.microStyle),
            Text(widget.title, style: AppTheme.titleStyle(fontSize: 22)),
            const SizedBox(height: 20),
            widget.child,
          ],
        ],
      ),
    );
  }
}

class HearthCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback onChange;

  const HearthCheckbox({
    super.key,
    required this.checked,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: checked ? AppTheme.moss : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: checked ? AppTheme.moss : AppTheme.muted.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: checked
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}

class HearthSegmented<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  const HearthSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.stone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(30, 32, 29, 0.04),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labelBuilder(opt),
                  style: AppTheme.sansMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppTheme.ink : AppTheme.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class HearthSelect<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) labelBuilder;
  final String? placeholder;

  const HearthSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: items.contains(value) ? value : null,
          hint: placeholder != null
              ? Text(
                  placeholder!,
                  style: AppTheme.sansMedium.copyWith(
                    color: AppTheme.muted.withValues(alpha: 0.7),
                  ),
                )
              : null,
          icon: const Icon(Icons.expand_more, size: 18, color: AppTheme.muted),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: AppTheme.sansMedium,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

void showHearthModal({
  required BuildContext context,
  required String title,
  String? sub,
  required Widget child,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 600;

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sub != null)
                          Text(sub.toUpperCase(), style: AppTheme.microStyle),
                        Text(title, style: AppTheme.titleStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.muted),
                    onPressed: () => Navigator.pop(dialogCtx),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.stone,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sub != null)
                          Text(sub.toUpperCase(), style: AppTheme.microStyle),
                        Text(title, style: AppTheme.titleStyle(fontSize: 22)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.muted),
                    onPressed: () => Navigator.pop(sheetCtx),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
