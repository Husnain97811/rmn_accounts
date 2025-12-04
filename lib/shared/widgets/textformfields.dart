import 'package:flutter/material.dart';
import 'package:rmn_accounts/utils/views.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final EdgeInsetsGeometry? contentpadding;
  final String labelText;
  final IconData prefixIcon;
  final IconButton? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLines;
  final bool? autoFocus;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.contentpadding,
    required this.labelText,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines,
    this.onTap,
    this.autoFocus,
    bool? autofocus,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding:
            contentpadding ??
            EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 3.w),
        filled: true,
        fillColor: Colors.white30,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      autofocus: autoFocus ?? false,
    );
  }
}
