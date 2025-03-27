import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../service/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerScreen({Key? key, required this.onLocationSelected}) : super(key: key);

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  String address = "Buscando ubicación...";
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determineUserLocation();
  }

  Future<void> _determineUserLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          address = "Servicio de ubicación desactivado";
          isLoading = false;
        });
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          address = "Permiso de ubicación denegado";
          isLoading = false;
        });
        return;
      }
    }

    try {
      LocationData userLocation = await location.getLocation();
      LatLng userLatLng = LatLng(userLocation.latitude!, userLocation.longitude!);
      String userAddress = await LocationService.getAddressFromLatLng(
        userLatLng.latitude,
        userLatLng.longitude,
      );

      setState(() {
        selectedLocation = userLatLng;
        address = userAddress;
        isLoading = false;
      });

      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(userLatLng));
      }
    } catch (e) {
      setState(() {
        address = "Error obteniendo la ubicación";
        isLoading = false;
      });
    }
  }

  void _onMapTap(LatLng tappedPoint) async {
    String newAddress = await LocationService.getAddressFromLatLng(
      tappedPoint.latitude,
      tappedPoint.longitude,
    );

    setState(() {
      selectedLocation = tappedPoint;
      address = newAddress;
    });
  }

  Future<void> _searchLocation() async {
    String query = searchController.text;
    if (query.isEmpty) return;

    LatLng? newLocation = await LocationService.getCoordinatesFromAddress(query);
    if (newLocation != null) {
      String newAddress = await LocationService.getAddressFromLatLng(
        newLocation.latitude,
        newLocation.longitude,
      );

      setState(() {
        selectedLocation = newLocation;
        address = newAddress;
      });

      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(newLocation));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Dirección no encontrada"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Seleccionar Ubicación",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar dirección...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: _searchLocation,
                  child: Icon(Icons.search, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.blueGrey))
                    : GoogleMap(
                        onMapCreated: (controller) {
                          mapController = controller;
                          if (selectedLocation != null) {
                            mapController!.animateCamera(CameraUpdate.newLatLng(selectedLocation!));
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target: selectedLocation ?? const LatLng(37.7749, -122.4194),
                          zoom: 14,
                        ),
                        markers: selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId("seleccionado"),
                                  position: selectedLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                                )
                              }
                            : {},
                        onTap: _onMapTap,
                      ),
                if (!isLoading)
                  Positioned(
                    top: 10,
                    left: MediaQuery.of(context).size.width * 0.25,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        "Toca el mapa para ajustar",
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_pin, size: 20, color: Colors.blueGrey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Dirección: $address",
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedLocation != null ? Colors.blueGrey[800] : Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                  ),
                  onPressed: selectedLocation != null
                      ? () {
                          widget.onLocationSelected(selectedLocation!, address);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(
                    "Confirmar Ubicación",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}