import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/core/config/app_colors.dart';
import 'package:rmn_accounts/utils/views.dart';

import 'package:sizer/sizer.dart';

class AuthRoundBtn extends StatefulWidget {
  final String title;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  bool? loading = false;

  AuthRoundBtn({
    super.key,
    required this.title,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.loading,
  });

  @override
  State<AuthRoundBtn> createState() => _AuthRoundBtnState();
}

class _AuthRoundBtnState extends State<AuthRoundBtn> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HoverProvider(),
      child: Consumer<HoverProvider>(
        builder: (context, hoverProvider, child) {
          return MouseRegion(
            onEnter: (_) => hoverProvider.setHovering(true),
            onExit: (_) => hoverProvider.setHovering(false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                alignment: Alignment.center,
                height: 7.7.h,
                width: 70.sp,

                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        hoverProvider.isHovering
                            ? [Colors.amber.shade600, Colors.blue]
                            : [
                              Colors.blue,
                              const Color.fromARGB(255, 95, 78, 34),
                              Colors.lightBlueAccent,
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: widget.borderColor ?? Colors.amber,
                    width: 2.sp,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(23),
                    topLeft: Radius.circular(23),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    widget.loading == true
                        ? ProviderLoadingWidget()
                        : Text(
                          widget.title,
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: 15.sp,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
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

class HoverProvider with ChangeNotifier {
  bool _isHovering = false;

  bool get isHovering => _isHovering;

  void setHovering(bool value) {
    _isHovering = value;
    notifyListeners();
  }
}
