import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/perfil/main_perfil.dart';
import 'screens/catalog/machinery_list_screen.dart';
import 'SplashScreen.dart';
import 'screens/reservaciones/ReservationsScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Bloquea la orientación en vertical
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.grey[50],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueGrey[800],
          unselectedItemColor: Colors.grey[600],
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      home: SplashScreen(), // 📌 Inicia con la pantalla de bienvenida
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
    MachineryListScreen(), // 📌 Pantalla de inicio es el catálogo
    ReservationsScreen(), // Muestra las reservas del usuario
    Center(
      child: Text(
        "Ayuda",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
        ),
      ),
    ),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
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
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300), // Suave transición entre pantallas
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_selectedIndex], // 📌 Muestra la pantalla según el índice seleccionado
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
            tooltip: 'Catálogo de Maquinaria',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Reservas',
            tooltip: 'Mis Reservaciones',
          ),
        
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
            tooltip: 'Mi Perfil',
          ),
        ],
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        backgroundColor: Colors.white,
        elevation: 12,
        selectedIconTheme: IconThemeData(size: 28),
        unselectedIconTheme: IconThemeData(size: 24),
      ),
    );
  }
}