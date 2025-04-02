import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_product_page.dart';

void main() => runApp(CupertinoApp(
  debugShowCheckedModeBanner: false,
  home: Homepage(),
));

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String server = "http://192.168.1.115/devops";
  List<dynamic> items = [];
  List<Map<String, dynamic>> cart = [];
  bool isLoading = true;

  Future<void> getData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse("$server/API.php"));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          items = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print("❌ API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cart.add(item);
    });
  }

  Future<void> purchaseItems() async {
    try {
      final response = await http.post(
        Uri.parse("$server/purchase.php"),
        body: {"cart": jsonEncode(cart)},
      );

      if (response.statusCode == 200) {
        setState(() {
          cart.clear();
          getData();
        });
        showSuccessDialog();
      } else {
        print("❌ Purchase failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error purchasing: $e");
    }
  }

   void showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Purchase Successful"),
          content: Text("Your order has been placed successfully!"),
          actions: [
            CupertinoDialogAction(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void updateItem(Map<String, dynamic> item) {
    TextEditingController nameController = TextEditingController(text: item['item_name']);
    TextEditingController stockController = TextEditingController(text: item['stock'].toString());
    TextEditingController priceController = TextEditingController(text: item['price'].toString());

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text("Update Item"),
              content: Column(
                children: [
                  CupertinoTextField(controller: nameController, placeholder: "Item Name"),
                  CupertinoTextField(controller: stockController, placeholder: "Stock", keyboardType: TextInputType.number),
                  CupertinoTextField(controller: priceController, placeholder: "Price", keyboardType: TextInputType.number),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  child: Text("Update"),
                  onPressed: () async {
                    String itemName = nameController.text.trim();
                    String stock = stockController.text.trim();
                    String price = priceController.text.trim();

                    if (itemName.isEmpty || stock.isEmpty || price.isEmpty) {
                      print("❌ All fields are required");
                      return;
                    }

                    int? stockValue = int.tryParse(stock);
                    double? priceValue = double.tryParse(price);

                    if (stockValue == null || priceValue == null) {
                      print("❌ Invalid stock or price values");
                      return;
                    }

                    Map<String, dynamic> requestData = {
                      "id": item['id'], // Ensure ID is an integer
                      "item_name": itemName,
                      "stock": stockValue,
                      "price": priceValue,
                    };

                    print("📤 Sending request: ${jsonEncode(requestData)}"); // Debugging

                    try {
                      final response = await http.post(
                        Uri.parse("$server/update_item.php"),
                        headers: {
                          "Content-Type": "application/json", // Ensure JSON content type
                          "Accept": "application/json", // Accept JSON response
                        },
                        body: jsonEncode(requestData),
                      );

                      print("🛠️ Response: ${response.body}"); // Debugging

                      if (response.statusCode == 200) {
                        setState(() {
                          int index = items.indexWhere((element) => element['id'] == item['id']);
                          if (index != -1) {
                            items[index]['item_name'] = itemName;
                            items[index]['stock'] = stockValue.toString();
                            items[index]['price'] = priceValue.toString();
                          }
                        });

                        Navigator.pop(context);
                      } else {
                        print("❌ Update failed: ${response.statusCode}");
                      }
                    } catch (e) {
                      print("❌ Error updating item: $e");
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
void deleteItem(dynamic id) async {
    int itemId = int.tryParse(id.toString()) ?? 0; // Convert to int safely

    if (itemId == 0) {
      print("❌ Invalid item ID");
      return;
    }

    bool confirmDelete = await showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Delete Item"),
          content: Text("Are you sure you want to delete this item?"),
          actions: [
            CupertinoDialogAction(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              child: Text("Delete", style: TextStyle(color: CupertinoColors.systemRed)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (!confirmDelete) return; // User canceled deletion

    try {
      final response = await http.post(
        Uri.parse("$server/delete_item.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": itemId}), // Send integer ID
      );

      print("🛠️ Delete Response: ${response.body}"); // Debugging output

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData["success"] != null) {
          setState(() {
            items.removeWhere((item) => item['id'] == itemId);
          });
          print("✅ Item deleted successfully");
        } else {
          print("❌ Error deleting item: ${responseData['error']}");
        }
      } else {
        print("❌ Delete request failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error deleting item: $e");
    }
  }
@override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), getData);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Item List"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.add, color: CupertinoColors.activeGreen),
              onPressed: () async {
                await Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AddProductPage(
                      server: server,
                      refreshItems: getData,
                    ),
                  ),
                );
                getData();
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.cart, color: CupertinoColors.activeBlue),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => CartPage(cart, purchaseItems)),
                );
              },
            ),
          ],
        ),
      ),

 child: SafeArea(
        child: isLoading
            ? Center(child: CupertinoActivityIndicator())
            : items.isEmpty
            ? Center(child: Text("No items available"))
            : ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, int index) {
            final item = items[index];

            return CupertinoListTile(
              title: Text(item['item_name'] ?? "Unknown Item"),
              subtitle: Text("Stock: ${item['stock']} | Price: ₱${item['price']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.add_circled, color: CupertinoColors.systemBlue),
                    onPressed: () => addToCart(item),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.pencil, color: CupertinoColors.systemYellow),
                    onPressed: () => updateItem(item),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed),
                    onPressed: () => deleteItem(item['id']),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  final List<Map<String, dynamic>> cart;
  final Function purchaseItems;

  const CartPage(this.cart, this.purchaseItems, {super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text("Cart (${cart.length} items)"),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cart.length,
                itemBuilder: (context, int index) {
                  final item = cart[index];
                  return CupertinoListTile(
                    title: Text(item['item_name'] ?? "Unknown Item"),
                    subtitle: Text("Price: ₱${item['price'] ?? '0.00'}"),
                  );
                },
              ),
            ),
            if (cart.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: CupertinoButton.filled(
                  child: Text("Purchase"),
                  onPressed: () {
                    purchaseItems();
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

