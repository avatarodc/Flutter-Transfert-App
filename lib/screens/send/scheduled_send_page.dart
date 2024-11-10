// ---------- PARTIE 1: Imports et Formateur de numéro de téléphone ----------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/planification_transfert_service.dart';
import '../../services/api_service.dart';
import '../../services/user_service.dart';
import '../../services/contact_service.dart';
import '../../models/periodicity_model.dart';
import '../../models/planification_transfert_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;

// Formateur personnalisé pour les numéros de téléphone
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Si l'utilisateur essaie de modifier le +221, on l'en empêche
    if (!text.startsWith('+221')) {
      text = '+221${text.replaceAll('+221', '')}';
    }

    // Supprimer tous les caractères non numériques sauf le +
    text = text.replaceAll(RegExp(r'[^\d+]'), '');

    // Limiter à 9 chiffres après le +221
    if (text.length > 13) { // +221 = 4 caractères + 9 chiffres max
      text = text.substring(0, 13);
    }

    // Formatter le numéro pour une meilleure lisibilité
    if (text.length > 4) {
      String prefix = text.substring(0, 4); // +221
      String rest = text.substring(4);
      
      // Formatter les groupes de chiffres
      List<String> groups = [];
      for (int i = 0; i < rest.length; i += 2) {
        if (i + 2 <= rest.length) {
          groups.add(rest.substring(i, i + 2));
        } else {
          groups.add(rest.substring(i));
        }
      }
      text = '$prefix ${groups.join(' ')}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class Contact {
  final String name;
  final String phoneNumber;

  Contact({required this.name, required this.phoneNumber});
}

// ---------- PARTIE 2: Déclaration de classe et variables d'état ----------

class ScheduledSendPage extends StatefulWidget {
  const ScheduledSendPage({Key? key}) : super(key: key);

  @override
  State<ScheduledSendPage> createState() => _ScheduledSendPageState();
}

class _ScheduledSendPageState extends State<ScheduledSendPage> {
  // Contrôleurs
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController(text: '+221 ');
  final _scrollController = ScrollController();

  // Services
  final planificationService = PlanificationTransfertService(ApiService());
  final userService = UserService(ApiService());
  final contactService = ContactService();

  // Variables d'état
  bool _isLoading = false;
  Contact? _selectedContact;
  TimeOfDay? _selectedTime;
  Periodicity _selectedPeriodicity = Periodicity.JOURNALIER;
  String? _currentUserPhone;

  // Périodicités disponibles
  final Map<Periodicity, String> _periodicites = {
    Periodicity.JOURNALIER: 'Quotidien',
    Periodicity.HEBDOMADAIRE: 'Hebdomadaire',
    Periodicity.MENSUEL: 'Mensuel',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Méthodes utilitaires
  String _formatPhoneForApi(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+221')) {
      cleaned = '+221$cleaned';
    }
    if (cleaned.length > 13) {
      cleaned = cleaned.substring(0, 13);
    }
    return cleaned;
  }

  // ---------- PARTIE 3: Méthodes de gestion des événements ----------

  Future<void> _loadCurrentUser() async {
    try {
      final currentUser = await userService.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _currentUserPhone = _formatPhoneForApi(currentUser.numeroTelephone);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectContact() async {
    try {
      final contact = await contactService.showContactPicker(context);
      if (contact != null && mounted) {
        final phoneNumber = contactService.getMainPhoneNumber(contact);
        if (phoneNumber != null) {
          String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
          if (cleaned.length > 9) {
            cleaned = cleaned.substring(cleaned.length - 9);
          }
          
          setState(() {
            _selectedContact = Contact(
              name: contact.displayName,
              phoneNumber: '+221 ${cleaned.replaceAllMapped(
                RegExp(r'(\d{2})(\d{3})(\d{2})(\d{2})'),
                (Match m) => '${m[1]} ${m[2]} ${m[3]} ${m[4]}'
              )}'
            );
            _phoneController.text = _selectedContact!.phoneNumber;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8E21F0),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _handleSchedule() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_currentUserPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une heure d\'exécution'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Créer une instance de PlanificationTransfert
        final planification = PlanificationTransfert(
          expediteurTelephone: _currentUserPhone!,
          destinataireTelephone: _formatPhoneForApi(_phoneController.text),
          montant: double.parse(_amountController.text),
          periodicite: _selectedPeriodicity,
          referenceGroupe: DateTime.now().millisecondsSinceEpoch.toString(),
          heureExecution: "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}" // Format HH:mm
        );

        print('Données envoyées: ${planification.toJson()}');

        await planificationService.createPlanification(planification);

        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // ---------- PARTIE 4: Dialogues et début du build ----------

  void _showSuccessDialog() {
    showDialog(
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
              'Planification réussie!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre transfert de ${NumberFormat.currency(
                locale: 'fr_FR',
                symbol: 'FCFA',
                decimalDigits: 0,
              ).format(double.parse(_amountController.text))} '
              'sera envoyé à ${_selectedContact?.name ?? _phoneController.text} ${_selectedPeriodicity.libelle.toLowerCase()}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8E21F0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Erreur',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Une erreur est survenue lors de la planification: $error',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color(0xFF8E21F0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Planifier un transfert',
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
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ---------- PARTIE 5: Suite et fin du build ----------
                      // Section Contact
                      Text(
                        'Contact destinataire',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  hintText: '+221 XX XXX XX XX',
                                  prefixIcon: Icon(Icons.phone, color: Colors.grey[400]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                inputFormatters: [PhoneNumberFormatter()],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un numéro';
                                  }
                                  
                                  String cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');
                                  if (cleaned.length != 13) {
                                    return 'Format invalide: +221 XX XXX XX XX';
                                  }
                                  
                                  return null;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.contact_phone),
                              color: const Color(0xFF8E21F0),
                              onPressed: _selectContact,
                              tooltip: 'Sélectionner depuis les contacts',
                            ),
                          ),
                        ],
                      ),
                      if (_selectedContact != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _selectedContact!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Section Montant
                      Text(
                        'Montant',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          hintText: 'Montant en FCFA',
                          prefixIcon: Icon(Icons.attach_money, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorStyle: GoogleFonts.poppins(
                            color: Colors.red,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un montant';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Montant invalide';
                          }
                          if (amount < 100) {
                            return 'Le montant minimum est de 100 FCFA';
                          }
                          if (amount > 1000000) {
                            return 'Le montant maximum est de 1 000 000 FCFA';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Section Périodicité
                      Text(
                        'Périodicité',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<Periodicity>(
                          value: _selectedPeriodicity,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _periodicites.entries.map((entry) {
                            return DropdownMenuItem<Periodicity>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: GoogleFonts.poppins(),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPeriodicity = value;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section Heure
                      Text(
                        'Heure d\'exécution',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                _selectedTime != null
                                    ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Choisir une heure',
                                style: GoogleFonts.poppins(
                                  color: _selectedTime != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                      // Bouton de planification
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E21F0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.schedule),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Planifier',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
