import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dish_service.dart';
import '../models/dish.dart';

class EditDishScreen extends StatefulWidget {
  final Dish? dish;

  const EditDishScreen({super.key, this.dish});

  @override
  State<EditDishScreen> createState() => _EditDishScreenState();
}

class _EditDishScreenState extends State<EditDishScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late String _category;
  late bool _isAvailable;
  late int _sortOrder;
  String? _description;
  String? _imageUrl;

  final List<String> _categories = [
    'primi',
    'secondi',
    'contorni',
    'bevande',
    'dessert',
    'altro'
  ];

  @override
  void initState() {
    super.initState();
    final dish = widget.dish;
    if (dish != null) {
      _name = dish.name;
      _price = dish.price;
      _category = dish.category;
      _description = dish.description;
      _imageUrl = dish.imageUrl;
      _isAvailable = dish.isAvailable;
      _sortOrder = dish.sortOrder;
    } else {
      _name = '';
      _price = 0;
      _category = _categories.first;
      _isAvailable = true;
      _sortOrder = 0;
    }
  }

  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    debugPrint('Salvataggio piatto con sortOrder: $_sortOrder');

    final dish = widget.dish?.copyWith(
          name: _name,
          price: _price,
          category: _category,
          description: _description,
          imageUrl: _imageUrl,
          isAvailable: _isAvailable,
          sortOrder: _sortOrder,
          updatedAt: DateTime.now(),
        ) ??
        Dish(
          name: _name,
          price: _price,
          category: _category,
          description: _description,
          imageUrl: _imageUrl,
          isAvailable: _isAvailable,
          sortOrder: _sortOrder,
          updatedAt: DateTime.now(),
        );
        
    debugPrint('Piatto creato con sortOrder: ${dish.sortOrder}');

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final dishService = context.read<DishService>();

    try {
      if (widget.dish == null) {
        await dishService.addDish(dish);
        messenger.showSnackBar(
          const SnackBar(content: Text('Piatto aggiunto con successo')),
        );
      } else {
        await dishService.updateDish(dish);
        messenger.showSnackBar(
          const SnackBar(content: Text('Piatto aggiornato con successo')),
        );
      }
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dish == null ? 'Nuovo Piatto' : 'Modifica Piatto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDish,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nome del piatto'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome del piatto';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _sortOrder.toString(),
                decoration: const InputDecoration(
                  labelText: 'Ordinamento',
                  helperText: 'Numero più basso = visualizzazione in alto',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un numero';
                  }
                  final number = int.tryParse(value);
                  if (number == null) {
                    return 'Inserisci un numero valido';
                  }
                  return null;
                },
                onSaved: (value) => _sortOrder = int.tryParse(value ?? '0') ?? 0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(
                  labelText: 'Prezzo *',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il prezzo';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Inserisci un prezzo valido';
                  }
                  return null;
                },
                onSaved: (value) => _price = double.parse(value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Categoria *',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category[0].toUpperCase() +
                              category.substring(1)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => _description = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _imageUrl,
                decoration: const InputDecoration(
                  labelText: 'URL immagine',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _imageUrl,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Disponibile'),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
