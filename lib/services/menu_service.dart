import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dish.dart';

// Lista ordinata delle categorie nell'ordine desiderato
const List<String> _orderedCategories = [
  'primi',
  'secondi',
  'contorni',
  'bevande',
  'dessert',
];

class MenuService {
  final SupabaseClient _supabase;
  bool _initialized = true;

  MenuService() : _supabase = Supabase.instance.client {
    // Check if we're using default Supabase credentials
    final url = _supabase.rest.url;
    if (url.toString().isEmpty || url.toString().contains('your-supabase-url')) {
      _initialized = false;
      debugPrint('Using default Supabase URL, falling back to sample data');
    }
  }

  // Get all dishes grouped by category in the specified order
  Future<Map<String, List<Dish>>> getDishesGroupedByCategory() async {
    try {
      final dishes = await getDishes();
      final Map<String, List<Dish>> dishesByCategory = {};
      
      // Initialize all categories with empty lists to maintain order
      for (var category in _orderedCategories) {
        dishesByCategory[category] = [];
      }
      
      // Add dishes to their respective categories
      for (var dish in dishes) {
        final category = dish.category.toLowerCase();
        if (_orderedCategories.contains(category)) {
          dishesByCategory[category]!.add(dish);
        } else {
          // If category is not in the ordered list, add it at the end
          dishesByCategory.putIfAbsent(category, () => []).add(dish);
        }
      }
      
      // Remove empty categories that are not in the ordered list
      dishesByCategory.removeWhere((key, value) => 
          value.isEmpty && !_orderedCategories.contains(key));
      
      return dishesByCategory;
    } catch (e) {
      debugPrint('Error getting dishes grouped by category: $e');
      // Return sample data in case of error
      final sampleDishes = _getSampleDishes();
      final Map<String, List<Dish>> sampleMap = {};
      
      // Initialize all categories with empty lists to maintain order
      for (var category in _orderedCategories) {
        sampleMap[category] = [];
      }
      
      // Add sample dishes to their respective categories
      for (var dish in sampleDishes) {
        final category = dish.category.toLowerCase();
        if (_orderedCategories.contains(category)) {
          sampleMap[category]!.add(dish);
        } else {
          sampleMap.putIfAbsent(category, () => []).add(dish);
        }
      }
      
      // Remove empty categories that are not in the ordered list
      sampleMap.removeWhere((key, value) => 
          value.isEmpty && !_orderedCategories.contains(key));
      
      return sampleMap;
    }
  }
  
  // Get all dishes
  Future<List<Dish>> getDishes() async {
    debugPrint('Fetching dishes...');
    if (!_initialized) {
      debugPrint('Supabase not initialized, using sample data');
      return _getSampleDishes();
    }

    try {
      debugPrint('Supabase URL: ${_supabase.rest.url}');
      debugPrint('Supabase headers: ${_supabase.rest.headers}');
      
      debugPrint('Fetching dishes from Supabase...');
      final response = await _supabase
          .from('dishes')
          .select()
          .order('category', ascending: true)
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 30));

      debugPrint('Successfully fetched ${response.length} dishes');
      return (response as List).map((json) => Dish.fromJson(json)).toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching dishes: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Falling back to sample data');
      return _getSampleDishes();
    }
  }

  // Get dishes by category
  Future<List<Dish>> getDishesByCategory(String category) async {
    try {
      if (!_initialized) {
        return _getSampleDishesByCategory(category);
      }
      
      final response = await _supabase
          .from('dishes')
          .select()
          .eq('category', category.toLowerCase())
          .order('name', ascending: true);
          
      return (response as List).map((json) => Dish.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting dishes by category: $e');
      return _getSampleDishesByCategory(category);
    }
  }

  // Sample data for testing
  List<Dish> _getSampleDishes() {
    return [
      Dish(
        id: '1',
        name: 'Pasta al Pomodoro',
        description: 'Pasta con salsa di pomodoro fresco',
        price: 8.50,
        category: 'primi',
        quantity: 0,
      ),
      Dish(
        id: '2',
        name: 'Cotoletta alla Milanese',
        description: 'Con patatine fritte',
        price: 12.00,
        category: 'secondi',
        quantity: 0,
      ),
      // Aggiungi altri piatti di esempio qui
    ];
  }

  List<Dish> _getSampleDishesByCategory(String category) {
    return _getSampleDishes().where((dish) => 
      dish.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  // Add a new dish
  Future<void> addDish(Dish dish) async {
    if (!_initialized) {
      debugPrint('Cannot add dish: Supabase not initialized');
      return;
    }
    
    try {
      await _supabase.from('dishes').insert(dish.toJson());
    } catch (e) {
      debugPrint('Error adding dish: $e');
      rethrow;
    }
  }

  // Update an existing dish
  Future<void> updateDish(Dish dish) async {
    if (!_initialized) {
      debugPrint('Cannot update dish: Supabase not initialized');
      return;
    }
    
    try {
      await _supabase
          .from('dishes')
          .update(dish.toJson())
          .eq('id', dish.id);
    } catch (e) {
      debugPrint('Error updating dish: $e');
      rethrow;
    }
  }

  // Delete a dish
  Future<void> deleteDish(String id) async {
    if (!_initialized) {
      debugPrint('Cannot delete dish: Supabase not initialized');
      return;
    }
    
    try {
      await _supabase
          .from('dishes')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting dish: $e');
      rethrow;
    }
  }
}
