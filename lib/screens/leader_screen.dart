import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/screens/home_screen.dart'; // Ana sayfa ekranı için

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<dynamic>> _futureLeaderboardData;
  int _selectedIndex = 1; // Liderlik tablosu için başlangıç indeksi olarak ayarlandı

  @override
  void initState() {
    super.initState();
    _futureLeaderboardData = ApiService().fetchUsers();
  }
  // Sayfa geçiş fonksiyonu
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
    // Diğer indeksler için ek sayfalar eklenebilir
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Liderlik Tablosu', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildPodium(context),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _futureLeaderboardData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return AnimationLimiter(
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        var item = snapshot.data![index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildListItem(context, item),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _futureLeaderboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.length < 3) {
          return const Text('Yeterli veri yok');
        } else {
          // İlk üç kullanıcıyı göster
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPodiumAvatar(context, snapshot.data![1], 2), // 2. sıra
                _buildPodiumAvatar(context, snapshot.data![0], 1), // 1. sıra
                _buildPodiumAvatar(context, snapshot.data![2], 3), // 3. sıra
              ],
            ),
          );
        }
      },
    );
  }
  Widget _buildPodiumAvatar(BuildContext context, User item, int position) {
    double size = position == 1 ? 75 : 50; // Birinci sıra için büyük boyut
    String imageUrl = 'https://kelibu.net/storage/${item.avatar}'; // Tam resim URL'si

    return CircleAvatar(
      radius: size,
      backgroundImage: NetworkImage(imageUrl), // Tam URL ile resmi yükle
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black45],
          ),
        ),
        child: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: size / 3,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, User item) {
    String imageUrl = 'https://kelibu.net/storage/${item.avatar}'; // Tam resim URL'si

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(imageUrl), // Doğrudan nesne özelliğine eriş
          ),
          title: Text(
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.deepPurple,
            ),
          ),
          subtitle: Text(
            '${item.point} Puan',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
    );
  }
}