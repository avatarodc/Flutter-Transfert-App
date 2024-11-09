import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/balance_qr_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/recent_transactions_card.dart';
import '../../models/transaction.dart';
import '../../widgets/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RecentTransactionsCardState> _transactionsCardKey = GlobalKey<RecentTransactionsCardState>();

  void _handleTransfer(String type, String recipient, double amount) {
    debugPrint('Type: $type, Recipient: $recipient, Amount: $amount');
  }

  void _handleViewAllTransactions() {
    Navigator.pushNamed(context, '/transactions');
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF8E21F0),
      elevation: 0,
      toolbarHeight: 70,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8E21F0),
              const Color(0xFF9C47FF),
              const Color(0xFFAB69FF),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.dashboard_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 700),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-20 * (1 - value), 0),
                  child: child,
                ),
              );
            },
            child: Text(
              'Accueil',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // ... Reste du code des actions
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 900),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, 
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    debugPrint('Notifications clicked');
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 1100),
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    // Rafraîchir les transactions
    await _transactionsCardKey.currentState?.refresh();
    // Ajoutez ici d'autres rafraîchissements si nécessaire
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      endDrawer: const CustomDrawer(),
      body: RefreshIndicator(
        color: const Color(0xFF8E21F0),
        onRefresh: _handleRefresh,
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
                  child: const BalanceQrCard(),
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
                  child: RecentTransactionsCard(
                    key: _transactionsCardKey,
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