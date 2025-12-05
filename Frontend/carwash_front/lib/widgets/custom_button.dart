import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String? text; // Make text optional
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final double? width;
  final double height;
  final Color? textColor;
  final Color? borderColor;
  final Widget? child; // New parameter for child widget

  const CustomButton({
    super.key,
    this.text, // Make text optional
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.width,
    this.height = 56,
    this.textColor,
    this.borderColor,
    this.child, // Initialize new parameter
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : child ?? // Render child if provided
                Text(
                  text ?? '', // Fallback to empty string if text is null
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.white,
                  ),
                ),
      ),
    );
  }
}
