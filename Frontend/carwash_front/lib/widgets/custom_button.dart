import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;
  final double? width;
  final double height; // New parameter for height
  final Color? textColor;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.width,
    this.height = 56, // Default height to 56
    this.textColor,
    this.borderColor,
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
            side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none, // Apply border
          ),
          elevation: 2,
        ),
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  text,
                  style: TextStyle( // Use TextStyle to apply dynamic color
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor ?? Colors.white, // Use textColor if provided, otherwise default to white
                  ),
                ),
      ),
    );
  }
}
