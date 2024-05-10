import 'dart:math';

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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/Models/user.dart';
import 'package:getwidget/getwidget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> with SingleTickerProviderStateMixin {
  late Future<List<User>> _futureLeaderboardData;
  late TabController _tabController;
  int? userRank;
  User? currentUser;
  final ScrollController _scrollController = ScrollController();
  bool _isUserRankComputed = false;
  String? _code;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadData('all_time'); // default period
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString('leaderboard_code');
    if (_code != null) {
      setState(() {});
      _loadData(_code!);
    }
  }

  void _setCode(String newCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('leaderboard_code', newCode);
    _code = newCode;
    _loadData(_code!);
  }

  void _removeCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leaderboard_code');
    _code = null;
    _loadData('all_time');
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      switch (_tabController.index) {
        case 0:
          _loadData('all_time');
          break;
        case 1:
          _loadData('daily');
          break;
        case 2:
          _loadData('weekly');
          break;
        case 3:
          _loadData('monthly');
          break;
      }
    }
  }

  void _loadData(String timePeriod) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    _futureLeaderboardData = ApiService().fetchUsersNew(_code ?? "", timePeriod);
    List<User> users = await _futureLeaderboardData;
    int currentUserIndex = users.indexWhere((user) => user.id == currentUserId);

    if (currentUserIndex != -1 && currentUserIndex < 150) {
      userRank = currentUserIndex + 1;
    } else {
      userRank = null; // User not found in the current period's leaderboard
    }
    _isUserRankComputed = true;

    if (mounted) {
      setState(() {});
      if (userRank != null) {
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
        backgroundColor: const Color(0xFFFEFAF6),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFEFAF6),
          title: Text(
            'Liderlik Tablosu',
            style: GoogleFonts.poppins(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Tümü'),
              Tab(text: 'Günlük'),
              Tab(text: 'Haftalık'),
              Tab(text: 'Ay'),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _code == null ? () async {
                TextEditingController codeController = TextEditingController();
                bool shouldRefresh = await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Enter Code"),
                      content: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(hintText: "Code"),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (codeController.text.isNotEmpty) {
                              _setCode(codeController.text);
                              Navigator.of(context).pop(true);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                );
                if (shouldRefresh) {
                  _loadData(_code!);
                }
              } : null,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            LeaderboardList(timePeriod: 'all_time', code: _code),
            LeaderboardList(timePeriod: 'daily', code: _code),
            LeaderboardList(timePeriod: 'weekly', code: _code),
            LeaderboardList(timePeriod: 'monthly', code: _code),
          ],
        ),
        bottomSheet: userRank != null && _isUserRankComputed
            ? Container(
          color: Colors.blueGrey[100],
          height: 50,
          child: Center(
            child: Text(
              'Sizin sıralamanız: #$userRank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        )
            : SizedBox.shrink(),
        floatingActionButton: _code != null
            ? FloatingActionButton(
          onPressed: _removeCode,
          tooltip: 'Remove Code',
          child: Icon(Icons.remove),
        )
            : null,
      ),
    );
  }

  void scrollToUserRank(int index) async {
    if (userRank == null) return; // No rank to scroll to

    await Future.delayed(const Duration(milliseconds: 100));

    if (_scrollController.hasClients) {
      var itemPositionOffset = 104.0 * index;
      var screenHeight = MediaQuery.of(context).size.height;
      var centeredPositionOffset = itemPositionOffset - (screenHeight / 2) + (104.0 / 2);
      final offset = max(centeredPositionOffset, 0.0);

      _scrollController.animateTo(
        offset,
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
      );
    }
  }
}


class LeaderboardList extends StatelessWidget {
  final String timePeriod;
  final String? code;

  const LeaderboardList({Key? key, required this.timePeriod, this.code}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<List<User>> users = ApiService().fetchUsersNew(code ?? "", timePeriod);

    return FutureBuilder<List<User>>(
      future: users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: const LogoLoadingIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available');
        } else {
          return AnimationLimiter(
            child: ListView.builder(
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
    );
  }

  Widget _buildUserTile(User user, int rank) {
    Color backgroundColor = _getBackgroundColorForRank(rank);

    Widget rankIndicator = _getRankIndicator(rank);

    String teamInfo = user.team == null || user.team!.isEmpty ? "Bilgi Verilmemiştir." : user.team!;
    String cityInfo = user.city ?? "Şehir Bilinmiyor";

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
        '${user.point} Points',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        minFontSize: 12,
        maxLines: 1,
      ),
      color: backgroundColor,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal:16),
    );
  }

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

  Widget _getRankIndicator(int rank) {
    if (rank <= 3) {
      return Icon(
        Icons.emoji_events,
        color: rank == 1 ? Colors.yellow : rank == 2 ? Colors.grey : Colors.brown,
        size: 16,
      );
    } else {
      return Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: Colors.pink,
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