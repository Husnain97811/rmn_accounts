import 'package:rmn_accounts/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// lib/services/activity_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rmn_accounts/utils/views.dart';

class ActivityService with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  final int _inactivityTimeout = 10 * 60; // 10 minutes in seconds
  final SupabaseClient _supabase = Supabase.instance.client;
  DateTime _lastActivityTime = DateTime.now();
  bool _isActive = true;

  void startTracking() {
    _resetTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  void _resetTimer() {
    // print("Resetting inactivity timer");
    _lastActivityTime = DateTime.now();
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(
      Duration(seconds: _inactivityTimeout),
      _checkInactivity,
    );
  }

  void _checkInactivity() {
    final inactiveSeconds =
        DateTime.now().difference(_lastActivityTime).inSeconds;
    if (inactiveSeconds >= _inactivityTimeout) {
      _logout();
    } else {
      // Reschedule the check for the remaining time
      _inactivityTimer = Timer(
        Duration(seconds: _inactivityTimeout - inactiveSeconds),
        _checkInactivity,
      );
    }
  }

  void recordActivity() {
    if (!_isActive) return;
    // print("User activity detected at ${DateTime.now()}");
    _resetTimer();
  }

  void _logout() {
    // print("Logging out due to inactivity at ${DateTime.now()}");
    _isActive = false;
    _inactivityTimer?.cancel();
    _supabase.auth.signOut();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      RouteNames.signin,
      (route) => false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only log out when app is fully terminated (detached)
    if (state == AppLifecycleState.detached) {
      _clearSessionOnExit();
    } else if (state == AppLifecycleState.resumed) {
      recordActivity(); // Reset timer on app resume
    }
  }

  // New method: Clear session without navigation
  void _clearSessionOnExit() {
    _isActive = false;
    _inactivityTimer?.cancel();
    _supabase.auth.signOut(); // Critical: Clears session tokens
    print("Session cleared on app termination");
  }

  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

class ActivityTrackerWrapper extends StatefulWidget {
  final Widget child;
  final ActivityService activityService;

  const ActivityTrackerWrapper({
    super.key,
    required this.child,
    required this.activityService,
  });

  @override
  State<ActivityTrackerWrapper> createState() => _ActivityTrackerWrapperState();
}

class _ActivityTrackerWrapperState extends State<ActivityTrackerWrapper> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    widget.activityService.recordActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.activityService.recordActivity(),
      onPointerMove: (_) => widget.activityService.recordActivity(),
      onPointerUp: (_) => widget.activityService.recordActivity(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => widget.activityService.recordActivity(),
        onDoubleTap: () => widget.activityService.recordActivity(),
        onLongPress: () => widget.activityService.recordActivity(),
        onPanUpdate: (_) => widget.activityService.recordActivity(),
        child: MouseRegion(
          onHover: (_) => widget.activityService.recordActivity(),
          child: RawKeyboardListener(
            focusNode: _focusNode,
            onKey: (event) => widget.activityService.recordActivity(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                widget.activityService.recordActivity();
                return false;
              },
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
