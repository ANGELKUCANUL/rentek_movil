import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Para verificar la conexión
import 'package:fluttertoast/fluttertoast.dart'; // Para mostrar notificaciones tipo "toast"
import 'main.dart'; // Asegúrate de importar tu pantalla principal

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

  // Método para verificar la conexión a Internet
  Future<void> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // No hay conexión a Internet
      _showNoInternetToast();
    } else {
      // Hay conexión a Internet, navegar a la pantalla principal después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      });
    }
  }

  // Método para mostrar una notificación tipo "toast" cuando no hay conexión
  void _showNoInternetToast() {
    Fluttertoast.showToast(
      msg: "No hay conexión a Internet. Intenta de nuevo.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    // Opcional: Mostrar un botón para reintentar la validación
    Future.delayed(Duration(seconds: 2), () {
      _showRetryDialog();
    });
  }

  // Método para mostrar un diálogo de reintento
  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sin conexión a Internet"),
          content: Text("Por favor, verifica tu conexión y vuelve a intentarlo."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el diálogo
                _checkInternetConnection(); // Reintentar la validación
              },
              child: Text("Reintentar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro para resaltar el amarillo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono de maquinaria con animación
            Icon(
              Icons.construction, // Ícono de construcción/maquinaria
              size: 100,
              color: Colors.yellow.shade600,
            ).animate()
                .scale(duration: 800.ms, begin: Offset(0.8, 0.8), end: Offset(1, 1), curve: Curves.easeOut)
                .fadeIn(duration: 500.ms)
                .then(delay: 300.ms)
                .shake(duration: 500.ms, hz: 4) // Efecto de vibración
                .then(delay: 500.ms),

            SizedBox(height: 20), // Espacio entre el ícono y el texto

            // Texto de bienvenida con animación
            Column(
              children: [
                Text(
                  "Bienvenido a",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.yellow.shade600,
                    fontWeight: FontWeight.w300,
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.5, end: 0, duration: 500.ms)
                    .then(delay: 300.ms),

                SizedBox(height: 10), // Espacio entre los textos

                Text(
                  "Rentek",
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.yellow.shade600,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1), duration: 800.ms, curve: Curves.easeOut)
                    .then(delay: 300.ms)
                    .shimmer(duration: 1000.ms, color: Colors.yellow.withOpacity(0.5)) // Efecto de brillo
                    .then(delay: 500.ms),
              ],
            ),

            SizedBox(height: 40), // Espacio entre el texto y el indicador de carga

            // Indicador de carga con animación
            CircularProgressIndicator(
              color: Colors.yellow.shade600,
              strokeWidth: 2,
            ).animate()
                .fadeIn(duration: 500.ms)
                .then(delay: 300.ms)
                .rotate(duration: 1.seconds, curve: Curves.linear)
                .then()
                .scale(duration: 500.ms, begin: Offset(1, 1), end: Offset(1.2, 1.2), curve: Curves.easeInOut)
                .then()
                .scale(duration: 500.ms, begin: Offset(1.2, 1.2), end: Offset(1, 1), curve: Curves.easeInOut),
          ],
        ),
      ),
    );
  }
}