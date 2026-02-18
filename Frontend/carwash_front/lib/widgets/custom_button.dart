import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String? text; 
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final double? width;
  final double height;
  final Color? textColor;
  final Color? borderColor;
  final Widget? child; 
  final bool isGlass; // NEW: For modern transparent look

  const CustomButton({
    super.key,
    this.text, 
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.width,
    this.height = 56,
    this.textColor,
    this.borderColor,
    this.child,
    this.isGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isGlass ? Colors.white.withOpacity(0.15) : color,
          foregroundColor: textColor ?? Colors.white,
          elevation: isGlass ? 0 : 4,
          shadowColor: isGlass ? Colors.transparent : Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isGlass ? 30 : 16),
            side: borderColor != null 
                ? BorderSide(color: borderColor!, width: 2) 
                : (isGlass ? const BorderSide(color: Colors.white30) : BorderSide.none),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : child ?? 
                Text(
                  text ?? '', 
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