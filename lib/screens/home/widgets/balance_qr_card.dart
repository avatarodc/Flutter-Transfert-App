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
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Solde
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde disponible',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedCrossFade(
                      firstChild: Text(
                        '${widget.balance} FCFA',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF001B8A),
                        ),
                      ),
                      secondChild: Text(
                        '••••••• FCFA',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF001B8A),
                        ),
                      ),
                      crossFadeState: _isBalanceHidden 
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(_isBalanceHidden ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                  },
                  color: const Color(0xFF001B8A),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // QR Code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Votre QR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: Implémenter le partage
                  },
                  color: const Color(0xFF001B8A),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrData,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scannez pour recevoir un paiement',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}