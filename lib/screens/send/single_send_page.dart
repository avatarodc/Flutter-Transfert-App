import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';
import '../../services/transaction_service.dart';

class SingleSendPage extends StatefulWidget {
  const SingleSendPage({Key? key}) : super(key: key);

  @override
  State<SingleSendPage> createState() => _SingleSendPageState();
}

class _SingleSendPageState extends State<SingleSendPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _feesController = TextEditingController();
  final _totalController = TextEditingController();
  final _contactService = ContactService();
  final _transactionService = TransactionService();
  bool _isLoading = false;
  Contact? _selectedContact;

  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await _contactService.showContactPicker(context);
        if (contact != null && mounted) {
          setState(() {
            _selectedContact = contact;
            _phoneController.text = contact.phones?.firstOrNull?.number ?? '';
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez autoriser l\'accès aux contacts pour utiliser cette fonctionnalité.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'accès aux contacts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un numéro de téléphone';
    }
    // Supprimer tous les caractères non numériques sauf +
    String cleanNumber = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+221$cleanNumber';
    }
    if (cleanNumber.length < 12) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un montant';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Montant invalide';
    }
    if (amount <= 0) {
      return 'Le montant doit être supérieur à 0';
    }
    if (amount > 1000000) {
      return 'Le montant maximum est de 1,000,000 FCFA';
    }
    return null;
  }

  Future<void> _handleSend() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Préparer les données
        String phoneNumber = _phoneController.text.trim();
        if (!phoneNumber.startsWith('+')) {
          phoneNumber = '+221$phoneNumber';
        }
        final amount = double.parse(_amountController.text);
        
        // Effectuer le transfert
        final transaction = await _transactionService.transferMoney(
          recipientPhone: phoneNumber,
          amount: amount,
        );
        
        if (!mounted) return;

        // Afficher le dialogue de succès
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Transfert réussi!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre transfert de ${_amountController.text} FCFA a été envoyé à ${_selectedContact?.displayName ?? phoneNumber}.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Référence: ${transaction.id}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Ferme le dialogue
                  Navigator.of(context).pop(); // Retourne à l'écran précédent
                },
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
      } catch (e) {
        if (!mounted) return;
        // Afficher le message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _updateFeesAndTotal() {
    final amount = double.tryParse(_amountController.text);
    if (amount != null) {
      final fees = amount * 0.01; // Calcul des frais à 1%
      _feesController.text = fees.toStringAsFixed(2); // Mise à jour du champ des frais
      
      // Calcul du total
      final total = amount + fees;
      _totalController.text = total.toStringAsFixed(2); // Mise à jour du champ total
    } else {
      _feesController.clear(); // Effacer si le montant n'est pas valide
      _totalController.clear(); // Effacer le total si le montant n'est pas valide
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Envoi direct',
          style: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: const Color(0xFF8E21F0),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Destinataire',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    hintText: 'Entrez un numéro de téléphone',
                    prefixIcon: Icon(Icons.phone, color: const Color(0xFF8E21F0)),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.contact_phone, color: const Color(0xFF8E21F0)),
                      onPressed: _pickContact,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  validator: _validatePhoneNumber,
                ),
                const SizedBox(height: 12),
                Text(
                  'Montant',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: 'Montant en FCFA',
                    prefixIcon: Icon(Icons.attach_money, color: const Color(0xFF8E21F0)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validateAmount,
                  onChanged: (value) => _updateFeesAndTotal(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Frais (1%)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _feesController,
                  decoration: InputDecoration(
                    hintText: 'Frais en FCFA',
                    prefixIcon: Icon(Icons.money_off, color: const Color(0xFF8E21F0)),
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  readOnly: true,
                  style: TextStyle(color: const Color(0xFF8E21F0)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _totalController,
                  decoration: InputDecoration(
                    hintText: 'Total en FCFA',
                    prefixIcon: Icon(Icons.attach_money, color: const Color(0xFF8E21F0)),
                    filled: true,
                    fillColor: Colors.grey[300],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  readOnly: true,
                  style: TextStyle(color: const Color(0xFF8E21F0)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E21F0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Envoyer',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _feesController.dispose();
    _totalController.dispose();
    super.dispose();
  }
}