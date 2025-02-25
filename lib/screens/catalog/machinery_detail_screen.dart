import 'package:flutter/material.dart';

class MachineryDetailScreen extends StatelessWidget {
  final dynamic machinery;
  final dynamic provider;

  MachineryDetailScreen({required this.machinery, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(machinery['name']),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la maquinaria
            machinery['image_code'] != null
                ? Image.network(machinery['image_code'], height: 250, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 250, color: Colors.grey), // Placeholder

            SizedBox(height: 16),

            // Información de la maquinaria
            Text('Nombre: ${machinery['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Marca: ${machinery['brand'] ?? "No disponible"}'),
            Text('Ubicación: ${machinery['location']}'),
            Text('Precio: \$${machinery['rental_price']}'),
            Text('Descripción: ${machinery['description'] ?? "No disponible"}'),

            SizedBox(height: 16),

            // Información del proveedor
            Text('Proveedor: ${provider['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Correo: ${provider['email']}'),
            Text('Teléfono: ${provider['phoneNumber']}'),
            Text('Calificación: ${provider['rating'] ?? "No disponible"}'),
          ],
        ),
      ),
    );
  }
}
