import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/numero_favori_service.dart';
import '../../services/api_service.dart';
import '../../models/numero_favori_model.dart';
import '../../services/user_service.dart';
import '../../services/contact_service.dart';

class NumerosFavorisCard extends StatefulWidget {
  final NumeroFavoriService numeroFavoriService;

  const NumerosFavorisCard({
    Key? key,
    required this.numeroFavoriService,
  }) : super(key: key);

  @override
  _NumerosFavorisCardState createState() => _NumerosFavorisCardState();
}

class _NumerosFavorisCardState extends State<NumerosFavorisCard> {
  List<NumeroFavori> _favoris = [];
  bool _isLoading = true;
  bool _isInitialized = false;
  final TextEditingController _searchController = TextEditingController();
  List<NumeroFavori> _filteredFavoris = [];
  int? _clientId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final userService = UserService(ApiService());
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser != null && currentUser.id != null) {
        final userId = int.parse(currentUser.id!);
        
        setState(() {
          _clientId = userId;
          _isInitialized = true;
        });
        print('User ID récupéré et converti: $userId');
        await _loadFavoris();
      } else {
        _showErrorSnackBar('Erreur: Utilisateur non connecté ou ID manquant');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur d\'initialisation détaillée: $e');
      _showErrorSnackBar('Erreur d\'initialisation');
      setState(() => _isLoading = false);
    }
  }

  void _filterFavoris(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFavoris = List.from(_favoris);
      } else {
        _filteredFavoris = _favoris.where((favori) {
          final nomLower = (favori.nom ?? '').toLowerCase();
          final numeroLower = favori.numeroTelephone.toLowerCase();
          final searchLower = query.toLowerCase();
          return nomLower.contains(searchLower) || 
                 numeroLower.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _loadFavoris() async {
    if (_clientId == null) {
      _showErrorSnackBar('Erreur: ID client non disponible');
      return;
    }

    try {
      setState(() => _isLoading = true);
      final favoris = await widget.numeroFavoriService.getAllNumerosFavoris(_clientId!);
      setState(() {
        _favoris = favoris;
        _filteredFavoris = List.from(favoris);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des favoris');
    }
  }

  Future<void> _ajouterFavori() async {
    if (_clientId == null) {
      _showErrorSnackBar('Erreur: ID client non disponible');
      return;
    }

    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ajouter un favori',
          style: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF8E21F0)),
              title: Text(
                'Saisir manuellement',
                style: GoogleFonts.poppins(),
              ),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.contacts, color: Color(0xFF8E21F0)),
              title: Text(
                'Choisir depuis les contacts',
                style: GoogleFonts.poppins(),
              ),
              onTap: () => Navigator.pop(context, 'contacts'),
            ),
          ],
        ),
      ),
    );

    if (method == null) return;

    if (method == 'manual') {
      await _ajouterFavoriManuel();
    } else {
      await _ajouterFavoriDepuisContacts();
    }
  }

  Future<void> _ajouterFavoriManuel() async {
    final numeroController = TextEditingController();
    final nomController = TextEditingController();

    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Nouveau favori',
          style: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numeroController,
              decoration: const InputDecoration(
                labelText: 'Numéro',
                labelStyle: TextStyle(color: Color(0xFF8E21F0)),
                prefixIcon: Icon(Icons.phone, color: Color(0xFF8E21F0)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom (optionnel)',
                labelStyle: TextStyle(color: Color(0xFF8E21F0)),
                prefixIcon: Icon(Icons.person, color: Color(0xFF8E21F0)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8E21F0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Ajouter',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (added == true && numeroController.text.isNotEmpty) {
      try {
        final favori = await widget.numeroFavoriService.ajouterNumeroFavori(
          clientId: _clientId!,
          numeroTelephone: numeroController.text,
          nom: nomController.text.isNotEmpty ? nomController.text : null,
        );

        if (favori != null) {
          await _loadFavoris();
        } else {
          _showErrorSnackBar('Erreur lors de l\'ajout du favori');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de l\'ajout du favori');
      }
    }

    numeroController.dispose();
    nomController.dispose();
  }

  Future<void> _ajouterFavoriDepuisContacts() async {
    try {
      final contactService = ContactService();
      final contact = await contactService.showContactPicker(context);

      if (contact != null) {
        final phoneNumber = contactService.getMainPhoneNumber(contact);
        
        if (phoneNumber != null) {
          final favori = await widget.numeroFavoriService.ajouterNumeroFavori(
            clientId: _clientId!,
            numeroTelephone: phoneNumber,
            nom: contact.displayName,
          );

          if (favori != null) {
            await _loadFavoris();
          } else {
            _showErrorSnackBar('Erreur lors de l\'ajout du favori');
          }
        } else {
          _showErrorSnackBar('Ce contact n\'a pas de numéro de téléphone');
        }
      }
    } catch (e) {
      print('Erreur détaillée: $e');
      _showErrorSnackBar('Erreur lors de la sélection du contact');
    }
  }

  Future<void> _supprimerFavori(NumeroFavori favori) async {
    if (_clientId == null) {
      _showErrorSnackBar('Erreur: ID client non disponible');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmer la suppression',
          style: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ce numéro des favoris ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await widget.numeroFavoriService.supprimerNumeroFavori(
          clientId: _clientId!,
          numeroTelephone: favori.numeroTelephone,
        );

        if (success) {
          await _loadFavoris();
        } else {
          _showErrorSnackBar('Erreur lors de la suppression');
        }
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Numéros favoris',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8E21F0),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E21F0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: _ajouterFavori,
                        child: const Icon(Icons.add, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _filterFavoris,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    hintStyle: GoogleFonts.poppins(),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8, 
                      horizontal: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFF8E21F0)),
              ),
            )
          else if (_filteredFavoris.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 36, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun numéro favori',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredFavoris.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final favori = _filteredFavoris[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, 
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF8E21F0).withOpacity(0.1),
                    radius: 16,
                    child: Text(
                      (favori.nom ?? 'S')[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8E21F0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    favori.nom ?? 'Sans nom',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  ),
                  subtitle: Text(
                    favori.numeroTelephone,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    onPressed: () => _supprimerFavori(favori),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}