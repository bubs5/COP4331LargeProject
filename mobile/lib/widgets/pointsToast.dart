import 'package:flutter/material.dart';

import '../services/rewardsProvider.dart';

class PointsToast extends StatefulWidget {
  const PointsToast({super.key});

  @override
  State<PointsToast> createState() => _PointsToastState();
}

class _PointsToastState extends State<PointsToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offset;
  late final Animation<double> _scale;
  String? _activeId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _offset = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );

    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.56, 0.64, 1),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final toast = RewardsScope.of(context).toast;
    final id = toast?.id;

    if (id != null && id != _activeId) {
      _activeId = id;
      _controller.forward(from: 0);
    }

    if (id == null && _activeId != null) {
      _activeId = null;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = RewardsScope.of(context);
    final toast = rewards.toast;
    if (toast == null && _controller.value == 0) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 600;

    return IgnorePointer(
      ignoring: toast == null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Positioned(
            left: isMobile ? 16 : null,
            right: 16,
            bottom: isMobile ? 90 : 32,
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.translate(
                offset: Offset(0, _offset.value),
                child: Transform.scale(
                  scale: _scale.value,
                  child: GestureDetector(
                    onTap: rewards.dismissToast,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color.fromRGBO(15, 20, 40, 0.95),
                        border: Border.all(
                          color: rewards.activeTheme.colors.primaryColor,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color.fromRGBO(255, 255, 255, 0.04),
                            blurRadius: 1,
                          ),
                          const BoxShadow(
                            color: Color.fromRGBO(0, 0, 20, 0.7),
                            blurRadius: 50,
                            offset: Offset(0, 20),
                          ),
                          BoxShadow(
                            color: rewards.activeTheme.colors.primaryColor
                                .withOpacity(0.35),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            toast?.icon ?? '',
                            style: const TextStyle(fontSize: 24, height: 1),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                toast?.label ?? '',
                                style: const TextStyle(
                                  color: Color(0xFFCBD5F5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '+${toast?.points ?? 0} pts',
                                style: TextStyle(
                                  color: rewards.activeTheme.colors.primaryColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
