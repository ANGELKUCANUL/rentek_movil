import 'package:flutter/material.dart';
import 'package:rentek/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Login.dart';
import 'metodo_pago/PaymentMethod.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent, size: 24),
              SizedBox(width: 10),
              Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("¿Estás seguro de que deseas cerrar sesión?"),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar", style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: Text("Cerrar Sesión", style: TextStyle(fontSize: 16, color: Colors.white)),
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

    Navigator.pop(context);

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
      _loadUserData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
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
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            accountName: Text(
              username ?? "Hola",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            accountEmail: email != null
                ? Text(email!, style: TextStyle(fontSize: 16, color: Colors.grey[200]))
                : null,
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.blueGrey[700]),
            ),
            margin: EdgeInsets.zero,
          ),
          if (username == null) ...[
            Padding(
              padding: EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _navigateToLogin,
                child: Text(
                  "Iniciar Sesión",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.warning, color: Colors.orange[700]),
              title: Text(
                "Inicia sesión para más opciones",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
          ] else ...[
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: Text("Cerrar Sesión", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: _confirmLogout,
            ),
            Divider(color: Colors.grey[300], indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.credit_card, color: Colors.blueGrey[600]),
              title: Text("Método de pago", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentMethodScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline, color: Colors.blueGrey[600]),
              title: Text("Preguntas Frecuentes", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.support_agent, color: Colors.blueGrey[600]),
              title: Text("Centro de Ayuda", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentMethodScreen()),
                );
              },
            ),
            Divider(color: Colors.grey[300], indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.home, color: Colors.blueGrey[600]),
              title: Text("Página de inicio", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.card_giftcard, color: Colors.blueGrey[600]),
              title: Text("Promociones", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.blueGrey[600]),
              title: Text("Sobre Rentadora", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
              onTap: () {},
            ),
            Divider(color: Colors.grey[300], indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Sigue a Rentadora",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                  icon: Icon(Icons.facebook, size: 30, color: Colors.blueGrey[600]),
                  onPressed: () async {
                    const url = 'https://www.facebook.com/share/12HY3Bq9tFX'; // Reemplaza con la URL real
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo abrir Facebook')),
                      );
                    }
                  },
                ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, size: 30, color: Colors.blueGrey[600]),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.business, size: 30, color: Colors.blueGrey[600]),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.pin_drop, size: 30, color: Colors.blueGrey[600]),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}