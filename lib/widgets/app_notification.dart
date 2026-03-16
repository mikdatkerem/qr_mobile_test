import 'package:flutter/material.dart';

enum NotificationStyle { info, success, warning }

class AppNotificationBar extends StatefulWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final VoidCallback? onDismiss;
  final NotificationStyle style;
  final Duration duration;

  const AppNotificationBar({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.onDismiss,
    this.style = NotificationStyle.info,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<AppNotificationBar> createState() => _AppNotificationBarState();
}

class _AppNotificationBarState extends State<AppNotificationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = switch (widget.style) {
      NotificationStyle.info => Colors.blue.shade600,
      NotificationStyle.success => Colors.green.shade600,
      NotificationStyle.warning => Colors.orange.shade600,
    };

    final icon = switch (widget.style) {
      NotificationStyle.info => Icons.directions_car_rounded,
      NotificationStyle.success => Icons.local_parking_rounded,
      NotificationStyle.warning => Icons.exit_to_app_rounded,
    };

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accent.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sol accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16)),
                  ),
                ),
                const SizedBox(width: 14),
                // İkon
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Mesaj + butonlar
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        // İki buton yan yana
                        if (widget.actionLabel != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _ActionButton(
                                label: widget.actionLabel!,
                                color: accent,
                                onTap: () {
                                  _dismiss();
                                  widget.onAction?.call();
                                },
                              ),
                              if (widget.secondaryActionLabel != null) ...[
                                const SizedBox(width: 8),
                                _ActionButton(
                                  label: widget.secondaryActionLabel!,
                                  color: Colors.grey.shade200,
                                  textColor: Colors.grey.shade700,
                                  onTap: () {
                                    _dismiss();
                                    widget.onSecondaryAction?.call();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Kapat
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey.shade500, size: 15),
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
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
