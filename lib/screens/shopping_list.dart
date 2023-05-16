import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/screens/new_item_screen.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<GroceryItem> groceries = [];
  bool _isLoading = true;
  String? _error;

  //initState Function
  @override
  initState() {
    super.initState();
    _loadItems();
  }

  //Function to load data from firebase
  void _loadItems() async {
    final url = Uri.https(
      'shopping-list-9f3f1-default-rtdb.firebaseio.com',
      'Shopping-list.json',
    );

    try {
      final response = await http.get(url);
      final resBody = json.decode(response.body);

      if (response.statusCode >= 400) {
        setState(() {
          _error = resBody['error'];
        });
      }

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final List<GroceryItem> localGroceries = [];
      for (final grocery in resBody.entries) {
        final category = categories.entries
            .firstWhere(
                (cat) => cat.value.categoryName == grocery.value['category'])
            .value;
        localGroceries.add(
          GroceryItem(
            id: grocery.key,
            name: grocery.value['name'],
            quantity: grocery.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        groceries = localGroceries;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = 'Something went wrong...';
      });
    }
  }

  //function to add grocery to list
  void addNewItem() async {
    final GroceryItem? grocery = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return const NewItem();
        },
      ),
    );
    if (grocery == null) {
      return;
    }
    setState(() {
      groceries.add(grocery);
    });
  }

  //Function to remove Item
  void _removeItem(GroceryItem item) async {
    final itemIndex = groceries.indexOf(item);
    setState(() {
      groceries.remove(item);
    });
    final url = Uri.https(
      'shopping-list-9f3f1-default-rtdb.firebaseio.com',
      'Shopping-list/${item.id}.json',
    );
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        groceries.insert(itemIndex, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
//if strusture to decide screen content
    Widget body;

    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (groceries.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('No Grocery.'),
            Text('All your groceries will appear here...'),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        itemCount: groceries.length,
        itemBuilder: (context, index) {
          return Dismissible(
            key: ValueKey(groceries[index].id),
            background: Container(
              color: Theme.of(context).colorScheme.onError,
            ),
            onDismissed: (direction) {
              _removeItem(groceries[index]);
            },
            child: ListTile(
              leading: Container(
                height: 25,
                width: 25,
                color: groceries[index].category.color,
              ),
              title: Text(groceries[index].name),
              trailing: Text(groceries[index].quantity.toString()),
            ),
          );
        },
      );
    }

    if (_error != null) {
      body = Center(
        child: Text(_error!),
      );
    }

    //Page Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: () {
              addNewItem();
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: body,
    );
  }
}
