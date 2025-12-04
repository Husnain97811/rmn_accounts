import 'dart:async';

import 'package:flutter/foundation.dart';

class LoadingProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isPdfLoading = false;

  // <<< 2. Add a nullable Timer variable to hold our timeout timer.
  Timer? _loadingTimer;

  bool get isLoading => _isLoading;
  bool get isPdfLoading => _isPdfLoading;

  void startLoading() {
    _isLoading = true;
    _startTimeoutTimer(); // <<< 3. Start the timeout when loading starts
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    _cancelTimeoutTimerIfNeeded(); // <<< 4. Try to cancel the timer when loading stops
    notifyListeners();
  }

  void startPdfLoading() {
    _isPdfLoading = true;
    _startTimeoutTimer(); // <<< 3. Start the timeout when loading starts
    notifyListeners();
  }

  void stopPdfLoading() {
    _isPdfLoading = false;
    _cancelTimeoutTimerIfNeeded(); // <<< 4. Try to cancel the timer when loading stops
    notifyListeners();
  }

  // <<< 5. A helper method to start the timer.
  void _startTimeoutTimer() {
    // If a timer is already running, cancel it to reset the countdown.
    _loadingTimer?.cancel();

    // Start a new 10-second timer.
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      // This code will run IF the timer is not cancelled within 10 seconds.
      // print("Loading timed out after 10 seconds. Forcing stop.");

      // Check if the provider is still active before trying to update state
      if (_isLoading || _isPdfLoading) {
        _isLoading = false;
        _isPdfLoading = false;
        notifyListeners(); // Update the UI to hide the overlay
      }
    });
  }

  // <<< 6. A helper method to cancel the timer ONLY if all loading is complete.
  void _cancelTimeoutTimerIfNeeded() {
    // If there is no active loading process, we can safely cancel the timer.
    if (!_isLoading && !_isPdfLoading) {
      _loadingTimer?.cancel();
    }
  }

  // It's good practice to cancel any active timers when the provider is disposed.
  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }
}
