import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../perfil/Login.dart';
import 'package:rentek/service/url.dart';
import 'location_picker_screen.dart';

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

  void _calculateTotalPrice() {
    int days = int.tryParse(_daysController.text) ?? 0;
    double pricePerDay = widget.machinery['rental_price']?.toDouble() ?? 0.0;
    setState(() {
      totalPrice = days * pricePerDay;
    });
  }

  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _startDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    DateTime startDate = DateTime.parse(_startDateController.text);
    int days = int.parse(_daysController.text);
    DateTime endDate = startDate.add(Duration(days: days));

    final reservationData = {
      "rental_start": _startDateController.text,
      "rental_end": endDate.toString().split(' ')[0],
      "address_entrega": _addressController.text,
      "userId": userId ?? "",
      "machineryId": widget.machinery['id'],
      "price": totalPrice,
      "payment_status": "pendiente",
      "delivery_status": "pendiente",
    };

    try {
      final response = await http.post(
      Uri.parse('${GlobalData.url}/reservations'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reservationData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reserva creada exitosamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al crear la reserva")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
        title: Text(widget.machinery['name']),
        backgroundColor: Colors.yellow[700],
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
            Text(
              widget.machinery['name'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Marca: ${widget.machinery['brand'] ?? "No disponible"}",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Ubicación: ${widget.machinery['location']}",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Precio por día: \$${widget.machinery['rental_price']}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800]),
            ),
            Text(
              "Descripción: ${widget.machinery['description'] ?? "No disponible"}",
              style: TextStyle(fontSize: 16),
            ),
            Divider(thickness: 2),
            Text(
              "Proveedor: ${widget.provider['name']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text("Correo: ${widget.provider['email']}"),
            Text("Teléfono: ${widget.provider['phoneNumber']}"),
            Text("Calificación: ${widget.provider['rating'] ?? "No disponible"}"),
            SizedBox(height: 24),
            Text(
              "Reservar Maquinaria",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.yellow[800]),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: "Fecha de inicio",
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: Colors.yellow[800]),
                        onPressed: _selectStartDate,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seleccione una fecha de inicio';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _daysController,
                    decoration: InputDecoration(
                      labelText: "Cantidad de días",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotalPrice(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese la cantidad de días';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: "Dirección de entrega",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.location_on, color: Colors.yellow[800]),
                  ),
                  readOnly: true,
                  onTap: () async {
                    LatLng? selectedLocation;
                    String? selectedAddress;

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPickerScreen(
                          onLocationSelected: (LatLng location, String address) {
                            selectedLocation = location;
                            selectedAddress = address;
                          },
                        ),
                      ),
                    );

                    if (selectedAddress != null && selectedLocation != null) {
                      setState(() {
                        _addressController.text = selectedAddress!;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese la dirección de entrega';
                    }
                    return null;
                  },
                ),

                  SizedBox(height: 16),
                  Text(
                    "Total a pagar: \$${totalPrice.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                  ),
                  SizedBox(height: 16),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow[700]),
                          onPressed: _submitReservation,
                          child: Text('Reservar', style: TextStyle(color: Colors.black)),
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


