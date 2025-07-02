import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> addToCart(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User tidak login");

    final existing = await _supabase
        .from('cart_items')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing != null) {
      await _supabase.from('cart_items').update({
        'quantity': (existing['quantity'] ?? 1) + 1,
      }).eq('id', existing['id']);
    } else {
      await _supabase.from('cart_items').insert({
        'user_id': userId,
        'product_id': productId,
        'quantity': 1,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User tidak login");

    final response = await _supabase
        .from('cart_items')
        .select('*, products(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }
}
