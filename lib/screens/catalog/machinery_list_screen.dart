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

class _MachineryListScreenState extends State<MachineryListScreen> {
  List<dynamic> machineryList = [];
  List<dynamic> filteredMachineryList = [];
  bool isLoading = true;
  String? username;
  String searchQuery = '';
  String? selectedBrand;
  String? selectedLocation;
  double? minPrice;
  double? maxPrice;
  String? userId;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchMachinery();
    checkUserSession();
  }

  Future<void> checkUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUsername = prefs.getString('username');
    String? storedUserId = prefs.getString('userId');

    setState(() {
      username = storedUsername;
      userId = storedUserId;
    });
  }

  Future<void> fetchMachinery() async {
    try {
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
        throw Exception('Error al obtener las maquinarias: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las maquinarias: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange[700], size: 28),
              SizedBox(width: 10),
              Text('Iniciar Sesión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
            ],
          ),
          content: Text(
            'Debes iniciar sesión para ver los detalles de la maquinaria.',
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey[700]),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Iniciar Sesión', style: TextStyle(fontSize: 16, color: Colors.white)),
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
        final brandMatch = selectedBrand == null || selectedBrand!.isEmpty ||
            machine['brand'].toLowerCase().contains(selectedBrand!.toLowerCase());
        final locationMatch = selectedLocation == null || selectedLocation!.isEmpty ||
            machine['location'].toLowerCase().contains(selectedLocation!.toLowerCase());
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
      _brandController.clear();
      _locationController.clear();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blueGrey[700], size: 24),
              SizedBox(width: 10),
              Text('Filtrar Maquinaria', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    hintText: 'Ej: Caterpillar',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.branding_watermark, color: Colors.blueGrey[600]),
                  ),
                  onChanged: (value) => tempBrand = value,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Ubicación',
                    hintText: 'Ej: CDMX',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.location_on, color: Colors.blueGrey[600]),
                  ),
                  onChanged: (value) => tempLocation = value,
                ),
                SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Precio mínimo',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: Colors.blueGrey[600]),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => tempMinPrice = double.tryParse(value),
                ),
                SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Precio máximo',
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.attach_money, color: Colors.blueGrey[600]),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => tempMaxPrice = double.tryParse(value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () {
                _resetFilters();
                Navigator.of(context).pop();
              },
              child: Text('Borrar Filtros', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
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
              child: Text('Aplicar', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Catálogo de Maquinaria',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.blueGrey[700]))
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar maquinaria...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.construction, size: 60, color: Colors.grey[400]),
                              SizedBox(height: 10),
                              Text(
                                "No se encontraron maquinarias",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Intenta ajustar tus filtros",
                                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredMachineryList.length,
                          itemBuilder: (context, index) {
                            final machinery = filteredMachineryList[index];

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
                                        provider: machinery['provider'], // Cambiado de 'Provider' a 'provider'
                                      ),
                                    ),
                                  ).then((_) {
                                    checkUserSession();
                                  });
                                }
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                margin: EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Imagen destacada
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                      child: Stack(
                                        children: [
                                          machinery['image_code'] != null
                                              ? Image.network(
                                                  machinery['image_code'],
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Image.network(
                                                      'https://th.bing.com/th/id/OIP.lWp9hgkXFNkI3XAY-v-K9gHaHa?rs=1&pid=ImgDetMain',
                                                      height: 180,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                              : Image.network(
                                                  'https://th.bing.com/th/id/OIP.lWp9hgkXFNkI3XAY-v-K9gHaHa?rs=1&pid=ImgDetMain',
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                          // Sombra en la parte inferior para transición suave
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.5),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Contenido de la tarjeta
                                    Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Nombre y precio en la misma fila
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  machinery['name'] ?? 'Sin nombre',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueGrey[900],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                '\$${machinery['rental_price']?.toString() ?? 'N/A'}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          // Descripción
                                          Text(
                                            machinery['description'] ?? 'Sin descripción',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          // Marca
                                          Row(
                                            children: [
                                              Icon(Icons.branding_watermark, size: 16, color: Colors.blueGrey[500]),
                                              SizedBox(width: 6),
                                              Text(
                                                machinery['brand'] ?? 'Sin marca',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.blueGrey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          // Ubicación
                                          Row(
                                            children: [
                                              Icon(Icons.location_on, size: 16, color: Colors.blueGrey[500]),
                                              SizedBox(width: 6),
                                              Text(
                                                machinery['location'] ?? 'Sin ubicación',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.blueGrey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          // Proveedor como chip
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Proveedor: ${machinery['provider']?['name'] ?? 'Sin proveedor'}', // Cambiado de provider a machinery['provider']
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
