import 'package:http/http.dart' as http;
import 'dart:convert';

class MpesaService {
  // Badilisha URL hii na yako halisi kutoka Supabase
  static const String _functionUrl = 'https://YOUR-PROJECT-REF.supabase.co/functions/v1/mpesa-stkpush';

  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,   // Lazima ianze na 254...
    required double amount,
    required String leaseId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone': phoneNumber,
          'amount': amount,
          'lease_id': leaseId,
          'account_ref': 'ALTAVAS-RENT-$leaseId',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ M-Pesa STK Push sent successfully');
        return {'success': true, 'data': data};
      } else {
        print('❌ Error: ${response.body}');
        return {'success': false, 'error': data};
      }
    } catch (e) {
      print('Exception: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
