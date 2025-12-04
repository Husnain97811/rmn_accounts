import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/config/app_colors.dart';
import 'package:rmn_accounts/core/providers/loading_provider.dart';

class ProviderLoadingWidget extends StatelessWidget {
  final Color? loaderColor;
  final double? size;
  final String? loadingText;

  const ProviderLoadingWidget({
    super.key,
    this.loaderColor,
    this.size,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = loaderColor ?? theme.primaryColor;
    final loaderSize = size ?? 50.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: loaderSize,
            width: loaderSize,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                backgroundColor: Colors.brown,
              ),
            ),
          ),

          if (loadingText != null) ...[
            const SizedBox(height: 20),
            Text(
              loadingText!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final Color? overlayColor;
  final double? blur;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.overlayColor,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Listen to both isLoading and isPdfLoading
        Selector<LoadingProvider, bool>(
          selector:
              (_, provider) => provider.isLoading || provider.isPdfLoading,
          builder: (context, isLoading, child) {
            if (!isLoading) return const SizedBox.shrink();

            return ModalBarrier(
              color: overlayColor ?? Colors.black.withOpacity(0.4),
              dismissible: false,
            );
          },
        ),
        // Separate selector for the loading widget to ensure it's always on top
        Selector<LoadingProvider, bool>(
          selector:
              (_, provider) => provider.isLoading || provider.isPdfLoading,
          builder: (context, isLoading, child) {
            if (!isLoading) return const SizedBox.shrink();

            return Center(child: ProviderLoadingWidget());
          },
        ),
      ],
    );
  }
}
