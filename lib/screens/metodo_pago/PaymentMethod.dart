import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/url.dart';

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
    print(userId);
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
      builder:
          (context) => AlertDialog(
            title: Text('Agregar Método de Pago'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cardHolderController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Titular',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty
                                ? 'Ingrese el nombre del titular'
                                : null,
                  ),
                  TextFormField(
                    controller: cardNumberController,
                    decoration: InputDecoration(labelText: 'Número de Tarjeta'),
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    validator:
                        (value) =>
                            value!.length != 16
                                ? 'Debe tener 16 dígitos'
                                : null,
                  ),
                  TextFormField(
                    controller: expirationDateController,
                    decoration: InputDecoration(
                      labelText: 'Fecha de Expiración (MM/AA)',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Ingrese una fecha válida' : null,
                  ),
                  TextFormField(
                    controller: cvvController,
                    decoration: InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    validator:
                        (value) =>
                            value!.length != 3 ? 'Debe tener 3 dígitos' : null,
                  ),
                ],
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

  Widget _buildCard(Map<String, dynamic> paymentMethod) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paymentMethod['card_holder'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '**** **** **** ${paymentMethod['card_number'].substring(paymentMethod['card_number'].length - 4)}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expira: ${paymentMethod['expiration_date']}'),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePaymentMethod(paymentMethod['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Métodos de Pago')),
      body:
          paymentMethods.isEmpty
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
}
