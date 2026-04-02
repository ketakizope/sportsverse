import 'package:flutter/material.dart';
import 'package:sportsverse_app/api/api_client.dart';
import 'dart:convert';
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List expenses = [];
  bool isLoading = true;

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    final res = await apiClient.get('/api/payments/expenses/');
    if (res.statusCode == 200) {
      setState(() {
        expenses = res.body != null ? List.from(jsonDecode(res.body)) : [];
        isLoading = false;
      });
    }
  }

  Future<void> addExpense() async {
    final res = await apiClient.post(
      '/api/payments/add-expense/',
      {
        "title": titleController.text,
        "amount": amountController.text,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      Navigator.pop(context);
      fetchExpenses();
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: addExpense, child: const Text("Save"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expenses")),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (_, i) {
                final e = expenses[i];
                return ListTile(
                  title: Text(e['title']),
                  subtitle: Text(e['type']),
                  trailing: Text("₹${e['amount']}"),
                );
              },
            ),
    );
  }
}