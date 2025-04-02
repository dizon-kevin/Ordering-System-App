import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class AddProductPage extends StatefulWidget {
  final String server;
  final Function refreshItems;

  const AddProductPage({super.key, required this.server, required this.refreshItems});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  bool isLoading = false;

  Future<void> addProduct() async {
    setState(() {
      isLoading = true;
    });


