import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomSnackbar extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const CustomSnackbar({
    Key? key,
    required this.message,
    this.isSuccess = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF8E21F0) : Colors.red.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? const Color(0xFF8E21F0) : Colors.red.shade800).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showCustomSnackbar(BuildContext context, String message, bool isSuccess) {
  final snackBar = SnackBar(
    content: CustomSnackbar(
      message: message,
      isSuccess: isSuccess,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    duration: const Duration(seconds: 3),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}