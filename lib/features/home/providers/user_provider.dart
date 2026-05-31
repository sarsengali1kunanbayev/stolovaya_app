import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

final userRoleProvider = FutureProvider<String>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  print('USER ID: $userId');
  if (userId == null) return 'seller';

  try {
    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    print('PROFILE DATA: $data');
    return data?['role'] as String? ?? 'seller';
  } catch (e) {
    print('PROFILE ERROR: $e');
    return 'seller';
  }
});
