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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF8E21F0) : Colors.red.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? const Color(0xFF8E21F0) : Colors.red.shade800).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: 20, // Réduit de 28 à 20
          ),
          const SizedBox(width: 8), // Réduit de 12 à 8
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13, // Réduit de 16 à 13
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
    duration: const Duration(seconds: 2), // Réduit de 3 à 2 secondes
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12), // Réduit de 16 à 12
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}