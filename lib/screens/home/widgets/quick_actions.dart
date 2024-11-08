import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickActionButton(
          icon: Icons.qr_code_scanner,
          label: 'Scanner',
          color: const Color(0xFF001B8A),
        ),
        _buildQuickActionButton(
          icon: Icons.send,
          label: 'Envoyer',
          color: Colors.green,
        ),
        _buildQuickActionButton(
          icon: Icons.account_balance,
          label: 'Banque',
          color: Colors.orange,
        ),
        _buildQuickActionButton(
          icon: Icons.history,
          label: 'Historique',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}