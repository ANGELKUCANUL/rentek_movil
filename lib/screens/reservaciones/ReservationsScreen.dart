import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../service/url.dart';
import '../perfil/Login.dart';
import '../../main.dart';

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

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mis Reservas",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50], // Fondo sutil
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: Colors.blueGrey[700]),
                )
                : _userId == null
                ? _buildNotLoggedInMessage()
                : _reservations.isEmpty
                ? _buildNoReservationsMessage()
                : _buildReservationsList(),
      ),
    );
  }

  /// 🟡 Mensaje si el usuario no ha iniciado sesión
  Widget _buildNotLoggedInMessage() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange[700], size: 60),
            SizedBox(height: 20),
            Text(
              "Debes iniciar sesión primero",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: _navigateToLogin,

            
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: Text(
                "Iniciar Sesión",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🟡 Mensaje si no hay reservas
  Widget _buildNoReservationsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: Colors.grey[600], size: 50),
          SizedBox(height: 20),
          Text(
            "No tienes reservas aún",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "¡Explora el catálogo y haz tu primera reserva!",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 🟡 Lista de reservas con diseño mejorado
  Widget _buildReservationsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];

        return Card(
          margin: EdgeInsets.only(bottom: 8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reserva", // Eliminado "ID: ${reservation['id']}"
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 12),
                _buildInfoRow(
                  Icons.calendar_today,
                  "Inicio: ${_formatDate(reservation['rental_start'])}",
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  "Fin: ${_formatDate(reservation['rental_end'])}",
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on,
                  "Dirección: ${reservation['address_entrega'] ?? 'No disponible'}",
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  Icons.attach_money,
                  "Precio: \$${reservation['price']}",
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(
                      "Pago: ${reservation['payment_status']}",
                      reservation['payment_status'] == "pendiente"
                          ? Colors.red[600]!
                          : Colors.green[600]!,
                    ),
                    _buildStatusChip(
                      "Entrega: ${reservation['delivery_status']}",
                      Colors.blue[600]!,
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

  /// 🟡 Widget auxiliar para filas de información
  Widget _buildInfoRow(IconData icon, String text, {TextStyle? textStyle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey[600]),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style:
                textStyle ?? TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  /// 🟡 Widget auxiliar para chips de estado
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
