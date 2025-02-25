import 'package:flutter/material.dart';
import 'screens/perfil/main_perfil.dart';
import 'screens/catalog/machinery_list_screen.dart'; // Importamos la pantalla de catálogo

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Lista de pantallas para cambiar dinámicamente
  final List<Widget> _screens = [
    MachineryListScreen(), // 📌 Ahora la pantalla de inicio es el catálogo
    Center(child: Text("Reservas", style: TextStyle(fontSize: 24))),
    Center(child: Text("Ayuda", style: TextStyle(fontSize: 24))),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 3) {
      _scaffoldKey.currentState?.openEndDrawer(); // Abre el Drawer para el perfil
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: ProfileScreen(),
      body: _screens[_selectedIndex], // 📌 Muestra la pantalla según el índice seleccionado
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.yellow[800],
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Ayuda'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
