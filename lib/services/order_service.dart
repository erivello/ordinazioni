import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _supabase;

  OrderService() : _supabase = Supabase.instance.client;

  // Salva un nuovo ordine
  Future<void> saveOrder(Order order) async {
    try {
      // Converti gli OrderItem in una lista di mappe
      final itemsJson = order.items.map((item) => item.toJson()).toList();
      
      // Debug: stampa i dati che stiamo inviando
      debugPrint('Invio ordine con ${order.items.length} articoli');
      debugPrint('Dettagli ordine: ${order.toJson()}');
      debugPrint('Articoli: $itemsJson');
      
      // Salva l'ordine
      final response = await _supabase.rpc('create_order_with_items', params: {
        'p_order_id': order.id,
        'p_total': order.total,
        'p_status': order.status ?? 'pending',
        'p_items': itemsJson,
      });
      
      debugPrint('Ordine salvato con successo: $response');
    } catch (e, stackTrace) {
      debugPrint('Errore durante il salvataggio dell\'ordine: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Recupera tutti gli ordini
  Future<List<Order>> getOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items(*)
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Order.fromJson(json))
          .toList();
    } catch (e) {
      print('Errore durante il recupero degli ordini: $e');
      rethrow;
    }
  }
}
