import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/transaction.dart';
import '../../../services/transaction_service.dart';
import '../../../services/api_config.dart';

extension TransactionExtension on Transaction {
  bool get isCancelable {
    final now = DateTime.now();
    final transactionTime = DateTime.parse(this.date);
    return now.difference(transactionTime).inMinutes < 30 && isCancleable;
  }
}

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final TransactionService _transactionService = TransactionService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnectionAndLoadData();
  }

  Future<void> _checkConnectionAndLoadData() async {
    _isConnected = await ApiConfig.checkServerConnection();
    if (_isConnected) {
      await _loadTransactions();
    } else {
      setState(() {
        _error = 'Impossible de se connecter au serveur';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final transactions = await _transactionService.getMyTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Erreur lors du chargement des transactions';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Réessayer',
            textColor: Colors.white,
            onPressed: _loadTransactions,
          ),
        ),
      );
    }
  }

  Widget _buildDetailTile(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETE':
        return Colors.green;
      case 'EN_ATTENTE':
        return Colors.orange;
      case 'ANNULE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: transaction.type.color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Barre de poignée
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Titre et bouton fermer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Détails de la transaction',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8E21F0),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: transaction.type.color.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        transaction.type.icon,
                        size: 40,
                        color: transaction.type.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      transaction.formattedAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Corps des détails
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailTile(
                      'Type',
                      transaction.type.label,
                      Icons.category,
                      transaction.type.color,
                    ),
                    _buildDetailTile(
                      'Date',
                      transaction.formattedDate,
                      Icons.access_time,
                      Colors.blue,
                    ),
                    _buildDetailTile(
                      'Statut',
                      transaction.statusFormatted,
                      Icons.info_outline,
                      _getStatusColor(transaction.status),
                    ),
                    _buildDetailTile(
                      'Bénéficiaire',
                      transaction.recipient,
                      Icons.person_outline,
                      Colors.green,
                    ),
                    if (transaction.reference != null)
                      _buildDetailTile(
                        'Référence',
                        transaction.reference!,
                        Icons.tag,
                        Colors.indigo,
                      ),
                    if (transaction.motifAnnulation != null)
                      _buildDetailTile(
                        'Motif d\'annulation',
                        transaction.motifAnnulation!,
                        Icons.cancel_outlined,
                        Colors.red,
                      ),
                  ],
                ),
              ),

              // Bouton d'annulation si disponible
                // Bouton d'annulation si disponible
                if (transaction.isCancelable)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Ajout d'une boîte de dialogue de confirmation
                          final confirmer = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) => AlertDialog(
                              title: Text(
                                'Confirmation',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'Voulez-vous vraiment annuler cette transaction ?',
                                style: GoogleFonts.poppins(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    'Non',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Oui, annuler',
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmer == true) {
                            // Afficher indicateur de chargement
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Annulation en cours...'),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            // Appeler le service pour annuler
                            await _transactionService.cancelTransaction(
                              transaction.id.toString(),
                            );

                            if (!mounted) return;
                            
                            // Fermer la modal
                            Navigator.pop(context);
                            
                            // Rafraîchir les transactions
                            await _loadTransactions();
                            
                            // Afficher message de succès
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Transaction annulée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annuler la transaction',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Historique des transactions',
          style: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8E21F0)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _checkConnectionAndLoadData,
        color: const Color(0xFF8E21F0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E21F0)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  color: Colors.red[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkConnectionAndLoadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E21F0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction',
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTransactionDetails(transaction),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: transaction.type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          transaction.type.icon,
                          color: transaction.type.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    transaction.formattedAmount,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: transaction.type.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    transaction.type.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: transaction.type.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              transaction.recipient,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              transaction.formattedDate,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
