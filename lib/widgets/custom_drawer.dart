import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final UserService _userService = UserService(ApiService());
  User? _currentUser;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = await _userService.getCurrentUser();
      if (!mounted) return;
      
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getRoleIcon() {
    if (_currentUser?.typeNotification == 'ADMIN') return '👑';
    if (_currentUser?.typeNotification == 'AGENT') return '🛡️';
    return '👤';
  }

  Color _getRoleColor() {
    if (_currentUser?.typeNotification == 'ADMIN') return const Color(0xFFFFD700);
    if (_currentUser?.typeNotification == 'AGENT') return const Color(0xFF4CAF50);
    return const Color(0xFF8E21F0);
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'FCFA',
      decimalDigits: 0,
      locale: 'fr_FR',
    ).format(amount);
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isLogout 
            ? Colors.red.withOpacity(0.1)
            : const Color(0xFF8E21F0).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLogout 
                ? Colors.red.withOpacity(0.1)
                : const Color(0xFF8E21F0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : const Color(0xFF8E21F0),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isLogout ? Colors.red.withOpacity(0.5) : Colors.grey[400],
          size: 20,
        ),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[50],
      child: SafeArea(
        child: _isLoading 
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E21F0)),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: GoogleFonts.poppins(
                              color: Colors.red[300],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _loadUserData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8E21F0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        _getRoleColor(),
                                        _getRoleColor().withOpacity(0.5),
                                      ],
                                    ),
                                  ),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/logo/next.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _getRoleIcon(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentUser?.nomComplet ?? 'Utilisateur',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              _currentUser?.numeroTelephone ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_currentUser?.email != null)
                              Text(
                                _currentUser!.email!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Affichage du solde pour les clients
                      if (_currentUser?.typeNotification == 'CLIENT')
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Solde disponible',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatCurrency(_currentUser?.solde ?? 0),
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8E21F0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildDrawerItem(
                                icon: Icons.person_outline,
                                title: 'Mon Profil',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/profile');
                                },
                              ),
                              if (_currentUser?.typeNotification == 'CLIENT')
                                _buildDrawerItem(
                                  icon: Icons.history,
                                  title: 'Historique',
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/transactions');
                                  },
                                ),
                              if (_currentUser?.typeNotification == 'ADMIN') ...[
                                _buildDrawerItem(
                                  icon: Icons.admin_panel_settings,
                                  title: 'Gestion des utilisateurs',
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/admin/users');
                                  },
                                ),
                                _buildDrawerItem(
                                  icon: Icons.analytics,
                                  title: 'Statistiques',
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/admin/stats');
                                  },
                                ),
                              ],
                              if (_currentUser?.typeNotification == 'AGENT')
                                _buildDrawerItem(
                                  icon: Icons.support_agent,
                                  title: 'Gestion des clients',
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/agent/clients');
                                  },
                                ),
                              _buildDrawerItem(
                                icon: Icons.settings_outlined,
                                title: 'Paramètres',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/settings');
                                },
                              ),
                              _buildDrawerItem(
                                icon: Icons.help_outline,
                                title: 'Aide & Support',
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/support');
                                },
                              ),
                              const SizedBox(height: 8),
                              _buildDrawerItem(
                                icon: Icons.logout,
                                title: 'Déconnexion',
                                onTap: () async {
                                  try {
                                    await _userService.logout();
                                    if (mounted) {
                                      Navigator.of(context).pushNamedAndRemoveUntil(
                                        '/login',
                                        (route) => false,
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                isLogout: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _currentUser?.estActif ?? false
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _currentUser?.estActif ?? false
                                        ? Icons.verified_user
                                        : Icons.warning,
                                    size: 16,
                                    color: _currentUser?.estActif ?? false
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentUser?.estActif ?? false
                                        ? 'Compte vérifié'
                                        : 'En attente de vérification',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: _currentUser?.estActif ?? false
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Version 1.0.0',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}