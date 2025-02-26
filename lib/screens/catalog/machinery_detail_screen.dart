import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../perfil/Login.dart';

class MachineryDetailScreen extends StatefulWidget {
  final dynamic machinery;
  final dynamic provider;

  MachineryDetailScreen({required this.machinery, required this.provider});

  @override
  _MachineryDetailScreenState createState() => _MachineryDetailScreenState();
}

class _MachineryDetailScreenState extends State<MachineryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  String? userId;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('userId');
    print("User ID cargado: $storedUserId");

    if (storedUserId != null) {
      setState(() {
        userId = storedUserId;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.amber,
            colorScheme: ColorScheme.light(primary: Colors.amber),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0];
        _calculateTotal();
      });
    }
  }

  void _calculateTotal() {
    int days = int.tryParse(_daysController.text) ?? 0;
    double pricePerDay = widget.machinery['rental_price']?.toDouble() ?? 0.0;
    setState(() {
      totalPrice = days * pricePerDay;
    });
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (userId == null || widget.machinery == null || widget.machinery['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: Datos incompletos. Intenta de nuevo.")));
      return;
    }

    int days = int.tryParse(_daysController.text) ?? 0;
    DateTime startDate = DateTime.parse(_startDateController.text);
    DateTime endDate = startDate.add(Duration(days: days));

    setState(() {
      _isLoading = true;
    });

    final reservationData = {
      "rental_start": _startDateController.text,
      "rental_end": endDate.toIso8601String().split('T')[0],
      "address_entrega": _addressController.text,
      "userId": userId,
      "machineryId": widget.machinery['id'],
      "price": totalPrice,
      "payment_status": "pendiente",
      "delivery_status": "pendiente",
    };

    try {
      final response = await http.post(
        Uri.parse("https://rentek.onrender.com/reservations"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reservationData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reserva creada exitosamente"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al crear la reserva: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.machinery['name'], style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[700],
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.machinery['image_code'] != null
                ? Image.network(
                    widget.machinery['image_code'],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(height: 250, color: Colors.grey),
            SizedBox(height: 16),
            Text(widget.machinery['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
            SizedBox(height: 8),
            Text('Ubicación: ${widget.machinery['location']}', style: TextStyle(color: Colors.grey[700])),
            Text('Precio por día: \$${widget.machinery['rental_price']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            SizedBox(height: 16),
            Divider(),
            Text('Reservar Maquinaria', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: "Fecha de inicio",
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.amber[800]),
                        onPressed: () => _selectDate(context, _startDateController),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Ingrese la fecha de inicio' : null,
                    readOnly: true,
                  ),
                  TextFormField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Cantidad de días"),
                    validator: (value) => value!.isEmpty ? 'Ingrese los días de renta' : null,
                    onChanged: (value) => _calculateTotal(),
                  ),
                  SizedBox(height: 16),
                  Text("Costo total: \$${totalPrice.toStringAsFixed(2)}", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: "Dirección de entrega"),
                    validator: (value) => value!.isEmpty ? 'Ingrese la dirección de entrega' : null,
                  ),
                  SizedBox(height: 16),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _submitReservation,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                          child: Text('Reservar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
