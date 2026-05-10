import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final EdgeInsetsGeometry? margin;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    required this.controller,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final hintColor = isDark ? Colors.white60 : const Color.fromARGB(255, 69, 89, 99);
    final iconColor = isDark ? const Color(0xFF2DD4BF) : AppColors.primary;
    final borderColor = isDark ? Colors.white12 : AppColors.backgroundMint;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : AppColors.primary.withOpacity(0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: iconColor,
        style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: iconColor),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: borderColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              width: 2,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}