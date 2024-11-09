import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class BalanceQrCard extends StatefulWidget {
  final String balance;
  final String qrData;

  const BalanceQrCard({
    Key? key,
    required this.balance,
    required this.qrData,
  }) : super(key: key);

  @override
  State<BalanceQrCard> createState() => _BalanceQrCardState();
}

class _BalanceQrCardState extends State<BalanceQrCard> {
  bool _isBalanceHidden = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8E21F0),
            const Color(0xFF8E21F0).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E21F0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: CardPatternPainter(),
            child: Container(),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isBalanceHidden ? '••••••• FCFA' : '${widget.balance} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 8),
                      icon: Icon(
                        _isBalanceHidden ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isBalanceHidden = !_isBalanceHidden;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(  // Ajout du widget Center ici
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: widget.qrData,
                      version: QrVersions.auto,
                      size: 140.0,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: const Color(0xFF8E21F0),
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: const Color(0xFF8E21F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
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

    final spacing = 40.0;
    for (double i = -spacing; i < size.width + spacing; i += spacing) {
      for (double j = -spacing; j < size.height + spacing; j += spacing) {
        canvas.drawCircle(Offset(i, j), 4, paint);
        
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}   