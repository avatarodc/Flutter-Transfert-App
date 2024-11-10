import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'all_transactions_page.dart'; 
import 'package:camera/camera.dart' as camera;
import 'package:barcode_scan2/barcode_scan2.dart';
import '../../send/send_options_page.dart';
import '../../numeroFavori/numeros_favoris_page.dart'; 


class QuickActions extends StatefulWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  _QuickActionsState createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions> {
  late List<camera.CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    _cameras = await camera.availableCameras();
  }

  Future<void> _scanQrCode() async {
    try {
      final result = await BarcodeScanner.scan();
      // Afficher le contenu du QR code
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Contenu du code QR'),
          content: Text(result.rawContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } on Exception catch (e) {
      // Gestion des erreurs de scan
      print('Erreur de scan : $e');
    }
  }

  void _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'historique':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AllTransactionsPage(),
          ),
        );
        break;
      case 'scanner':
        // Vérifier si les autorisations d'accès à la caméra sont accordées
        var status = await Permission.camera.request();
        if (status.isGranted) {
          // Ouvrir l'interface de l'appareil photo et scanner le QR code
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraPage(cameras: _cameras, onScanQrCode: _scanQrCode),
            ),
          );
        } else {
          // Afficher un message d'erreur si les autorisations ne sont pas accordées
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Veuillez accorder l\'accès à la caméra pour utiliser cette fonctionnalité.'),
            ),
          );
        }
        break;
      case 'envoyer':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SendOptionsPage(),
          ),
        );
        break;
      case 'favoris':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NumerosFavorisPage(),
          ),
        );
        break;
    }
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String action,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleAction(context, action),
              child: Icon(icon, color: color),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickActionButton(
          context: context,
          icon: Icons.qr_code_scanner,
          label: 'Scanner',
          color: const Color(0xFF001B8A),
          action: 'scanner',
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.send,
          label: 'Envoyer',
          color: Colors.green,
          action: 'envoyer',
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.star_outline,
          label: 'Favoris',
          color: const Color(0xFF8E21F0),
          action: 'favoris',
        ),
        _buildQuickActionButton(
          context: context,
          icon: Icons.history,
          label: 'Historique',
          color: Colors.purple,
          action: 'historique',
        ),
      ],
    );
  }
}

class CameraPage extends StatefulWidget {
  final List<camera.CameraDescription> cameras;
  final Future<void> Function() onScanQrCode;

  const CameraPage({
    Key? key,
    required this.cameras,
    required this.onScanQrCode,
  }) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late camera.CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraController = camera.CameraController(
      widget.cameras.first,
      camera.ResolutionPreset.medium,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appareil photo'),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Si l'initialisation est terminée, afficher la vue de la caméra
            return GestureDetector(
              onTap: widget.onScanQrCode,
              child: camera.CameraPreview(_cameraController),
            );
          } else {
            // Sinon, afficher un indicateur de chargement
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    // Libérer les ressources de la caméra lors de la fermeture de la page
    _cameraController.dispose();
    super.dispose();
  }
}