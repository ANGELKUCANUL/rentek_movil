import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rentek/service/url.dart'; // Para usar GlobalData.url
import 'package:rentek/main.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  final Map<String, dynamic> reservationData;

  PaymentScreen({required this.totalPrice, required this.reservationData});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _statusMessage = "Esperando confirmación del pago...";

  Future<void> createPreferenceAndPay() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${GlobalData.url}/api/pagos/crear-preferencia"), // Ajusta la URL según tu backend
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"precio": widget.totalPrice}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String initPoint = responseData["init_point"];

        if (initPoint.isNotEmpty) {
          print("Redirigiendo a: $initPoint");

          if (await canLaunchUrl(Uri.parse(initPoint))) {
            await launchUrl(Uri.parse(initPoint), mode: LaunchMode.externalApplication);
            // Después de lanzar la URL, verificamos el estado del pago
            _checkPaymentStatus();
          } else {
            setState(() {
              _statusMessage = "No se pudo abrir el enlace de pago";
            });
          }
        }
      } else {
        setState(() {
          _statusMessage = "Error al generar el pago: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error de conexión: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPaymentStatus() async {
    // Simulamos una verificación con el backend (ajusta según tu API)
    try {
      final response = await http.post(
        Uri.parse("${GlobalData.url}/reservations"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(widget.reservationData),
      );

      if (response.statusCode == 201) {
        final reservationResponse = jsonDecode(response.body);
        String reservationId = reservationResponse["id"]; // Asegúrate de que tu backend devuelva el ID

        // Actualizamos el estado del pago a "pagado"
        await _updateReservationStatus(reservationId, "pagado");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pago exitoso y reserva confirmada")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El pago no fue confirmado")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al verificar el pago: $e")),
      );
    }
  }

  Future<void> _updateReservationStatus(String reservationId, String status) async {
    try {
      await http.put(
        Uri.parse("${GlobalData.url}/reservations/$reservationId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"payment_status": status}),
      );
    } catch (e) {
      print("Error al actualizar estado: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    createPreferenceAndPay(); // Inicia el proceso de pago automáticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pago con MercadoPago")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(_statusMessage, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}