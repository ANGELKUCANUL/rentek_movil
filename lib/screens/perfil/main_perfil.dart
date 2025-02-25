import 'package:flutter/material.dart';
import 'package:rentek/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? username;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      email = prefs.getString('userEmail');
    });
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Cerrar Sesión"),
          content: Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                _logout(); // Cierra sesión y recarga la pantalla
              },
              child: Text("Cerrar Sesión", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      username = null;
      email = null;
    });

    Navigator.pop(context); // Cierra el menú lateral

    // Recarga la pantalla y vuelve a MainScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    ).then((_) {
      _loadUserData(); // Recarga los datos después de iniciar sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()), // Recarga la pantalla principal
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.yellow.shade800),
            accountName: username != null
                ? Text(username!, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                : Text("Hola", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            accountEmail: email != null ? Text(email!) : null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.black54),
            ),
          ),
          if (username == null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow.shade700),
                onPressed: _navigateToLogin, // Ahora redirige al login y recarga la pantalla
                child: Text("Iniciar Sesión"),
              ),
            ),
          ] else ...[
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text("Cerrar Sesión"),
              onTap: _confirmLogout,
            ),
          ],
          Divider(),
          ListTile(
            leading: Icon(Icons.language),
            title: Text("Idioma y Moneda"),
            trailing: Text("MXN 🇲🇽"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text("Preguntas Frecuentes"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.support_agent),
            title: Text("Centro de Ayuda"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Página de inicio"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.card_giftcard),
            title: Text("Promociones"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Sobre Rentadora"),
            onTap: () {},
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Sigue a Rentadora", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.facebook, size: 30),
              Icon(Icons.camera_alt, size: 30),
              Icon(Icons.business, size: 30),
              Icon(Icons.pin_drop, size: 30),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
