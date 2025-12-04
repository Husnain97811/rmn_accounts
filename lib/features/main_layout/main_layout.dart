import 'package:flutter/material.dart';
import '../../shared/widgets/sidebar.dart';
import '../../core/config/app_constants.dart';

class MainLayout extends StatelessWidget {
  final Widget? child;

  const MainLayout({this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
