import 'package:aullet/models/category.dart';
import 'package:aullet/models/expense.dart';
import 'package:aullet/utils/color_utils.dart';
import 'package:aullet/utils/icon_map.dart';
import 'package:aullet/viewmodel/category_view_model.dart';
import 'package:aullet/viewmodel/expense_view_model.dart';
import 'package:aullet/views/new_expense_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aullet/views/edit_expense_page.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseViewModel>().loadExpenses();
      context.read<CategoryViewModel>().loadCategories();
    });
  }

Future<void> _editExpense(Expense exp) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EditExpensePage(expense: exp),
    ),
  );

  if (!mounted) return;

  await context.read<ExpenseViewModel>().loadExpenses();
}

Future<void> _deleteExpense(Expense exp) async {
  final expenseVM = context.read<ExpenseViewModel>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Elimina spesa'),
      content: const Text(
        'Sei sicura di voler eliminare questa spesa?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Elimina'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  await expenseVM.deleteExpense(exp.id!);

  if (!mounted) return;

  await expenseVM.loadExpenses();
}

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final catVM = context.watch<CategoryViewModel>();

    return Scaffold(
      body: expenseVM.isLoading || catVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(expenseVM, catVM),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.home)),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewExpensePage()),
          ).then((_) {
            //ricarica lista dopo il ritorno dalla form
            context.read<ExpenseViewModel>().loadExpenses();
          });
        },
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody(ExpenseViewModel expenseVM, CategoryViewModel catVM) {
    final expenses = expenseVM.expense;
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Non ci sono spese inserite',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewExpensePage()),
                ).then((_) {
                  context.read<ExpenseViewModel>().loadExpenses();
                });
              },
              label: const Text('Aggiungi spesa'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: ListView.separated(
        itemCount: expenses.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final exp = expenses[index];
          final cat = catVM.categories.firstWhere(
            (c) => c.id == exp.categoryId,
            orElse: () => Category(
              id: '',
              name: 'Unknown',
              icon: 'category',
              color: 'FF000000',
            ),
          );
          final iconData = iconMap[cat.icon] ?? Icons.category;
          final color = parseHexColor(cat.color);
          final date = exp.date;
          final formattedDate =
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';

          return ListTile(
            leading: Icon(iconData, color: color),
            title: Text(
              'Euro ${exp.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$formattedDate${exp.description != null && exp.description!.isNotEmpty ? '\n${exp.description}' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
IconButton(
  onPressed: () => _editExpense(exp),
  icon: const Icon(Icons.edit),
),
IconButton(
  onPressed: () => _deleteExpense(exp),
  icon: const Icon(Icons.delete),
),
              ],
            ),
          );
        },
      ),
    );
  }
}
