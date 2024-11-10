import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'all_transactions_page.dart'; 
import '../../send/send_options_page.dart'; 


class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'historique':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllTransactionsPage(),
          ),
        );
        break;
      case 'scanner':
        // Ajoutez la logique pour le scanner
        break;
      case 'envoyer':
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SendOptionsPage(),
        ),
      );
      break;
      case 'banque':
        // Ajoutez la logique pour la banque
        break;
    }
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String action,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleAction(context, action),
              child: Icon(icon, color: color),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickActionButton(
          context: context,
          icon: Icons.qr_code_scanner,
          label: 'Scanner',
          color: const Color(0xFF001B8A),
          action: 'scanner',
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.send,
          label: 'Envoyer',
          color: Colors.green,
          action: 'envoyer',
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.account_balance,
          label: 'Banque',
          color: Colors.orange,
          action: 'banque',
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.history,
          label: 'Historique',
          color: Colors.purple,
          action: 'historique',
        ),
      ],
    );
  }
}