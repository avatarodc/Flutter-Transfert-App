import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/balance_qr_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/transfer_form_card.dart';         
import 'widgets/recent_transactions_card.dart';    
import '../../models/transaction.dart';         

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Transaction> _mockTransactions = [
    Transaction(
      date: '2024-03-08',
      amount: '50.000',
      type: 'Envoi',
      recipient: '+221778889999',
      status: 'Succès',
    ),
    Transaction(
      date: '2024-03-07',
      amount: '25.000',
      type: 'Réception',
      recipient: '+221776665555',
      status: 'Succès',
    ),
  ];

  void _handleTransfer(String type, String recipient, double amount) {
    debugPrint('Type: $type, Recipient: $recipient, Amount: $amount');
  }

  void _handleViewAllTransactions() {
    debugPrint('View all transactions clicked');
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF8E21F0),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8E21F0),
              const Color(0xFF8E21F0).withOpacity(0.8),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'Accueil',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              debugPrint('Notifications clicked');
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              debugPrint('Profile clicked');
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF8E21F0),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const BalanceQrCard(
                    balance: '150.000',
                    qrData: 'user-123456789',
                  ),
                ),
                const SizedBox(height: 24),
                const QuickActions(),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TransferFormCard(
                    onTransfer: _handleTransfer,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RecentTransactionsCard(
                    transactions: _mockTransactions,
                    onViewAll: _handleViewAllTransactions,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}