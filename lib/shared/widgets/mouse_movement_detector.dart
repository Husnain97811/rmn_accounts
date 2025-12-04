// lib/widgets/mouse_movement_detector.dart
import 'package:flutter/material.dart';
import 'package:rmn_accounts/core/services/activity_service.dart';

class MouseMovementDetector extends StatelessWidget {
  final Widget child;
  final ActivityService activityService;

  const MouseMovementDetector({
    super.key,
    required this.child,
    required this.activityService,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => activityService.recordActivity(),
      child: child,
    );
  }
}
