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
  TextEditingController searchController = TextEditingController(); // Controlador del buscador

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
        const SnackBar(content: Text("Dirección no encontrada")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seleccionar Ubicación")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar dirección...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    onMapCreated: (controller) {
                      mapController = controller;
                      if (selectedLocation != null) {
                        mapController!.animateCamera(CameraUpdate.newLatLng(selectedLocation!));
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation ?? const LatLng(37.7749, -122.4194), // Ubicación por defecto
                      zoom: 14,
                    ),
                    markers: selectedLocation != null
                        ? {Marker(markerId: const MarkerId("seleccionado"), position: selectedLocation!)}
                        : {},
                    onTap: _onMapTap,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text("Dirección: $address", textAlign: TextAlign.center),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: selectedLocation != null
                      ? () {
                          widget.onLocationSelected(selectedLocation!, address);
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text("Confirmar Ubicación"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
