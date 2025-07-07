import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../services/dish_service.dart';
import 'payment_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  OrderSummaryScreenState createState() => OrderSummaryScreenState();
}

class OrderSummaryScreenState extends State<OrderSummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  int _selectedTable = 1;
  
  @override
  void initState() {
    super.initState();
    final orderProvider = context.read<OrderProvider>();
    _selectedTable = orderProvider.tableNumber;
    _notesController.text = orderProvider.orderNotes ?? '';
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orderItems = orderProvider.selectedDishes.values.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riepilogo Ordine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Ricarica i piatti disponibili
              final dishService = context.read<DishService>();
              dishService.getDishes();
              
              // Mostra un feedback all'utente
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menu aggiornato'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Selettore tavolo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<int>(
                value: _selectedTable,
                decoration: const InputDecoration(
                  labelText: 'Tavolo',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: List.generate(20, (index) => index + 1)
                    .map((number) => DropdownMenuItem(
                          value: number,
                          child: Text('Tavolo $number'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTable = value;
                    });
                    orderProvider.updateTableNumber(value);
                  }
                },
              ),
            ),
            
            // Note per l'ordine
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note per la cucina (opzionale)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  orderProvider.updateOrderNotes(value.isEmpty ? null : value);
                },
              ),
            ),
            
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 8),
            
            Expanded(
              child: orderItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun articolo nell\'ordine',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Quantità: ${item.quantity}'),
                            trailing: Text(
                              '€${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            onTap: () {
                              // Opzionale: permettere di modificare la quantità
                            },
                          ),
                        );
                      },
                    ),
            ),
            if (orderItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Totale (${orderProvider.totalItems} articoli):',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '€${orderProvider.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Bottone Annulla
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () async {
                          final shouldCancel = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Annulla ordine'),
                              content: const Text('Sei sicuro di voler annullare l\'ordine?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('NO'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'SI',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldCancel == true) {
                            if (context.mounted) {
                              orderProvider.clearOrder();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ordine annullato'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'ANNULLA',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bottone Invia Ordine
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        onPressed: () async {
                          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                          
                          // Naviga alla schermata di pagamento
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaymentScreen(),
                            ),
                          );

                          // Se il pagamento è andato a buon fine
                          if (result == true) {
                            // Mostra il messaggio di successo
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ordine inviato con successo!')),
                            );
                            
                            // Resetta il numero del tavolo a 1
                            orderProvider.updateTableNumber(1);
                            
                            // Resetta le note
                            orderProvider.updateOrderNotes(null);
                            
                            // Pulisci il carrello
                            orderProvider.clearOrder();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'INVIA ORDINE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'TORNA AL MENU',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
