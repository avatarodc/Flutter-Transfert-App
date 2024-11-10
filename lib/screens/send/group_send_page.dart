import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/transaction_service.dart';


class GroupSendPage extends StatefulWidget {
  const GroupSendPage({Key? key}) : super(key: key);

  @override
  State<GroupSendPage> createState() => _GroupSendPageState();
}

class _GroupSendPageState extends State<GroupSendPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  final _transactionService = TransactionService();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];

  // Calculs améliorés et dynamiques
  double get _amountPerPerson => double.tryParse(_amountController.text) ?? 0;
  double get _feesPerPerson => _amountPerPerson * 0.01; // 1% des frais par personne
  double get _totalPerPerson => _amountPerPerson + _feesPerPerson;
  double get _totalAmount => _amountPerPerson * _phoneControllers.length;
  double get _totalFees => _feesPerPerson * _phoneControllers.length; // Total des frais
  double get _grandTotal => _totalAmount + _totalFees;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _addControllersListener(_phoneControllers.first);
  }

  void _addControllersListener(TextEditingController controller) {
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addNewRecipient() {
    setState(() {
      var newController = TextEditingController();
      _addControllersListener(newController);
      _phoneControllers.add(newController);
    });
  }

  void _removeRecipient(int index) {
    setState(() {
      _phoneControllers[index].dispose();
      _phoneControllers.removeAt(index);
    });
  }

  Future<void> _selectContact(int index) async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(withProperties: true);
        
        // ignore: use_build_context_synchronously
        final contact = await showModalBottomSheet<Contact>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _ContactPicker(contacts: contacts),
        );

        if (contact?.phones.isNotEmpty ?? false) {
          setState(() {
            _phoneControllers[index].text = contact!.phones.first.number!;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permission d'accès aux contacts refusée")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

void _handleSend() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      setState(() => _isLoading = true);

      // Récupérer tous les numéros de téléphone
      final recipientPhoneNumbers = _phoneControllers
          .map((controller) => controller.text.trim())
          .toList();

      // Vérifier s'il y a des numéros en double
      final uniqueNumbers = Set<String>.from(recipientPhoneNumbers);
      if (uniqueNumbers.length != recipientPhoneNumbers.length) {
        throw Exception('Des numéros de téléphone sont en double');
      }

      // Récupérer le montant
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        throw Exception('Montant invalide');
      }

      // Afficher un indicateur de chargement
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Traitement en cours...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Appeler le service pour effectuer le transfert multiple
      await _transactionService.transferMultiple(
        recipientPhoneNumbers: recipientPhoneNumbers,
        amount: amount,
      );

      if (!mounted) return;

      // Succès : fermer la page et afficher le message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transferts effectués avec succès'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      // Extraire le message d'erreur
      String errorMessage = e.toString();
      String title = 'Erreur de transfert';
      
      // Nettoyer le message d'erreur
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }

      // Personnaliser le titre selon le type d'erreur
      if (errorMessage.contains('Solde insuffisant')) {
        title = 'Solde insuffisant';
      }
      
      // Afficher une boîte de dialogue d'erreur
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title == 'Solde insuffisant')
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.orange,
                  size: 48,
                ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF8E21F0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 16),
            Text('Transferts réussis!', 
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(
              '${_phoneControllers.length} transferts de ${_amountPerPerson.toStringAsFixed(0)} FCFA envoyés avec succès.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context)..pop()..pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Envoi groupé', 
          style: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF8E21F0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Section Montant
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant à envoyer par personne',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            hintText: 'Montant en FCFA',
                            prefixIcon: Icon(Icons.payments, color: Colors.grey[400]),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => v?.isEmpty ?? true ? 'Montant requis' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Section Destinataires
                  Text(
                    'Destinataires',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._phoneControllers.asMap().entries.map((entry) => _RecipientField(
                    controller: entry.value,
                    onSelectContact: () => _selectContact(entry.key),
                    onRemove: _phoneControllers.length > 1 
                      ? () => _removeRecipient(entry.key)
                      : null,
                  )),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: Text('Ajouter un destinataire', style: GoogleFonts.poppins()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8E21F0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addNewRecipient,
                  ),
                ],
              ),
            ),
            _TransferSummary(
              amountPerPerson: _amountPerPerson,
              feesPerPerson: _feesPerPerson,
              totalAmount: _totalAmount,
              totalFees: _totalFees,
              grandTotal: _grandTotal,
              recipientCount: _phoneControllers.length,
              onSend: _handleSend,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSelectContact;
  final VoidCallback? onRemove;

  const _RecipientField({
    required this.controller,
    required this.onSelectContact,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Numéro de téléphone',
                prefixIcon: Icon(Icons.phone, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true ? 'Numéro requis' : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.contacts, color: Color(0xFF8E21F0)),
            onPressed: onSelectContact,
            tooltip: 'Sélectionner un contact',
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onRemove,
              tooltip: 'Supprimer',
            ),
        ],
      ),
    );
  }
}

class _TransferSummary extends StatelessWidget {
  final double amountPerPerson;
  final double feesPerPerson;
  final double totalAmount;
  final double totalFees;
  final double grandTotal;
  final int recipientCount;
  final VoidCallback onSend;
  final bool isLoading;

  const _TransferSummary({
    required this.amountPerPerson,
    required this.feesPerPerson,
    required this.totalAmount,
    required this.totalFees,
    required this.grandTotal,
    required this.recipientCount,
    required this.onSend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Montant total',
            value: '${totalAmount.toStringAsFixed(0)} FCFA',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Total des frais',
            value: '${totalFees.toStringAsFixed(0)} FCFA',
            valueColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8E21F0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _SummaryRow(
              label: 'TOTAL À PAYER',
              value: '${grandTotal.toStringAsFixed(0)} FCFA',
              valueColor: const Color(0xFF8E21F0),
              isBold: true,
              isLarge: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E21F0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text('Envoyer au groupe',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;
  final bool isLarge;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold || isLarge ? FontWeight.w600 : FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isLarge ? 18 : 16,
            fontWeight: isBold || isLarge ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

class _ContactPicker extends StatelessWidget {
  final List<Contact> contacts;

  const _ContactPicker({required this.contacts});

  @override
  Widget build(BuildContext context) {
    final filteredContacts = contacts.where((contact) => 
      contact.phones.isNotEmpty).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sélectionner un contact',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${filteredContacts.length} contacts',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_missed, 
                          size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun contact avec numéro',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF8E21F0).withOpacity(0.1),
                          child: Text(
                            contact.displayName[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF8E21F0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          contact.phones.first.number ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () => Navigator.pop(context, contact),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
