import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _serviceId = 'service_0jgwrh2';
  static const _templateId = 'template_qwfid7s';
  static const _publicKey = 'Bq59-dhJpDx7Bu8qr';

  static Future<void> sendWelcomeEmail({
    required String toEmail,
    required String toName,
  }) async {
    try {
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
          },
        }),
      );
    } catch (_) {}
  }
}
