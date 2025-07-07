import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';

final _euroFormat = NumberFormat.currency(
  locale: 'it_IT',
  symbol: '€',
  decimalDigits: 2,
);

extension DecimalExtension on Decimal {
  String toFormattedString() {
    return _euroFormat.format(toDouble());
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _importoController = TextEditingController();
  Map<Decimal, int>? _resto;
  double _totale = 0;
  bool _showResto = false;

  @override
  void initState() {
    super.initState();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _totale = orderProvider.totalAmount;
    _importoController.text = _totale.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _importoController.dispose();
    super.dispose();
  }

  void _calcolaResto() {
    if (_formKey.currentState!.validate()) {
      final ricevuto = double.tryParse(_importoController.text) ?? 0;
      
      if (ricevuto < _totale) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('L\'importo ricevuto è inferiore al totale')),
        );
        return;
      }

      setState(() {
        _resto = _calcolaRestoInterno(_totale, ricevuto);
        _showResto = true;
      });
    }
  }

  Map<Decimal, int> _calcolaRestoInterno(double totale, double ricevuto) {
    // Usa centesimi per evitare problemi con i decimali
    final tagliInCentesimi = [5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    final resto = <Decimal, int>{};
    
    // Converti in centesimi per evitare problemi con i decimali
    var restoInCentesimi = ((ricevuto * 100).round() - (totale * 100).round());
    
    if (restoInCentesimi <= 0) return {};
    
    for (final taglio in tagliInCentesimi) {
      if (restoInCentesimi >= taglio) {
        final quantita = restoInCentesimi ~/ taglio;
        if (quantita > 0) {
          final valoreTaglio = taglio / 100.0;
          resto[Decimal.parse(valoreTaglio.toStringAsFixed(2))] = quantita;
          restoInCentesimi -= quantita * taglio;
          
          if (restoInCentesimi == 0) break;
        }
      }
    }
    
    return resto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Totale da pagare',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '€${_totale.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _importoController,
                decoration: const InputDecoration(
                  labelText: 'Importo ricevuto (€)',
                  border: OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un importo';
                  }
                  final importo = double.tryParse(value);
                  if (importo == null) {
                    return 'Importo non valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _calcolaResto,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Calcola Resto',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              if (_showResto) ...[
                const SizedBox(height: 32),
                const Text(
                  'Resto da dare:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_resto != null && _resto!.isNotEmpty)
                  ..._resto!.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${entry.value} x',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              '€${entry.key.toFormattedString()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  const Text(
                    'Nessun resto da dare',
                    style: TextStyle(fontSize: 16),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Conferma Pagamento',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
