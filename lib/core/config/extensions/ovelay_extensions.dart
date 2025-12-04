// extensions/loading_overlay_extension.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/providers/loading_provider.dart';

extension LoadingOverlayExtension on BuildContext {
  Future<T> runWithLoader<T>(Future<T> Function() asyncFunction) async {
    try {
      // Show loading
      Provider.of<LoadingProvider>(this, listen: false).startLoading();

      // Execute the function
      final result = await asyncFunction();

      return result;
    } finally {
      // Hide loading
      Provider.of<LoadingProvider>(this, listen: false).stopLoading();
    }
  }
}
