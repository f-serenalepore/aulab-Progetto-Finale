import 'package:aullet/models/category.dart';
import 'package:aullet/models/expense.dart';
import 'package:aullet/viewmodel/category_view_model.dart';
import 'package:aullet/viewmodel/expense_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditExpensePage extends StatefulWidget {
  final Expense expense;

  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  Category? _selectedCategory;
  bool _isLoadingCategories = true;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    // Precompila i campi con i dati della spesa
    _amountCtrl.text = widget.expense.amount.toString();
    _descriptionCtrl.text = widget.expense.description ?? '';
    _selectedDate = widget.expense.date;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final catVM = context.read<CategoryViewModel>();

    await catVM.loadCategories();

    if (!mounted) return;

    final categories = catVM.categories;

    // Cerca la categoria della spesa
    for (final category in categories) {
      if (category.id == widget.expense.categoryId) {
        _selectedCategory = category;
        break;
      }
    }

    setState(() {
      _isLoadingCategories = false;
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateExpense() async {
    // Controlla la categoria
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleziona una categoria')));
      return;
    }

    // Converte l'importo
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un importo valido')),
      );
      return;
    }

    // Crea la versione aggiornata della spesa
    final updatedExpense = Expense(
      id: widget.expense.id,
      userId: widget.expense.userId,
      categoryId: _selectedCategory!.id,
      amount: amount,
      date: _selectedDate,
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
    );

    final expenseVM = context.read<ExpenseViewModel>();

    await expenseVM.updateExpense(updatedExpense);

    if (!mounted) return;

    if (expenseVM.errorMessage == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>().categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Modifica spesa')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CATEGORIA
            if (_isLoadingCategories)
              const CircularProgressIndicator()
            else
              DropdownButton<Category>(
                isExpanded: true,
                value: _selectedCategory,
                hint: const Text('Seleziona una categoria'),
                icon: const Icon(Icons.arrow_drop_down),
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

            // IMPORTO
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Importo',
                prefixText: '€ ',
              ),
            ),

            const SizedBox(height: 20),

            // DATA
            ListTile(
              title: const Text('Data'),
              subtitle: Text(
                '${_selectedDate.day}/'
                '${_selectedDate.month}/'
                '${_selectedDate.year}',
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

            // DESCRIZIONE
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
              ),
            ),

            const SizedBox(height: 20),

            // SALVA
            ElevatedButton(
              onPressed: _updateExpense,
              child: const Text('Salva modifiche'),
            ),
          ],
        ),
      ),
    );
  }
}
