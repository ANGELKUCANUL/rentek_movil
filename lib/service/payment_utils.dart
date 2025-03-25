import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart'; // Para manejar deep links
import 'dart:async';

class PaymentUtils {
  static Future<String?> createPreferenceAndPay(double price) async {
    try {
      final response = await http.post(
        Uri.parse("https://rentek.onrender.com/api/pagos/crear-preferencia"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"precio": price}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String initPoint = responseData["init_point"];

        if (initPoint.isNotEmpty) {
          print("Redirigiendo a: $initPoint");
          if (await canLaunchUrl(Uri.parse(initPoint))) {
            await launchUrl(Uri.parse(initPoint), mode: LaunchMode.externalApplication);
            return await _handlePaymentResult(); // Esperar el resultado del deep link
          } else {
            return "No se pudo abrir el enlace de pago";
          }
        }
      } else {
        return "Error al generar el pago: ${response.body}";
      }
    } catch (e) {
      return "Error de conexión: $e";
    }
  }

  static Future<String?> _handlePaymentResult() async {
    StreamSubscription? _sub;
    try {
      // Escuchar deep links
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          print("Deep link recibido: $uri");
          if (uri.host == "success") {
            return "success";
          } else if (uri.host == "failure") {
            return "failure";
          } else if (uri.host == "pending") {
            return "pending";
          }
        }
      }, onError: (err) {
        print("Error en deep link: $err");
        return "Error al procesar el pago";
      });

      // Esperar 30 segundos como máximo para recibir el deep link
      await Future.delayed(Duration(seconds: 30));
      return "Tiempo de espera agotado";
    } catch (e) {
      return "Error: $e";
    } finally {
      _sub?.cancel();
    }
  }
}