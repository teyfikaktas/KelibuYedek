import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:kelibu/providers/user_provider.dart';
import 'package:provider/provider.dart';

import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:kelibu/variables.dart';

import '../main.dart';

class MarketPage extends StatefulWidget {
  MarketPage({Key? key}) : super(key: key);

  @override
  _MarketPageState createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final response = await http.get(
      Uri.parse('https://kelibu.net/api/getProductAll'),
      headers: {
        'X-Custom-Header': privacyKey.privacyKeyVariable,
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        products = data.map<Map<String, dynamic>>((item) => {
          "id": item["id"],
          "title": item["title"],
          "text": item["text"],
          "image": item["image"],
          "price": item["price"],
        }).toList();
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<void> buyProduct(String productId) async {
    print("productId= " + productId.toString());
    UserProvider userprovider = Provider.of<UserProvider>(context, listen: false);
    Uri url = Uri.parse('https://kelibu.net/api/buy-product');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Custom-Header': privacyKey.privacyKeyVariable,
        },
        body: json.encode({
          'userid': userprovider.userId.toString(),
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.pink[50],  // Pembemsi arkaplan
            title: Text('Ürün Kütüphaneye Başarılı bir şekilde eklenmiştir.'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png'),  // Logo ekleniyor
                Text('Ürün başarıyla kütüphaneye eklendi.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Tamam'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainScreen()));

                },
              ),
            ],
          ),
        );
      } else if (response.statusCode == 403) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.pink[100],  // Pembemsi arkaplan
            title: Text('Satın Alma Başarısız'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png'),  // Logo ekleniyor
                Text('Bu ürüne zaten sahipsiniz.'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Tamam'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        var responseData = jsonDecode(response.body);
        var responseError = responseData['error'] ?? 'Bilinmeyen hata.';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.pink[100],  // Pembemsi arkaplan
            title: Text('Satın Alma Başarısız'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png'),  // Logo ekleniyor
                Text('Satın alma işlemi sırasında bir hata oluştu: $responseError'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Tamam'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.pink[100],  // Pembemsi arkaplan
          title: Text('Hata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo.png'),  // Logo ekleniyor
              Text('Satın alma işlemi sırasında bir hata meydana geldi: ${e.toString()}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6),
      appBar: AppBar(
        backgroundColor: Colors.pink[50],
        flexibleSpace: SafeArea(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  "Kelibu'nun tüm setleri kısa süreli olarak öğrencilerimize ücretsizdir, PhD Akademi Eğitim hayatınızda başarılar diler!",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: products.isEmpty
            ? Center(child: CircularProgressIndicator())
            : StaggeredGridView.countBuilder(
          crossAxisCount: 4,
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            final product = products[index];
            return InkWell(
              onTap: () async {
                final shouldBuy = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Kütüphaneye Ekle'),
                    content: Text('Bu ürünü kütüphaneye eklemek istiyor musunuz?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Hayır'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: Text('Evet'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  ),
                );

                if (shouldBuy ?? false) {
                  buyProduct(product['id'].toString());
                }
              },
              child: Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.pink.shade100, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: 'https://kelibu.net/storage/${product["image"]}',
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.pink),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product["title"],
                        style: GoogleFonts.poppins(
                          color: Colors.pink.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          staggeredTileBuilder: (int index) => new StaggeredTile.count(2, index.isEven ? 3 : 3),
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
      ),
    );
  }
}
