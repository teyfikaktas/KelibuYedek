import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/category.dart';
import '../providers/user_provider.dart';
import 'flashy_tab_bar2.dart'; // FlashyTabBar dosyanızın yolu
import 'package:kelibu/api.dart'; // ApiService dosyanızın yolu
import 'package:kelibu/screens/WordListScreen.dart';
// Add path_provider package
import 'package:google_fonts/google_fonts.dart'; // Google Fonts'u import edin
import 'package:shimmer/shimmer.dart';
import 'dart:math';
import '../screens/leader_screen.dart';

class MyListItem extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const MyListItem({super.key, required this.title, required this.onTap});

  @override
  _MyListItemState createState() => _MyListItemState();
}

class _MyListItemState extends State<MyListItem> {
  Color _color = Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _color = Colors.grey;
        });
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: _color,
        child: ListTile(
          title: Text(
            widget.title,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
Widget _buildWordOfTheDaySection() {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.0),
    ),
    elevation: 5,
    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günün Kelimesi',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                'RED',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kırmızı',
            style: GoogleFonts.nunito(fontSize: 16),
          ),
          Text(
            'Sıfat',
            style: GoogleFonts.nunito(fontSize: 16),
          ),
        ],
      ),
    ),
  );
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
  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  void _fetchData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;
    print(currentUserId);

    // Kullanıcı puanını al
    ApiService().fetchUserPoint(currentUserId).then((userPoint) {
      setState(() {
        _userPoint = userPoint;
        print('userPoint: $_userPoint');
      });
    }).catchError((error) {
      print("Error fetching user point: $error");
    });

    // Kategorileri al
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
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
      body: SafeArea(
        child: Column(
          children: [
            _buildUserInfoSection(userProvider),
            _buildWordOfTheDaySection(),
            Expanded(
              child: _buildPackageList(),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUserInfoSection(UserProvider userProvider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white, // Arka plan rengini ayarlayın
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://kelibu.net/storage/${userProvider.avatar}'),
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoşgeldiniz, ${userProvider.username}',
                  style: GoogleFonts.nunito(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Puan: $_userPoint',
                  style: GoogleFonts.nunito(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
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
        } else if (snapshot.hasData) {
          double itemCount = snapshot.data!.length.toDouble();
          double containerHeight = min(itemCount * 60.0 + 60.0, MediaQuery.of(context).size.height * 0.30);

          return Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              height: containerHeight,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: Text(
                      "Kelime Setleri",
                      style: GoogleFonts.nunito(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildListView(snapshot.data!),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: Text("Kategori verisi yok"));
        }
      },
    );
  }
  Widget _buildListView(List<Package> packages) {
    return ListView.builder(
      itemCount: packages.length,
      itemBuilder: (context, index) {
        var package = packages[index];
        String title = package.classroom?.title ?? 'Varsayılan Başlık';

        return InkWell(
          onTap: () {
            // Öğeye tıklandığında yapılacak işlevsellik
            _onListItemTap(context, package.classroom?.id ?? 0, title);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        );
      },
    );
  }

  void _onListItemTap(BuildContext context, int categoryId, String categoryName) async {
    // Öğeye dokunulduğunda animasyonlu grileşme efekti
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yükleniyor...'),
        duration: Duration(milliseconds: 500),
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
  Widget _buildBottomNavigationBar() {
    return FlashyTabBar(
      selectedIndex: _selectedIndex,
      showElevation: true,
      backgroundColor: Colors.deepPurple, // Modern bir arka plan rengi
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        _onItemSelected(index, context);
      },
      items: [
        FlashyTabBarItem(
          icon: const Icon(Icons.home, color: Colors.white),
          title: Text('Ana Sayfa', style: GoogleFonts.nunito(color: Colors.white)),
        ),
        // Diğer tablar...
        FlashyTabBarItem(
          icon: const Icon(Icons.leaderboard, color: Colors.white),
          title: Text('Liderlik', style: GoogleFonts.nunito(color: Colors.white)),
        ),
        // Diğer tablar...
      ],
    );
  }
  }
