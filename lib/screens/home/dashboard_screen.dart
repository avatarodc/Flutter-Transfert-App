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
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrollPosition = _scrollController.position.pixels;
    final maxScroll = 100.0;
    
    setState(() {
      _scrollProgress = (scrollPosition / maxScroll).clamp(0.0, 1.0);
    });
  }

  PreferredSizeWidget _buildAppBar() {
    final Color backgroundColor = Color.lerp(
      Colors.white,
      const Color(0xFF8E21F0),
      _scrollProgress,
    )!;

    final Color iconColor = Color.lerp(
      const Color(0xFF8E21F0),
      Colors.white,
      _scrollProgress,
    )!;

    final Color containerColor = Color.lerp(
      const Color(0xFF8E21F0).withOpacity(0.1),
      Colors.white.withOpacity(0.2),
      _scrollProgress,
    )!;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: _scrollProgress * 4,
      toolbarHeight: 70,
      centerTitle: false,
      automaticallyImplyLeading: false,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Opacity(
          opacity: _scrollProgress,
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ),
      title: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.dashboard_rounded,
          color: iconColor,
          size: 24,
        ),
      ),
      actions: [
        // Bouton Notifications
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: iconColor,
                  size: 24,
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
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: backgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bouton Profil
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.person_outline,
              color: iconColor,
              size: 24,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handleRefresh() async {
    await _transactionsCardKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      endDrawer: const CustomDrawer(),
      body: RefreshIndicator(
        color: const Color(0xFF8E21F0),
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
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
                        color: Colors.black.withOpacity(0.05),
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RecentTransactionsCard(
                    key: _transactionsCardKey,
                    onViewAll: () {}, // Fonction vide car on ne navigue plus
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