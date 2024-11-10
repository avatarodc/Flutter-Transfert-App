import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  List<Contact> _contacts = [];
  bool _hasLoaded = false;

  Future<List<Contact>> getContacts() async {
    if (_hasLoaded) return _contacts;
    
    try {
      if (await FlutterContacts.requestPermission()) {
        _contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );
        _contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
        _hasLoaded = true;
        return _contacts;
      } else {
        throw Exception('Permission d\'accès aux contacts refusée');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des contacts: $e');
    }
  }

  Future<Contact?> showContactPicker(BuildContext context) async {
    try {
      // Vérifier si les contacts ont déjà été chargés
      if (_contacts.isEmpty) {
        await getContacts();
      }

      return await showModalBottomSheet<Contact>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
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
                    Text(
                      'Sélectionner un contact',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    final phone = contact.phones.isNotEmpty 
                        ? contact.phones.first.number 
                        : '';
                    
                    if (phone.isEmpty) return const SizedBox.shrink();

                    return ListTile(
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
                        phone,
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
        ),
      );
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du contact : $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  String? getMainPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) return null;
    return contact.phones.first.number;
  }
}