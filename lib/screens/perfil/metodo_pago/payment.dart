import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/url.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  final Map<String, dynamic> reservationData;

  PaymentScreen({required this.totalPrice, required this.reservationData});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<dynamic> paymentMethods = [];
  String? userId;
  dynamic selectedPaymentMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('userId');
    });
    if (userId != null) {
      _fetchPaymentMethods();
    }
  }

  Future<void> _fetchPaymentMethods() async {
    final response = await http.get(
      Uri.parse('${GlobalData.url}/payment-methods/user/$userId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        paymentMethods = json.decode(response.body);
      });
    } else {
      print('Error al obtener métodos de pago');
    }
  }

  Future<void> _processPayment() async {
    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona un método de pago')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Actualizar el reservationData con el estado de pago y el método de pago seleccionado
    final paymentData = {
      ...widget.reservationData,
      "payment_status": "completado",
      "payment_method_id": selectedPaymentMethod['id'],
    };

    try {
      // Primero, crear la reserva con el pago completado
      final reservationResponse = await http.post(
        Uri.parse('${GlobalData.url}/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(paymentData),
      );

      if (reservationResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago y reserva realizados con éxito')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Scaffold(body: Center(child: Text('MainScreen')))), // Reemplaza con tu MainScreen real
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el pago y la reserva')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> paymentMethod) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPaymentMethod = paymentMethod;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              selectedPaymentMethod == paymentMethod ? Colors.green.shade700 : Colors.blueGrey.shade900,
              Colors.black87
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(66, 61, 34, 156),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paymentMethod['card_holder'],
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              '**** **** **** ${paymentMethod['card_number'].substring(paymentMethod['card_number'].length - 4)}',
              style: TextStyle(fontSize: 20, letterSpacing: 2, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              'Expira: ${paymentMethod['expiration_date']}',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Realizar Pago'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalles de la Reserva',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Total a pagar: \$${widget.totalPrice.toStringAsFixed(2)}'),
            Text('Fecha de inicio: ${widget.reservationData["rental_start"]}'),
            Text('Fecha de fin: ${widget.reservationData["rental_end"]}'),
            Text('Dirección: ${widget.reservationData["address_entrega"]}'),
            SizedBox(height: 24),
            Text(
              'Selecciona un Método de Pago',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            paymentMethods.isEmpty
                ? Center(child: Text('No tienes métodos de pago guardados.'))
                : ListView.builder(
                    shrinkWrap: true, // Para que funcione dentro de SingleChildScrollView
                    physics: NeverScrollableScrollPhysics(), // Desactiva el scroll interno
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentMethodCard(paymentMethods[index]);
                    },
                  ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      minimumSize: Size(double.infinity, 50), // Botón de ancho completo
                    ),
                    onPressed: _processPayment,
                    child: Text('Confirmar Pago', style: TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}

