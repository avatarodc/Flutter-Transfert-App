import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_service.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCompletController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomCompletController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    if (!RegExp(r'^\+\d{8,15}$').hasMatch(value)) {
      return 'Format invalide. Exemple: +221776543210';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 4) {
      return 'Le mot de passe doit contenir au moins 4 caractères';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

 Future<void> _handleRegister() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final userService = UserService(apiService);
      final response = await userService.register(
        nomComplet: _nomCompletController.text,
        numeroTelephone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inscription réussie',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF8E21F0),
            duration: const Duration(seconds: 2),
          ),
        );

        // Attendez un peu avant de rediriger
        await Future.delayed(const Duration(seconds: 2));
        
        // Redirigez vers la page de connexion
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'inscription: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bouton retour avec style moderne
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, 
                          color: Color(0xFF8E21F0),
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logo
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8E21F0).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo/next.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titre
                  Text(
                    'Inscription',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8E21F0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32), 

                  // Champs de formulaire
                  ..._buildFormFields(),

                  const SizedBox(height: 24),

                  // Bouton d'inscription
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E21F0).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E21F0),
                        foregroundColor: Colors.white,
                        elevation: 0,
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
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'S\'inscrire',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lien de connexion
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Déjà un compte ? Connectez-vous',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8E21F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Méthode pour construire les champs de formulaire
  List<Widget> _buildFormFields() {
    return [
      _buildFormField(
        controller: _nomCompletController,
        labelText: 'Nom complet',
        icon: Icons.person,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez entrer votre nom complet';
          }
          return null;
        },
        textCapitalization: TextCapitalization.words,
      ),
      const SizedBox(height: 16),

      _buildFormField(
        controller: _phoneController,
        labelText: 'Numéro de téléphone',
        icon: Icons.phone,
        validator: _validatePhone,
        keyboardType: TextInputType.phone,
        hintText: '+221776543210',
      ),
      const SizedBox(height: 16),

      _buildFormField(
        controller: _emailController,
        labelText: 'Email',
        icon: Icons.email,
        validator: _validateEmail,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 16),

      _buildPasswordField(
        controller: _passwordController,
        labelText: 'Mot de passe',
        icon: Icons.lock,
        obscureText: _obscurePassword,
        onToggleVisibility: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        validator: _validatePassword,
      ),
      const SizedBox(height: 16),

      _buildPasswordField(
        controller: _confirmPasswordController,
        labelText: 'Confirmer le mot de passe',
        icon: Icons.lock_outline,
        obscureText: _obscureConfirmPassword,
        onToggleVisibility: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
        validator: _validateConfirmPassword,
      ),
    ];
  }

  // Widget pour construire un champ de formulaire standard
  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontSize: 14,
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF8E21F0), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
      ),
    );
  }

  // Widget pour construire un champ de mot de passe
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(
            color: const Color(0xFF8E21F0),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF8E21F0), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: const Color(0xFF8E21F0),
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}