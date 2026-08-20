import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';

/// KPI Card Widget
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const KpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconBackgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line, width: 1.2),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.inkSoft,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Alert Row Widget
class AlertRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final AlertType type;
  final VoidCallback? onTap;

  const AlertRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getAlertColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line, width: 1.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  color: colors['border'],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: colors['background'],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getAlertIcon(),
                            size: 16,
                            color: colors['icon'],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color> _getAlertColors() {
    switch (type) {
      case AlertType.error:
        return {
          'border': AppColors.danger,
          'background': AppColors.errorLight,
          'icon': AppColors.danger,
        };
      case AlertType.warning:
        return {
          'border': AppColors.accent,
          'background': AppColors.warningLight,
          'icon': AppColors.warning,
        };
      case AlertType.info:
        return {
          'border': AppColors.info,
          'background': AppColors.infoLight,
          'icon': AppColors.info,
        };
    }
  }

  IconData _getAlertIcon() {
    switch (type) {
      case AlertType.error:
        return Icons.warning_outlined;
      case AlertType.warning:
        return Icons.info_outlined;
      case AlertType.info:
        return Icons.info_outlined;
    }
  }
}

enum AlertType { error, warning, info }

/// Task Card Widget
class TaskCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String meta;
  final TaskStatus status;
  final VoidCallback? onTap;
  final Color? customIconBackground;
  final Color? customIconColor;

  const TaskCard({
    super.key,
    required this.icon,
    required this.title,
    required this.meta,
    required this.status,
    this.onTap,
    this.customIconBackground,
    this.customIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.line, width: 1.2),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: customIconBackground ?? colors['background'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: customIconColor ?? colors['icon'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors['background'],
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                _getStatusLabel(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors['text'],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors() {
    switch (status) {
      case TaskStatus.done:
        return {
          'background': AppColors.successLight,
          'icon': AppColors.statusDone,
          'text': AppColors.statusDone,
        };
      case TaskStatus.todo:
        return {
          'background': AppColors.warningLight,
          'icon': AppColors.warning,
          'text': AppColors.statusTodo,
        };
      case TaskStatus.late:
        return {
          'background': AppColors.errorLight,
          'icon': AppColors.danger,
          'text': AppColors.statusLate,
        };
      case TaskStatus.partial:
        return {
          'background': AppColors.warningLight,
          'icon': AppColors.warning,
          'text': AppColors.statusTodo,
        };
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case TaskStatus.done:
        return 'Faite';
      case TaskStatus.todo:
        return 'À faire';
      case TaskStatus.late:
        return 'Retard';
      case TaskStatus.partial:
        return 'Partielle';
    }
  }
}

enum TaskStatus { done, todo, late, partial }

/// Input Box Widget
class AppInputBox extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType inputType;
  final int maxLines;
  final bool readOnly;
  final Widget? suffix;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppInputBox({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
    this.readOnly = false,
    this.suffix,
    this.onTap,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.03,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: readOnly ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.line, width: 1.6),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: inputType,
                    maxLines: maxLines,
                    readOnly: readOnly,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      hintText: placeholder,
                      hintStyle: const TextStyle(color: AppColors.inkSoft, fontSize: 16.5),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16.5,
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 10),
                  suffix!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Counter Box Widget
class CounterBox extends StatefulWidget {
  final int initialValue;
  final void Function(int)? onChanged;
  final String? unit;

  const CounterBox({
    super.key,
    this.initialValue = 0,
    this.onChanged,
    this.unit,
  });

  @override
  State<CounterBox> createState() => _CounterBoxState();
}

class _CounterBoxState extends State<CounterBox> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.line, width: 1.6),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _value = (_value - 1).clamp(0, double.infinity).toInt());
              widget.onChanged?.call(_value);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.remove, color: AppColors.primaryDark, size: 22),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _value.toString(),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.unit != null)
                  Text(
                    widget.unit!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _value++);
              widget.onChanged?.call(_value);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: AppColors.primaryDark, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
