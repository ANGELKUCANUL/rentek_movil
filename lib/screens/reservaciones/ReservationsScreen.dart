import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../service/url.dart';

class ReservationsScreen extends StatefulWidget {
  @override
  _ReservationsScreenState createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<dynamic> _reservations = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');

    if (_userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse('${GlobalData.url}/reservations/user/$_userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _reservations = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error al obtener reservas: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mis Reservas")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _userId == null
              ? _buildNotLoggedInMessage()
              : _reservations.isEmpty
                  ? _buildNoReservationsMessage()
                  : _buildReservationsList(),
    );
  }

  /// 🟡 Mensaje si el usuario no ha iniciado sesión
  Widget _buildNotLoggedInMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning, color: Colors.red, size: 50),
          SizedBox(height: 10),
          Text("Debes iniciar sesión primero",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Navegar a pantalla de inicio de sesión
              Navigator.pushNamed(context, '/login');
            },
            child: Text("Iniciar Sesión"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[800],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 🟡 Mensaje si no hay reservas
  Widget _buildNoReservationsMessage() {
    return Center(
      child: Text("No tienes reservas aún",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  /// 🟡 Lista de reservas con diseño mejorado
  Widget _buildReservationsList() {
    return ListView.builder(
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];

        return Card(
          margin: EdgeInsets.all(10),
          elevation: 5,
          child: Padding(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reserva ID: ${reservation['id']}",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  "Inicio: ${_formatDate(reservation['rental_start'])}",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  "Fin: ${_formatDate(reservation['rental_end'])}",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  "Dirección de entrega: ${reservation['address_entrega'] ?? 'No disponible'}",
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  "Precio: \$${reservation['price']}",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Pago: ${reservation['payment_status']}",
                      style: TextStyle(
                          fontSize: 14,
                          color: reservation['payment_status'] == "pendiente"
                              ? Colors.red
                              : Colors.green),
                    ),
                    Text(
                      "Entrega: ${reservation['delivery_status']}",
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🟡 Función para formatear la fecha
  String _formatDate(String? date) {
    if (date == null) return "No disponible";
    DateTime parsedDate = DateTime.parse(date);
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }
}
