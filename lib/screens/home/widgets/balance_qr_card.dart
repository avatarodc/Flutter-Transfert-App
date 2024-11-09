import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/user_service.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import 'dart:convert';

class BalanceQrCard extends StatefulWidget {
  const BalanceQrCard({Key? key}) : super(key: key);

  @override
  State<BalanceQrCard> createState() => _BalanceQrCardState();
}

class _BalanceQrCardState extends State<BalanceQrCard> {
  bool _isBalanceHidden = false;
  late final UserService _userService;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _userService = UserService(ApiService());
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (_) {}
  }

  void _showQrCodeModal() {
    if (_currentUser?.codeQr == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8E21F0),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8E21F0).withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Image.memory(
                  base64Decode(_currentUser!.codeQr!),
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8E21F0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // Hauteur réduite
      decoration: _buildCardDecoration(),
      child: Stack(
        children: [
          CustomPaint(
            painter: CardPatternPainter(),
            size: Size.infinite,
          ),
          _buildMainContent(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentUser == null) {
      return _buildPlaceholderContent();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Solde actuel',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isBalanceHidden
                          ? '••••••• FCFA'
                          : '${_currentUser!.solde.toStringAsFixed(0)} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _isBalanceHidden = !_isBalanceHidden),
                      child: Icon(
                        _isBalanceHidden ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showQrCodeModal,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'QR Code',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 180,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF8E21F0),
          const Color(0xFF8E21F0).withOpacity(0.9),
        ],
        stops: const [0.2, 0.9],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF8E21F0).withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final spacing = 30.0;
    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      for (double j = -spacing; j < size.height + spacing; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.5, dotPaint);
        
        if (i < size.width - spacing) {
          canvas.drawLine(
            Offset(i, j),
            Offset(i + spacing, j),
            paint,
          );
        }
        
        if (j < size.height - spacing) {
          canvas.drawLine(
            Offset(i, j),
            Offset(i, j + spacing),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}