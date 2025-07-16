import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

// Estensione per convertire un oggetto DateTime in una stringa ISO 8601
// che include i millisecondi
// extension DateTimeExtension on DateTime {
//   String toIso8601WithMilliseconds() {
//     final String iso = toIso8601String();
//     if (iso.contains('.')) return iso;
//     return '${iso.substring(0, iso.length - 1)}.000Z';
//   }
// }

class OrderService {
  final SupabaseClient _supabase;

  OrderService() : _supabase = Supabase.instance.client;

  // Salva un nuovo ordine
  Future<void> saveOrder(Order order) async {
    try {
      // Verifica che tutti gli articoli abbiano un ID piatto valido
      for (final item in order.items) {
        if (item.dishId.isEmpty) {
          throw Exception('ID piatto mancante per l\'articolo: ${item.dishName}');
        }
      }
      
      // Debug: stampa i dati che stiamo inviando
      debugPrint('=== BUILD ORDER SUMMARY ===');
      debugPrint('Numero di piatti: ${order.items.length}');
      debugPrint('Chiavi dei piatti: (${order.items.map((i) => i.dishId).join(', ')})');
      
      // Verifica la connessione a Supabase
      final isConnected = await checkConnection();
      if (!isConnected) {
        throw Exception('Nessuna connessione a Supabase');
      }
      
      if (_supabase.auth.currentUser == null) {
        debugPrint('Nessun utente autenticato. Accesso anonimo in corso...');
      }
      
      debugPrint('Invio ordine con ${order.items.length} articoli');
      debugPrint('Dettagli ordine: ${order.toJson()}');
      debugPrint('Numero tavolo: ${order.tableNumber}');
      debugPrint('Note: ${order.notes}');
      
      // Prepara i parametri per la chiamata RPC
      final params = <String, dynamic>{
        'p_order_id': order.id,
        'p_total': order.total,
        'p_status': order.status ?? 'pending',
        'p_table_number': order.tableNumber,
        'p_order_notes': order.notes ?? '',  // Invia una stringa vuota se notes è null
        'p_items': order.items.map((item) => {
          'dishId': item.dishId,
          'dishName': item.dishName,
          'dishPrice': item.dishPrice,
          'quantity': item.quantity,
          'notes': item.notes,
        }).toList(),
      };
      
      // Log dettagliato per il debug
      debugPrint('=== PARAMETRI ORDINE ===');
      debugPrint('ID Ordine: ${order.id}');
      debugPrint('Totale: ${order.total}');
      debugPrint('Stato: ${order.status ?? 'pending'}');
      debugPrint('Tavolo: ${order.tableNumber}');
      debugPrint('Note: ${order.notes ?? 'Nessuna nota'}');
      debugPrint('=== ARTICOLI ===');
      for (var i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        debugPrint('Articolo ${i + 1}:');
        debugPrint('  dishId: ${item.dishId}');
        debugPrint('  dishName: ${item.dishName}');
        debugPrint('  dishPrice: ${item.dishPrice}');
        debugPrint('  quantity: ${item.quantity}');
        debugPrint('  notes: ${item.notes}');
      }
      
      // Usa una transazione di Supabase
      await _supabase.rpc('create_order_with_items', params: params);
      
      debugPrint('Ordine salvato con successo: ${order.id}');
    } catch (e, stackTrace) {
      debugPrint('Errore durante il salvataggio dell\'ordine: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Verifica la connessione a Supabase
  Future<bool> checkConnection() async {
    try {
      // Prova una query semplice per verificare la connessione
      await _supabase
          .from('orders')
          .select()
          .limit(1);
          
      // Se arriviamo qui, la query è andata a buon fine
      debugPrint('Connessione a Supabase verificata con successo');
      return true;
      
    } on PostgrestException catch (e) {
      debugPrint('Errore di database: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Errore di connessione a Supabase: $e');
      return false;
    }
  }

  // Recupera tutti gli ordini
  Future<List<Order>> getOrders() async {
    try {
      final isConnected = await checkConnection();
      if (!isConnected) {
        throw Exception('Nessuna connessione al database');
      }

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
      debugPrint('Errore durante il recupero degli ordini: $e');
      rethrow;
    }
  }
}
