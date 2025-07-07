import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/menu_screen.dart';
import 'screens/admin_dishes_screen.dart';
import 'services/dish_service.dart';
import 'services/order_service.dart';
import 'providers/order_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carica le variabili d'ambiente
  await dotenv.load(fileName: ".env");
  
  // Ottieni le credenziali di Supabase dall'ambiente
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('Errore: Manca la configurazione di Supabase nel file .env');
  }

  try {
    debugPrint('Inizializzazione di Supabase...');
    
    // Inizializza Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Abilita i log di debug
    );
    
    debugPrint('Supabase inizializzato con successo');
    
    // Test di connessione
    try {
      final response = await Supabase.instance.client
          .from('dishes')
          .select('count')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('Connesso a Supabase. Conteggio piatti: $response');
      
    } catch (e) {
      debugPrint('Errore durante il test di connessione a Supabase: $e');
    }
  } catch (e) {
    debugPrint('Errore durante l\'inizializzazione di Supabase: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        Provider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => DishService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sagra di San Lorenzo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MenuScreen(),
        '/admin/dishes': (context) => const AdminDishesScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
