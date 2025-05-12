import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentek/screens/perfil/metodo_pago/payment.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../perfil/Login.dart';
import 'package:rentek/service/url.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rentek/screens/perfil/metodo_pago/PaymentMethod.dart';

class MachineryDetailScreen extends StatefulWidget {
  final dynamic machinery;
  final dynamic provider;

  const MachineryDetailScreen({required this.machinery, required this.provider, super.key});

  @override
  _MachineryDetailScreenState createState() => _MachineryDetailScreenState();
}

class _MachineryDetailScreenState extends State<MachineryDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isLoading = false;
  String? userId;
  double totalPrice = 0.0;
  static const String defaultAddress = "Calle 123, Colonia 456, Ciudad 789";

  @override
  void initState() {
    super.initState();
    print("Machinery: ${widget.machinery}");
    print("Provider: ${widget.provider}");
    _initializeNotifications();
    _loadUserId();
    _requestPermissions();
    _addressController.text = defaultAddress; // Establece la dirección predeterminada
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
    final int days = int.tryParse(_daysController.text) ?? 0;
    final double pricePerDay = (widget.machinery['rental_price'] as num?)?.toDouble() ?? 0.0;
    setState(() {
      totalPrice = days * pricePerDay;
    });
  }

  Future<void> _requestPermissions() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print("Android Info: ${androidInfo.toMap()}");
      if (androidInfo.version.sdkInt != null && androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          print("Permiso de notificación concedido.");
        } else if (status.isDenied) {
          print("⚠️ Permisos de notificación denegados.");
        } else if (status.isPermanentlyDenied) {
          print("⚠️ El usuario ha denegado permanentemente los permisos.");
          await openAppSettings();
        }
      } else {
        print("Versión del SDK no disponible o menor a 33: ${androidInfo.version.sdkInt}");
      }
    } catch (e) {
      print("Error al obtener información del dispositivo: $e");
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime minDate = now.add(const Duration(days: 2));
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
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
    final DateTime startDate = DateTime.parse(_startDateController.text);
    final int days = int.parse(_daysController.text);
    final DateTime endDate = startDate.add(Duration(days: days));
    final reservationData = {
      "rental_start": _startDateController.text,
      "rental_end": endDate.toString().split(' ')[0],
      "address_entrega": _addressController.text,
      "userId": userId ?? "",
      "machineryId": widget.machinery['id']?.toString() ?? "",
      "price": totalPrice,
      "payment_status": "pendiente",
      "delivery_status": "pendiente",
    };
    setState(() => _isLoading = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalPrice: totalPrice,
          reservationData: reservationData,
        ),
      ),
    );
    setState(() => _isLoading = false);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'reservation_channel',
      'Reservas',
      channelDescription: 'Notificación de reserva confirmada',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blueGrey)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.machinery['name']?.toString() ?? 'Maquinaria sin nombre',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.machinery['image_code'] != null
                  ? Image.network(
                      widget.machinery['image_code'] as String,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    )
                  : Container(
                      height: 250,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.machinery['name']?.toString() ?? 'Maquinaria sin nombre',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.branding_watermark, "Marca", widget.machinery['brand']?.toString() ?? 'No disponible'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on, "Ubicación", widget.machinery['location']?.toString() ?? 'No disponible'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.attach_money, "Precio por día",
                "\$${widget.machinery['rental_price']?.toString() ?? 'No disponible'}", Colors.green[700]),
            const SizedBox(height: 6),
            Text(
              "Descripción: ${widget.machinery['description']?.toString() ?? 'No disponible'}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey, thickness: 1),
            const SizedBox(height: 20),
            const Text(
              "Información del Proveedor",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, "Proveedor", widget.provider?['name']?.toString() ?? 'No disponible'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.email, "Correo", widget.provider?['email']?.toString() ?? 'No disponible'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.phone, "Teléfono", widget.provider?['phoneNumber']?.toString() ?? 'No disponible'),
            const SizedBox(height: 6),
            _buildInfoRow(Icons.star, "Calificación", widget.provider?['rating']?.toString() ?? 'No disponible'),
            const SizedBox(height: 24),
            const Divider(color: Colors.grey, thickness: 1),
            const SizedBox(height: 24),
            const Text(
              "Reservar Maquinaria",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextFormField(
                    controller: _startDateController,
                    labelText: "Fecha de inicio",
                    icon: Icons.calendar_today,
                    onTap: _selectStartDate,
                    validator: (value) => value == null || value.isEmpty ? 'Seleccione una fecha de inicio' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _daysController,
                    labelText: "Cantidad de días",
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotalPrice(),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingrese la cantidad de días';
                      if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Ingrese un número válido de días';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _addressController,
                    labelText: "Dirección de entrega",
                    icon: Icons.location_on,
                    validator: (value) => value == null || value.isEmpty ? 'Ingrese la dirección de entrega' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total a pagar:", style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text(
                        "\$${totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _navigateToPaymentScreen,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Reservar y Pagar', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          "$label: $value",
          style: TextStyle(fontSize: 16, color: valueColor ?? Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    void Function()? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[100],
        suffixIcon: icon != null ? Icon(icon, color: Colors.blueGrey[600]) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      readOnly: onTap != null,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onTap: onTap,
      validator: validator,
    );
  }
}