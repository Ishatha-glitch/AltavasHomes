import 'package:supabase_flutter/supabase_flutter.dart';

class MpesaService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Initiates an M-Pesa STK push for a specific lease.
  /// [phoneNumber] must be in 254XXXXXXXXX format.
  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String leaseId,
    required String tenantId,
    required String landlordId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
  'hyper-api',',
        body: {
          'phone': phoneNumber,
          'amount': amount,
          'lease_id': leaseId,
          'tenant_id': tenantId,
          'landlord_id': landlordId,
          'account_ref': 'ALTAVAS-RENT-$leaseId',
        },
      );

      final data = response.data;

      if (response.status == 200 && data is Map && data['success'] == true) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
