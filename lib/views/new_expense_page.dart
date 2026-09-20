import 'package:aullet/models/category.dart' show Category;
import 'package:aullet/viewmodel/category_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewExpensePage extends StatefulWidget {
  const NewExpensePage({super.key});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage> {
  final _descriptionCtrl = TextEditingController();
  Category? _selectedCategory;
  bool _isLoadingCategories = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final catVM = context.read<CategoryViewModel>();
    await catVM.loadCategories();
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = false;
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;

    return Scaffold(
      appBar: AppBar(title: Text("Aggiungi nuova spesa")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoadingCategories)
              const CircularProgressIndicator()
            else if (categories.isEmpty)
              const Text('Nessuna categoria disponibile')
            else
              DropdownButton<Category>(
                //menu a tendina per selezionare la categoria
                isExpanded: true,
                value: _selectedCategory,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(color: Colors.blue, fontSize: 16),
                hint: const Text('Seleziona una categoria'),
                items: categories.map<DropdownMenuItem<Category>>((
                  Category category,
                ) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (Category? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),

            const SizedBox(height: 20),

            //campo per inserire l'importo
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Importo',
                prefixText: '€ ',
              ),
            ),

            const SizedBox(height: 20),

            // Campo per selezionare la data
            ListTile(
              title: const Text('Data: '),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
            ),

            //campo per inserire un'eventuale descrizione
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
              ),
            ),

            const SizedBox(height: 20),

            //pulsante per aggiungere la spesa
            ElevatedButton(onPressed: () {}, child: Text("Aggiungi Spesa")),
          ],
        ),
      ),
    );
  }
}
