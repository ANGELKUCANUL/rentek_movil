import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Para TextInputFormatter
import 'package:intl/intl.dart'; // Para trabajar con fechas
import '../../../service/url.dart';


// Clase auxiliar para el formato de la fecha de expiración
class ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll('/', '');
    
    if (newText.isEmpty) {
      return newValue;
    }
    
    if (newText.length > 4) {
      return oldValue;
    }
    
    if (newText.length > 2) {
      return TextEditingValue(
        text: '${newText.substring(0, 2)}/${newText.substring(2)}',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    }
    
    return newValue;
  }
}

class PaymentMethodScreen extends StatefulWidget {
  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  List<dynamic> paymentMethods = [];
  String? userId;

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

  Future<void> _addPaymentMethod(Map<String, String> newPaymentMethod) async {
    final response = await http.post(
      Uri.parse('${GlobalData.url}/payment-methods'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(newPaymentMethod),
    );

    if (response.statusCode == 201) {
      _fetchPaymentMethods();
    } else {
      print('Error al agregar método de pago');
    }
  }

  Future<void> _deletePaymentMethod(String id) async {
    final response = await http.delete(
      Uri.parse('${GlobalData.url}/payment-methods/$id'),
    );
    if (response.statusCode == 200) {
      setState(() {
        paymentMethods.removeWhere((method) => method['id'] == id);
      });
    } else {
      print('Error al eliminar método de pago');
    }
  }

  void _showAddPaymentDialog() {
    final _formKey = GlobalKey<FormState>();
    TextEditingController cardHolderController = TextEditingController();
    TextEditingController cardNumberController = TextEditingController();
    TextEditingController expirationDateController = TextEditingController();
    TextEditingController cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Método de Pago'),
        content: SingleChildScrollView( // Agregamos SingleChildScrollView aquí
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cardHolderController,
                  decoration: InputDecoration(labelText: 'Nombre del Titular'),
                  validator: (value) =>
                      value!.isEmpty ? 'Ingrese el nombre del titular' : null,
                ),
                TextFormField(
                  controller: cardNumberController,
                  decoration: InputDecoration(labelText: 'Número de Tarjeta'),
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  validator: (value) {
                    if (value!.isEmpty) return 'Ingrese un número de tarjeta';
                    if (!RegExp(r'^\d{16}$').hasMatch(value)) {
                      return 'Debe contener exactamente 16 dígitos';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: expirationDateController,
                  decoration: InputDecoration(labelText: 'Fecha de Expiración (MM/AA)'),
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ExpirationDateFormatter(),
                  ],
                  validator: (value) {
                    if (value!.isEmpty) return 'Ingrese una fecha válida';
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'Formato incorrecto (MM/AA)';
                    }
                    return _validateExpirationDate(value);
                  },
                ),
                TextFormField(
                  controller: cvvController,
                  decoration: InputDecoration(labelText: 'CVV'),
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  validator: (value) {
                    if (value!.isEmpty) return 'Ingrese el CVV';
                    if (!RegExp(r'^\d{3}$').hasMatch(value)) {
                      return 'Debe tener 3 dígitos';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                _addPaymentMethod({
                  'card_holder': cardHolderController.text,
                  'card_number': cardNumberController.text,
                  'expiration_date': expirationDateController.text,
                  'cvv': cvvController.text,
                  'userId': userId ?? '',
                });
              }
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String? _validateExpirationDate(String value) {
    try {
      final now = DateTime.now();
      final currentYear = int.parse(DateFormat('yy').format(now));
      final currentMonth = int.parse(DateFormat('MM').format(now));

      final parts = value.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);

      if (month < 1 || month > 12) {
        return 'Mes inválido (01-12)';
      }
      if (year < currentYear || (year == currentYear && month < currentMonth)) {
        return 'La tarjeta ha expirado';
      }
      return null;
    } catch (e) {
      return 'Formato incorrecto (MM/AA)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Métodos de Pago')),
      body: paymentMethods.isEmpty
          ? Center(child: Text('No tienes métodos de pago guardados.'))
          : ListView.builder(
              itemCount: paymentMethods.length,
              itemBuilder: (context, index) {
                return _buildCard(paymentMethods[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPaymentDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> paymentMethod) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, Colors.black87],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: const Color.fromARGB(66, 61, 34, 156),
              blurRadius: 8,
              offset: Offset(0, 4))
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Expira: ${paymentMethod['expiration_date']}',
                  style: TextStyle(color: Colors.white70)),
              IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deletePaymentMethod(paymentMethod['id'])),
            ],
          ),
        ],
      ),
    );
  }
}

