import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/Models/user.dart';
import 'package:getwidget/getwidget.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'loadingIndicator.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<User>> _futureLeaderboardData;
  int? userRank;
  User? currentUser;
  final ScrollController _scrollController = ScrollController();
  bool _isUserRankComputed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    _futureLeaderboardData = ApiService().fetchUsers();
    List<User> users = await _futureLeaderboardData;
    int currentUserIndex = users.indexWhere((user) => user.id == currentUserId);

    if (currentUserIndex != -1 && currentUserIndex < 150) {
      userRank = currentUserIndex + 1;
    }
    _isUserRankComputed = true;

    if (mounted) {
      setState(() {});
      if (userRank != null) {
        // Delay the scroll to ensure the ListView is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToUserRank(currentUserIndex);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
        appBar: AppBar(
          backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
          title: Text(
            'Liderlik Tablosu',
            style: GoogleFonts.poppins(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(
            color: Colors.pink,
          ),
        ),
        body: FutureBuilder<List<User>>(
          future: _futureLeaderboardData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: const LogoLoadingIndicator(), // Merkeze alınmış LogoLoadingIndicator
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Yeterli veri yok');
            } else {
              // Potential place to initiate scrolling after data is loaded
              if (!_isUserRankComputed && userRank != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollToUserRank(userRank! - 1);
                });
              }
              return AnimationLimiter(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildUserTile(snapshot.data![index], index + 1),
                        ),
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
        bottomSheet: _isUserRankComputed
            ? Container(
          decoration: BoxDecoration(
            color: Colors.pink.shade100, // Gradyan yerine katı bir pembe renk kullan
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20)
            ),
            boxShadow: const [
              BoxShadow(
                spreadRadius: 0,
                blurRadius: 10,
                offset: Offset(0, -2), // Gölgelerin yönünü ayarlayın
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // İçerik ve logo arasında boşluk bırakmak için
            children: [
              Row( // Sıralama ve ikonu sol tarafta tutacak iç içe Row
                children: [
                  const Icon(Icons.leaderboard, color: Colors.white70),
                  const SizedBox(width: 10),
                  Text(
                    userRank != null && userRank! <= 150 ? 'Sizin Sıralamanız: #$userRank' : 'İlk 150 kişi içerisinde değilsiniz',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              // Sağ tarafta logo gösterimi
              Image.asset('assets/logo.png', width: 50), // Logo burada, boyutunu ayarlayabilirsiniz
            ],
          ),
        )
            : const SizedBox.shrink(),

      ),
    );
  }

  void scrollToUserRank(int index) async {
    await Future.delayed(Duration(milliseconds: 100)); // Ensure ListView is built

    if (_scrollController.hasClients) {
      // Ensure the calculation results in a double
      var itemPositionOffset = (100.0 + 4.0) * index; // Making 100.0 and 8.0 explicitly double

      // Get the height of the screen as a double
      var screenHeight = MediaQuery.of(context).size.height;

      // Calculate the offset to center the user's rank in the screen, ensuring the result is a double
      var centeredPositionOffset = itemPositionOffset - (screenHeight / 2) + (100.0 / 2); // Adjust the 100.0 if your item height is different

      // Ensure the calculated offset is not negative and explicitly cast to double if necessary
      final offset = centeredPositionOffset > 0 ? centeredPositionOffset : 0.0;

      _scrollController.animateTo(
        offset,
        duration: Duration(seconds: 2),
        curve: Curves.easeInOut,
      );
    }
  }


  Widget _buildUserTile(User user, int rank) {
    Color backgroundColor = _getBackgroundColorForRank(rank);

    // Determines the appropriate rank indicator based on rank
    Widget rankIndicator = _getRankIndicator(rank);

    String teamInfo = user.team == null || user.team!.isEmpty ? "Takım seçilmemiştir" : user.team!;
    String cityInfo = user.city ?? "İl belirsiz";

    return GFListTile(
      avatar: Stack(
        children: [
          GFAvatar(
            backgroundImage: NetworkImage('https://kelibu.net/storage/${user.avatar}'),
            shape: GFAvatarShape.circle,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: rankIndicator,
          ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AutoSizeText(
              user.name,
              style: TextStyle(fontWeight: FontWeight.bold),
              minFontSize: 10,
              maxLines: 1,
            ),
          ),
          AutoSizeText(
            '$cityInfo, $teamInfo',
            style: TextStyle(fontSize: 12),
            minFontSize: 10,
            maxLines: 1,
          ),
        ],
      ),
      subTitle: AutoSizeText(
        '${user.point} Puan',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        minFontSize: 12,
        maxLines: 1,
      ),
      color: backgroundColor,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  // Helper function to determine the background color based on rank
  Color _getBackgroundColorForRank(int rank) {
    switch (rank) {
      case 1:
        return Colors.yellow[100]!;
      case 2:
        return Colors.grey[100]!;
      case 3:
        return Colors.brown[100]!;
      default:
        return Colors.white;
    }
  }

  // Helper function to create a rank indicator widget
  Widget _getRankIndicator(int rank) {
    if (rank <= 3) {
      return Icon(
        Icons.emoji_events,
        color: rank == 1 ? Colors.yellow : rank == 2 ? Colors.grey : Colors.brown,
        size: 16,
      );
    } else {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }
  }
}
