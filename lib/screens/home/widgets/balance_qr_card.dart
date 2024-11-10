import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/user_service.dart';
import '../../../services/api_service.dart';
import '../../../services/transaction_service.dart';
import '../../../models/user_model.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class BalanceQrCard extends StatefulWidget {
  const BalanceQrCard({Key? key}) : super(key: key);

  @override
  State<BalanceQrCard> createState() => _BalanceQrCardState();
}

class _BalanceQrCardState extends State<BalanceQrCard> {
  bool _isBalanceHidden = false;
  late final UserService _userService;
  late final TransactionService _transactionService;
  User? _currentUser;
  final _numberFormat = NumberFormat('#,###', 'fr_FR');
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  StreamSubscription? _transactionSubscription;

  @override
  void initState() {
    super.initState();
    _userService = UserService(ApiService());
    _transactionService = TransactionService();
    _initializeData();
    _setupAutoRefresh();
    _setupTransactionListener();
    print('🚀 BalanceQrCard initialisé');
  }

  @override
  void dispose() {
    print('🔚 Nettoyage des ressources de BalanceQrCard');
    _refreshTimer?.cancel();
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _setupTransactionListener() {
    print('🎧 Configuration de l\'écouteur de transactions');
    _transactionSubscription = TransactionService.onTransactionCompleted.listen((_) {
      print('🔔 Transaction détectée, rafraîchissement du solde...');
      _refreshBalance();
    });
  }

  void _setupAutoRefresh() {
    print('⏰ Configuration du rafraîchissement automatique');
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      print('⏰ Rafraîchissement automatique déclenché');
      _refreshBalance();
    });
  }

  Future<void> _refreshBalance() async {
    if (_isRefreshing) {
      print('⏳ Rafraîchissement déjà en cours, ignoré');
      return;
    }
    
    print('🔄 Début du rafraîchissement du solde');
    setState(() {
      _isRefreshing = true;
    });

    try {
      print('📊 Récupération des transactions...');
      await _transactionService.getMyTransactions();
      print('👤 Mise à jour des données utilisateur...');
      await _initializeData();
      print('✅ Rafraîchissement terminé avec succès');
    } catch (e) {
      print('❌ Erreur lors du rafraîchissement: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _initializeData() async {
    print('🔄 Initialisation des données...');
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          print('💰 Nouveau solde: ${user?.solde} F CFA');
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
    }
  }

  String _formatBalance(double balance) {
    return _numberFormat.format(balance);
  }

  void _showQrCodeModal() {
    if (_currentUser?.codeQr == null) {
      print('⚠️ Pas de QR Code disponible');
      return;
    }

    print('📱 Affichage du QR Code');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8E21F0),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
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
    return RefreshIndicator(
      onRefresh: _refreshBalance,
      color: const Color(0xFF8E21F0),
      backgroundColor: Colors.white,
      displacement: 20,
      edgeOffset: 8,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: 130,
          decoration: _buildCardDecoration(),
          child: Stack(
            children: [
              CustomPaint(
                painter: CardPatternPainter(),
                size: MediaQuery.of(context).size,
              ),
              if (_isRefreshing)
                const Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              _buildMainContent(),
            ],
          ),
        ),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Solde actuel',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isBalanceHidden
                                ? '••••• F'
                                : '${_formatBalance(_currentUser!.solde)} F',
                            style: GoogleFonts.poppins(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() {
                            _isBalanceHidden = !_isBalanceHidden;
                            print('👁️ Visibilité du solde: ${_isBalanceHidden ? 'masqué' : 'visible'}');
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              _isBalanceHidden ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 70,
            padding: const EdgeInsets.all(0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showQrCodeModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 28,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 50,
            height: 50,
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