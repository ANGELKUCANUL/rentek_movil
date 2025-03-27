import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetToast();
    } else {
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      });
    }
  }

  void _showNoInternetToast() {
    Fluttertoast.showToast(
      msg: "Sin conexión a Internet. Verifica e intenta de nuevo.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16,
    );

    Future.delayed(Duration(seconds: 2), () {
      _showRetryDialog();
    });
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text(
                "Sin conexión",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              ),
            ],
          ),
          content: Text(
            "Por favor, verifica tu conexión a Internet e intenta de nuevo.",
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey[700]),
              onPressed: () {
                Navigator.pop(context);
                _checkInternetConnection();
              },
              child: Text("Reintentar", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // Fondo oscuro y profesional
      body: Stack(
        children: [
          // Fondo decorativo (opcional: gradiente)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueGrey[900]!,
                  Colors.blueGrey[800]!,
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagen con animación
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey[700]!.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/image/maqui.png', // Asegúrate de tener esta imagen
                    width: 120,
                    height: 120,
                    color: Colors.white, // Opcional: ajustar color de la imagen
                  ),
                ).animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: Offset(0.7, 0.7), end: Offset(1, 1), curve: Curves.easeOut)
                    .then()
                    .rotate(duration: 600.ms, begin: -0.05, end: 0, curve: Curves.easeInOut),

                SizedBox(height: 30),

                // Texto de bienvenida
                Column(
                  children: [
                    Text(
                      "Bienvenido a",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.blueGrey[100],
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ).animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOut),

                    SizedBox(height: 8),

                    Text(
                      "Rentek",
                      style: TextStyle(
                        fontSize: 52,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.blueGrey[400]!.withOpacity(0.5),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(duration: 800.ms)
                        .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1), duration: 1000.ms, curve: Curves.easeOut)
                        .then()
                        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.7)),
                  ],
                ),

                SizedBox(height: 40),

                // Indicador de carga
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey[200]!),
                  strokeWidth: 3,
                  backgroundColor: Colors.blueGrey[700]!.withOpacity(0.3),
                ).animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1), duration: 600.ms, curve: Curves.easeInOut)
                    .then()
                    .rotate(duration: 1500.ms, curve: Curves.easeInOut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}