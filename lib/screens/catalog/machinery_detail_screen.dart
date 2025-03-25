import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:rentek/screens/perfil/metodo_pago/payment.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../perfil/Login.dart';
import 'package:rentek/service/url.dart';
import 'location_picker_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rentek/screens/perfil/metodo_pago/PaymentMethod.dart'; // Importamos la nueva pantalla de pago

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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = false;
  String? userId;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserId();
    _requestPermissions();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🛎 Notificación tocada: ${response.payload}");
      },
    );
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

  Future<void> _requestPermissions() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print("Permiso de notificación concedido.");
      } else if (status.isDenied) {
        print("⚠️ Permisos de notificación denegados.");
      } else if (status.isPermanentlyDenied) {
        print("⚠️ El usuario ha denegado permanentemente los permisos.");
        openAppSettings();
      }
    }
  }

  Future<void> _selectStartDate() async {
    DateTime now = DateTime.now();
    DateTime minDate = now.add(Duration(days: 2));

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _startDateController.text = fullDateTime.toString();
        });
      }
    }
  }

  Future<void> _navigateToPaymentScreen() async {
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

    setState(() {
      _isLoading = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalPrice: totalPrice,
          reservationData: reservationData,
        ),
      ),
    ).then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reservation_channel',
      'Reservas',
      channelDescription: 'Notificación de reserva confirmada',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Reserva Confirmada',
      'Tu reserva ha sido creada con éxito.',
      platformChannelSpecifics,
    );
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
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800]),
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
            Text(
                "Calificación: ${widget.provider['rating'] ?? "No disponible"}"),
            SizedBox(height: 24),
            Text(
              "Reservar Maquinaria",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow[800]),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _startDateController,
                    decoration: InputDecoration(
                      labelText: "Fecha de inicio",
                      suffixIcon:
                          Icon(Icons.calendar_today, color: Colors.yellow[800]),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: _selectStartDate,
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
                      suffixIcon:
                          Icon(Icons.location_on, color: Colors.yellow[800]),
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
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
                    onPressed: _navigateToPaymentScreen,
                    child: Text('Reservar y Pagar', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 16),
                  if (_isLoading) CircularProgressIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}