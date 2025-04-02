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

try {
      final response = await http.post(
        Uri.parse("${widget.server}/add_product.php"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded", // Tama ang format
        },
        body: {
          "item_name": nameController.text.trim(),
          "price": priceController.text.trim(),
          "stock": stockController.text.trim(),
        },
      );

      print("Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData["success"] == true) {
          widget.refreshItems(); // ✅ Refresh list
          Navigator.pop(context); // ✅ Close page
        } else {
          showErrorDialog(responseData["message"]); // Error message galing sa PHP
        }
      } else {
        showErrorDialog("Server error: ${response.statusCode}");
      }
    } catch (e) {
      showErrorDialog("Error adding product: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          CupertinoButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Add Product"),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(controller: nameController, placeholder: "Item Name"),
              SizedBox(height: 10),
              CupertinoTextField(controller: priceController, placeholder: "Price", keyboardType: TextInputType.number),
              SizedBox(height: 10),
              CupertinoTextField(controller: stockController, placeholder: "Stock", keyboardType: TextInputType.number),
              SizedBox(height: 20),
              isLoading
                  ? CupertinoActivityIndicator()
                  : CupertinoButton.filled(
                child: Text("Add Product"),
                onPressed: addProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
