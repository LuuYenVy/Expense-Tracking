import 'package:expense_tracker_app/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker_app/models/expense.dart';
import 'package:expense_tracker_app/expense_list.dart';
import 'package:expense_tracker_app/widgets/chart/chart.dart';
import 'package:expense_tracker_app/data/database_helper.dart';
class Expenses extends StatefulWidget {
  const Expenses({super.key});
  @override
  State<StatefulWidget> createState() {
    return _ExpensesState();
  }

}


class _ExpensesState extends State<Expenses> {
  final List<Expense> _registerExpense = [
    Expense(
        title: 'Flutter Course',
        amount: 19.99,
        date: DateTime.now(),
        category: Category.work),
    Expense(
        title: 'Cinema',
        amount: 10.99,
        date: DateTime.now(),
        category: Category.leisure),
  ];

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (ctx) => NewExpense(
        onAddExpense: _addExpense,
      ),
    );
  }

  void _addExpense(Expense expense) async {
    await DatabaseHelper.instance.insertExpense({
      'id': expense.id, // 👈 QUAN TRỌNG
      'title': expense.title,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category.toString(),
    });

    setState(() {
      _registerExpense.add(expense);
    });
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _registerExpense.indexOf(expense);

    await DatabaseHelper.instance.deleteExpense(expense.id);

    setState(() {
      _registerExpense.remove(expense);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Expense deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await DatabaseHelper.instance.insertExpense({
              'id': expense.id,
              'title': expense.title,
              'amount': expense.amount,
              'date': expense.date.toIso8601String(),
              'category': expense.category.toString(),
            });

            setState(() {
              _registerExpense.insert(expenseIndex, expense);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    Widget mainContent = const Center(
      child: Text('No expenses found. Start adding some!'),
    );
    if (_registerExpense.isNotEmpty) {
      mainContent = ExpenseList(
        expenses: _registerExpense,
        onRemoveExpense: _removeExpense,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fullter Expense Tracker"),
        actions: [
          IconButton(
              onPressed: _openAddExpenseOverlay, icon: const Icon(Icons.add))
        ],
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _registerExpense),
                Expanded(child: mainContent)
              ],
            )
          : Row(
              children: [
                Expanded(child: Chart(expenses: _registerExpense)),
                Expanded(child: mainContent)
              ],
            ),
    );
  }
  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final data = await DatabaseHelper.instance.getExpenses();

    setState(() {
      _registerExpense.clear();

      _registerExpense.addAll(
        data.map((e) => Expense(
          id: e['id'],
          title: e['title'],
          amount: e['amount'],
          date: DateTime.parse(e['date']),
          category: Category.values.firstWhere(
                (c) => c.toString() == e['category'],
          ),
        )),
      );
    });
  }
}
