import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'machinery_detail_screen.dart';
import '../../service/url.dart';

class MachineryListScreen extends StatefulWidget {
  @override
  _MachineryListScreenState createState() => _MachineryListScreenState();
}



  @override
  void initState() {
    super.initState();
    fetchMachinery();
    checkUserSession();
  }

  Future<void> checkUserSession() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedUsername = prefs.getString('username');
  String? storedUserId = prefs.getString('userId'); // Obtener userId

  setState(() {
    username = storedUsername;
    userId = storedUserId; // Guardar userId correctamente
  });
}



  Future<void> fetchMachinery() async {
    final response = await http.get(
      Uri.parse('${GlobalData.url}/machinery/with-provider'),
    );

    if (response.statusCode == 200) {
      setState(() {
        machineryList = json.decode(response.body);
        filteredMachineryList = machineryList;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Error al obtener las maquinarias');
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.yellow[800]),
              SizedBox(width: 10),
              Text('Iniciar Sesión'),
            ],
          ),
          content: Text('Debes iniciar sesión para ver los detalles de la maquinaria.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

    void _filterMachinery() {
    setState(() {
      filteredMachineryList = machineryList.where((machine) {
        final nameMatch = machine['name'].toLowerCase().contains(searchQuery.toLowerCase());
        final brandMatch = selectedBrand == null || machine['brand'] == selectedBrand;
        final locationMatch = selectedLocation == null || machine['location'] == selectedLocation;
        final priceMatch = (minPrice == null || machine['rental_price'] >= minPrice!) &&
            (maxPrice == null || machine['rental_price'] <= maxPrice!);
        return nameMatch && brandMatch && locationMatch && priceMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      selectedBrand = null;
      selectedLocation = null;
      minPrice = null;
      maxPrice = null;
      searchQuery = '';
      filteredMachineryList = List.from(machineryList);
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? tempBrand = selectedBrand;
        String? tempLocation = selectedLocation;
        double? tempMinPrice = minPrice;
        double? tempMaxPrice = maxPrice;

        return AlertDialog(
          backgroundColor: Colors.yellow[700],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Filtrar Maquinaria', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Marca', filled: true, fillColor: Colors.white),
                value: tempBrand,
                items: ['Caterpillar', 'Komatsu', 'Volvo']
                    .map((brand) => DropdownMenuItem(value: brand, child: Text(brand)))
                    .toList(),
                onChanged: (value) {
                  tempBrand = value;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Ubicación', filled: true, fillColor: Colors.white),
                value: tempLocation,
                items: ['CDMX', 'Guadalajara', 'Monterrey']
                    .map((location) => DropdownMenuItem(value: location, child: Text(location)))
                    .toList(),
                onChanged: (value) {
                  tempLocation = value;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Precio mínimo', filled: true, fillColor: Colors.white),
                keyboardType: TextInputType.number,
                onChanged: (value) => tempMinPrice = double.tryParse(value),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Precio máximo', filled: true, fillColor: Colors.white),
                keyboardType: TextInputType.number,
                onChanged: (value) => tempMaxPrice = double.tryParse(value),
              ),
            ],
          ),
          actions: [
           TextButton(
              onPressed: () {
                _resetFilters();
                Navigator.of(context).pop(); // Cierra el diálogo después de borrar filtros
              },
              child: Text('Borrar Filtros', style: TextStyle(color: Colors.white)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                setState(() {
                  selectedBrand = tempBrand;
                  selectedLocation = tempLocation;
                  minPrice = tempMinPrice;
                  maxPrice = tempMaxPrice;
                  _filterMachinery();
                });
                Navigator.of(context).pop();
              },
              child: Text('Aplicar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo de Maquinaria'),
        backgroundColor: Colors.yellow[800],
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar maquinaria...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        _filterMachinery();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredMachineryList.isEmpty
                      ? Center(
                          child: Text(
                            "No se encontraron maquinarias",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredMachineryList.length,
                          itemBuilder: (context, index) {
                            final machinery = filteredMachineryList[index];
                            final provider = machinery['Provider'];

                            return GestureDetector(
                              onTap: () {
                                  if (username == null) {
                                  _showLoginRequiredDialog();
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MachineryDetailScreen(
                                        machinery: machinery,
                                        provider: provider,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      machinery['image_code'] != null
                                          ? Image.network(
                                              machinery['image_code'],
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 100,
                                              width: 100,
                                              color: Colors.grey,
                                            ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              machinery['name'],
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Descripción: ${machinery['description']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: Colors.black54),
                                            ),
                                            Text(
                                              'Ubicación: ${machinery['location']}',
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                            Text(
                                              'Precio: \$${machinery['rental_price']}',
                                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'Proveedor: ${provider['name']}',
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

        ],
      ),
    );
  }
}

