import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/category.dart';
import 'package:shopping_list_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  int quantity = 0;
  Category category = categories[Categories.vegetables]!;
  bool _isLoading = false;

  void _save() async {
    _isLoading = true;
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final url = Uri.https(
        'shopping-list-9f3f1-default-rtdb.firebaseio.com',
        'Shopping-list.json',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': title,
          'quantity': quantity,
          'category': category.categoryName,
        }),
      );
      final resBody = json.decode(response.body);

      if (context.mounted) {
        Navigator.of(context).pop(
          GroceryItem(
            id: resBody['name'],
            name: title,
            quantity: quantity,
            category: category,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Title'),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().length <= 1 ||
                      value.isEmpty) {
                    return 'Invalid input';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  title = newValue!;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Quabtity'),
                      ),
                      validator: (value) {
                        if (value == null ||
                            int.tryParse(value) == null ||
                            int.parse(value) <= 0 ||
                            value.isEmpty) {
                          return 'Invalid input';
                        }
                        return null;
                      },
                      onSaved: (newValue) {
                        quantity = int.parse(newValue!);
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField(
                      value: category,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  height: 15,
                                  width: 15,
                                  color: category.value.color,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(category.value.categoryName)
                              ],
                            ),
                          )
                      ],
                      onChanged: (value) {
                        category = value!;
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _formKey.currentState!.reset();
                          },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _save();
                          },
                    child: _isLoading
                        ? const Text('Saving...')
                        : const Text('Save Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
