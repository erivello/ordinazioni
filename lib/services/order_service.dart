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
      // Converti gli OrderItem in una lista di mappe
      final itemsJson = order.items.map((item) => item.toJson()).toList();
      
      // Debug: stampa i dati che stiamo inviando
      debugPrint('Invio ordine con ${order.items.length} articoli');
      debugPrint('Dettagli ordine: ${order.toJson()}');
      debugPrint('Numero tavolo: ${order.tableNumber}');
      debugPrint('Note: ${order.notes}');
      
      // Verifica la connessione a Supabase
      if (_supabase.auth.currentUser == null) {
        debugPrint('Nessun utente autenticato. Accesso anonimo in corso...');
      }
      
      // Salva l'ordine
      try {
        final response = await _supabase.rpc('create_order_with_items', params: {
          'p_order_id': order.id,
          'p_total': order.total,
          'p_status': order.status ?? 'pending',
          'p_table_number': order.tableNumber,
          'p_notes': order.notes,
          'p_items': itemsJson,
        });
        
        debugPrint('Ordine salvato con successo: $response');
      } on PostgrestException catch (e) {
        debugPrint('Errore Postgrest: ${e.message}');
        debugPrint('Dettagli: ${e.details}');
        debugPrint('Hint: ${e.hint}');
        debugPrint('Codice: ${e.code}');
        rethrow;
      } catch (e) {
        debugPrint('Errore durante la chiamata RPC: $e');
        rethrow;
      }
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
