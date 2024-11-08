// lib/screens/home/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/balance_qr_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/transfer_form_card.dart';         
import 'widgets/recent_transactions_card.dart';    
import '../../models/transaction.dart';         

class DashboardScreen extends StatefulWidget {  // Changé en StatefulWidget
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
      title: Text(
        'Tableau de bord',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF001B8A),
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            debugPrint('Notifications clicked');
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            debugPrint('Profile clicked');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            height: 100,
            color: const Color(0xFF001B8A),
          ),
          RefreshIndicator(
            color: const Color(0xFF001B8A),
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BalanceQrCard(
                      balance: '150.000',
                      qrData: 'user-123456789',
                    ),
                    const SizedBox(height: 24),

                    const QuickActions(),
                    const SizedBox(height: 24),

                    TransferFormCard(
                      onTransfer: _handleTransfer,
                    ),
                    const SizedBox(height: 24),

                    RecentTransactionsCard(
                      transactions: _mockTransactions,
                      onViewAll: _handleViewAllTransactions,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}