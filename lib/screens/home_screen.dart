import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/variables.dart';

import '../Models/category.dart';
import '../providers/user_provider.dart';
import 'flashy_tab_bar2.dart'; // FlashyTabBar dosyanızın yolu
import 'package:kelibu/api.dart'; // ApiService dosyanızın yolu
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Add path_provider package
import 'package:google_fonts/google_fonts.dart'; // Google Fonts'u import edin
import 'package:shimmer/shimmer.dart';
import 'dart:math';
import '../screens/leader_screen.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
class WordOfTheDay {
  final String term;
  final String definition;
  final String? type;

  WordOfTheDay({required this.term, required this.definition, this.type});

  factory WordOfTheDay.fromJson(Map<String, dynamic> json) {
    return WordOfTheDay(
      term: json['terim'],
      definition: json['tanim'],
      type: json['type'],
    );
  }
}

class MyListItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const MyListItem({Key? key, required this.title, required this.onTap}) : super(key: key);

  @override
  _MyListItemState createState() => _MyListItemState();
}

class _MyListItemState extends State<MyListItem> {
  bool _isTapped = false;
  final FlutterTts flutterTts = FlutterTts();

  void speak(String text) async {
    print("object");
    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _isTapped = !_isTapped);
        widget.onTap();
        speak("widget.title"); // Kelimenin okunmasını sağla
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: _isTapped ? Colors.grey : Colors.white,
        child: GFListTile(
          titleText: widget.title,
          icon: Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}

  Future<WordOfTheDay> fetchWordOfTheDay() async {
  final uri = Uri.parse('https://kelibu.net/api/daily-word');
  final response = await http.get(uri, headers: {
    "X-Custom-Header": privacyKey.privacyKeyVariable, // İsteğinize eklemek istediğiniz header
  });

  if (response.statusCode == 200) {
    return WordOfTheDay.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to load word of the day');
  }
}


void _onItemSelected(int index, BuildContext context) {
  if (index == 1) { // Liderlik tab'ı seçildiğinde
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LeaderboardPage()),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Future<List<Package>>? packagesFuture;
  bool isExpanded = false;
  int _userPoint = 0;
  bool _showMore = false; // "Daha Fazla Göster" seçeneğinin gösterilip gösterilmeyeceğini kontrol eder
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _getPoint();
  }
  
  void _getPoint() async {
    int userId = Provider.of<UserProvider>(context, listen: false).userId;
    print('hash');
    String hash = await Provider.of<UserProvider>(context, listen: false).getUsernameHash();
    print(hash);

    int userPoint = await ApiService().fetchUserPoint(userId);

    Provider.of<UserProvider>(context, listen: false).addPoint(userPoint);
  }
  void _fetchData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    print('fetchdata');
    // Kullanıcı puanını al
    ApiService().fetchUserPoint(currentUserId).then((userPoint) {
      setState(() {
        _userPoint = userPoint;
        UserProvider().addPoint(_userPoint);

      });
    }).catchError((error) {
      print("Error fetching user point: $error");
    });
    print('object');
    String hash = userProvider.getUsernameHash().toString();
    packagesFuture = ApiService().fetchCategories(currentUserId);
  }
  void fetchUserPoints() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    ApiService().fetchUserPoint(currentUserId).then((userPoint) {
      setState(() {
        _userPoint = userPoint;
      });
    }).catchError((error) {
      print("Error fetching user point: $error");
    });
  }


  void speak(String text) async {
    await flutterTts.setLanguage('en-US'); // Seslendirme dilini ayarla
    await flutterTts.setSpeechRate(0.5); // Konuşma hızını ayarla
    await flutterTts.setVolume(1.0); // Ses seviyesini ayarla
    await flutterTts.setPitch(1.0); // Ses tonunu ayarla

    await flutterTts.speak(text); // Metni ses olarak çal
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildUserInfoSection(userProvider)),
            Expanded(child: buildGFCard((String text) => speak(text))
            ),
    Expanded(
              child: PackageListWidget(packagesFuture: ApiService().fetchCategories(userProvider.userId))
              ,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUserInfoSection(UserProvider userProvider) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30.r,
            backgroundImage: NetworkImage('https://kelibu.net/storage/${userProvider.avatar}'),
            backgroundColor: Colors.grey[300],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoşgeldiniz, ${userProvider.username}',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Puanınız: ${userProvider.point}',
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black54, size: 24.sp),
            onPressed: () {
              // Bildirim butonu işlevi
            },
          ),
        ],
      ),
    );
  }
  Widget _buildPackageList() {
    return FutureBuilder<List<Package>>(
      future: packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerEffect();
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          var packages = snapshot.data!;
          var visiblePackages = packages;

          if (!_showMore && packages.length > 2) {
            visiblePackages = packages.sublist(0, 2);
          }

          return SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width, // Tüm ekran genişliğini kullan
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.1, // Sol taraftan %10 boşluk bırak
                  right: MediaQuery.of(context).size.width * 0.1, // Sağ taraftan %10 boşluk bırak
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // İçerikleri sol tarafa hizala
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: Text(
                            "Kelime Setleri",
                            style: GoogleFonts.nunito(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        ...visiblePackages.map((package) => _buildListItem(package)).toList(),
                      ],
                    ),
                    Positioned(
                      top: 0, // En üst
                      right: 0, // En sol
                      child: IconButton(
                        icon: Icon(_showMore ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            _showMore = !_showMore;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  "Kelime Setleri",
                  style: GoogleFonts.nunito(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              Text("Kategori verisi yok", style: TextStyle(fontSize: 16)),
            ],
          );
        }
      },
    );
  }

  Widget _buildListItem(Package package) {
    // Bu fonksiyon, verilen paket için bir liste öğesi widget'ı oluşturur.
    return InkWell(
      onTap: () => _onListItemTap(context, package.classroom?.id ?? 0, package.classroom?.title ?? 'Varsayılan Başlık'),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Text(
            package.classroom?.title ?? 'Varsayılan Başlık',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  Widget buildGFCard(Function(String) onSpeak) { // Callback parametresi ekleme
    return FutureBuilder<WordOfTheDay>(
      future: fetchWordOfTheDay(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // LogoLoadingIndicator tanımınız burada olmalı.
          return CircularProgressIndicator(); // Yer tutucu olarak kullanıldı.
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: GFCard(
              boxFit: BoxFit.cover,
              content: Padding(
                padding: EdgeInsets.all(8.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (snapshot.hasData) {
                              onSpeak(snapshot.data!.term); // Callback'i çağırma
                            }
                          },
                          child: GFAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.volume_up, color: Colors.white, size: 12.sp),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                'Günün Kelimesi',
                                style: GoogleFonts.nunito(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                                maxLines: 1,
                                minFontSize: 10,
                              ),
                              AutoSizeText(
                                snapshot.data?.term ?? '',
                                style: GoogleFonts.nunito(
                                  fontSize: 14.sp,
                                  color: Colors.redAccent,
                                ),
                                maxLines: 1,
                                minFontSize: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AutoSizeText(
                      snapshot.data?.definition ?? '',
                      style: GoogleFonts.nunito(fontSize: 12.sp, color: Colors.black87),
                      maxLines: 3,
                      minFontSize: 6,
                    ),
                    AutoSizeText(
                      snapshot.data?.type ?? 'Tip bilgisi verilmemiştir',
                      style: GoogleFonts.nunito(fontSize: 12.sp, color: Colors.black54),
                      maxLines: 1,
                      minFontSize: 6,
                    ),
                  ],
                ),
              ),
              borderRadius: BorderRadius.all(Radius.circular(12.r)),
            ),
          );
        }
      },
    );
  }

  void _onListItemTap(BuildContext context, int categoryId, String categoryName) async {
    // Öğeye dokunulduğunda animasyonlu grileşme efekti
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yükleniyor...'),
        duration: Duration(milliseconds: 5),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
    // İsteğe bağlı olarak ek işlevsellikler eklenebilir
  }

  Widget _buildShimmerEffect() {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(color: Colors.grey),
                        child: SizedBox(width: double.infinity, height: 10),
                      ),
                      SizedBox(height: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(color: Colors.grey),
                        child: SizedBox(width: double.infinity, height: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

class WordCard {
  final int id;
  final String? type; // type alanını nullable yaptık
  final String terim;
  final String tanim;

  WordCard({
    required this.id,
    this.type, // required kaldırıldı çünkü nullable
    required this.terim,
    required this.tanim,
  });

  // JSON'dan bir WordCard örneği oluşturmak için fabrika yapıcı.
  factory WordCard.fromJson(Map<String, dynamic> json) {
    return WordCard(
      id: json['id'],
      type: json['type'], // JSON'dan gelen type null olabilir
      terim: json['terim'],
      tanim: json['tanim'],
    );
  }
}




class PackageListWidget extends StatefulWidget {
  final Future<List<Package>> packagesFuture;

  const PackageListWidget({Key? key, required this.packagesFuture}) : super(key: key);

  @override
  _PackageListWidgetState createState() => _PackageListWidgetState();
}

class _PackageListWidgetState extends State<PackageListWidget> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Package>>(
      future: widget.packagesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerEffect();
        } else if (snapshot.hasError) {
          return Center(child: Text("Hata: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          var packages = snapshot.data!;
          var visiblePackages = packages;

          if (!_showMore && packages.length > 2) {
            visiblePackages = packages.sublist(0, 2);
          }

          return SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.1,
                  right: MediaQuery.of(context).size.width * 0.1,
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: Text(
                            "Kelime Setleri",
                            style: GoogleFonts.nunito(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        ...visiblePackages.map((package) => _buildListItem(package)).toList(),
                      ],
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(_showMore ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                        onPressed: () {
                          setState(() {
                            _showMore = !_showMore;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  "Kelime Setleri",
                  style: GoogleFonts.nunito(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              Text("Kategori verisi yok", style: TextStyle(fontSize: 16)),
            ],
          );
        }
      },
    );
  }

  Widget _buildListItem(Package package) {
    // Bu fonksiyon, verilen paket için bir liste öğesi widget'ı oluşturur.
    return InkWell(
      onTap: () => _onListItemTap(context, package.classroom?.id ?? 0, package.classroom?.title ?? 'Varsayılan Başlık'),
      child: Card(
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Daha oval kenarlar için
        ),
        color: Colors.lightBlueAccent.shade100, // Açık pembe arka plan rengi
        child: ListTile(
          leading: CircleAvatar(
            // Sol taraftaki asset logo
            backgroundColor: Colors.transparent, // Logo arka planı şeffaf
            child: Image.asset('assets/logo.png'), // Asset yolunuzu buraya girin
          ),
          title: Text(
            package.classroom?.title ?? 'Varsayılan Başlık',
            style: GoogleFonts.poppins(
              color: Colors.white, // Beyaz metin rengi
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  void _onListItemTap(BuildContext context, int categoryId, String categoryName) async {
    // Öğeye dokunulduğunda animasyonlu grileşme efekti
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yükleniyor...'),
        duration: Duration(milliseconds: 5),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 500));

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
    // İsteğe bağlı olarak ek işlevsellikler eklenebilir
  }

  Widget _buildShimmerEffect() {
    // Shimmer efekti için yer tutucu widget
    return Container(); // Örnek amaçlı boş bir container dönüyoruz.
  }
}
