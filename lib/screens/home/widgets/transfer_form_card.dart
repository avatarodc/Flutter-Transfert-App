// lib/screens/home/widgets/transfer_form_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TransferFormCard extends StatefulWidget {
  final Function(String type, String recipient, double amount) onTransfer;

  const TransferFormCard({
    Key? key,
    required this.onTransfer,
  }) : super(key: key);

  @override
  State<TransferFormCard> createState() => _TransferFormCardState();
}

class _TransferFormCardState extends State<TransferFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _recipientController = TextEditingController();
  String _selectedTransferType = 'Transfert Direct';

  @override
  void dispose() {
    _amountController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      widget.onTransfer(_selectedTransferType, _recipientController.text, amount);
    }
  }

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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Effectuer un transfert',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildDropdownField(),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildAmountField(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleTransfer,
                child: Text(
                  'Transférer',
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
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Type de transfert',
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
          border: InputBorder.none,
        ),
        value: _selectedTransferType,
        items: ['Transfert Direct', 'QR Code', 'Transfert Bancaire']
            .map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedTransferType = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _recipientController,
        decoration: InputDecoration(
          labelText: 'Numéro du destinataire',
          prefixIcon: const Icon(Icons.phone),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un numéro';
          }
          if (!RegExp(r'^\+\d{8,15}$').hasMatch(value)) {
            return 'Format invalide. Exemple: +221776543210';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: _amountController,
        decoration: InputDecoration(
          labelText: 'Montant',
          prefixIcon: const Icon(Icons.attach_money),
          suffixText: 'FCFA',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer un montant';
          }
          final amount = double.tryParse(value.replaceAll(',', '.'));
          if (amount == null || amount <= 0) {
            return 'Veuillez entrer un montant valide';
          }
          return null;
        },
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
        ],
      ),
    );
  }
}