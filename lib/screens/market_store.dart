import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; // url_launcher paketini import edin
import 'package:kelibu/variables.dart';
import 'loadingIndicator.dart'; // Bu dosyanın içeriğini göremiyorum, doğru yolu sağladığınızdan emin olun

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
        'X-Custom-Header': privacyKey.privacyKeyVariable, // Custom header added
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

  Future<void> _launchURL() async {
    final url = Uri.parse('https://kelibu.net');
    if (!await canLaunchUrl(url)) {
      throw 'Could not launch $url';
    } else {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Mağaza',
          style: GoogleFonts.poppins(
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.pink,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Alışveriş sepeti sayfasına yönlendirme
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: products.isEmpty
            ? Center(child: LogoLoadingIndicator())
            : StaggeredGridView.countBuilder(
          crossAxisCount: 4,
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            final product = products[index];
            return InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(product["title"]),
                    content: Text(product["text"]),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Kapat'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.pink.shade100, width: 1), // Kenarlık rengi ve kalınlığı
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: 'https://kelibu.net/storage/${product["image"]}',
                        placeholder: (context, url) => CircularProgressIndicator(), // Burayı isteğinize göre değiştirebilirsiniz
                        errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.pink), // Hata ikonu
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(

                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        product["title"],
                        style: GoogleFonts.poppins(
                          color: Colors.pink.shade600, // Ürün başlığı rengi
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
          staggeredTileBuilder: (int index) => new StaggeredTile.count(2, index.isEven ? 3 : 3), // Adjust the tile size
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
      ),
      bottomSheet: GestureDetector(
        onTap: _launchURL,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20)
            ),
            boxShadow: const [
              BoxShadow(
                spreadRadius: 0,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Text(
            'Ürünlerimizi kelibu.net adresinden satın alıp kullanabilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
