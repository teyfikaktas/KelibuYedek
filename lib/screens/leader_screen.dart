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
import '../variables.dart';
import 'loadingIndicator.dart';

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
  bool _isGroupMode = false; // To toggle between group and general leaderboard
  bool _isGroupSettingsVisible = false; // To toggle visibility of group settings
  final TextEditingController _groupCodeController = TextEditingController(); // Controller for the group code text field
  bool _showGroupSettingsHint = false; // To control the visibility of the hint pop-up
  bool _isGroupEmpty = false; // To check if group is empty
  bool _isDarkMode = false; // To control dark mode

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadData('all_time');
    _initPreferences();
    _checkFirstTime();
    _loadDarkModePreference(); // Load dark mode preference
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString('leaderboard_code');
    if (_code != null) {
      setState(() {
        _isGroupMode = true;
      });
      _loadData(_code!);
    }
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    bool? isFirstTime = prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      setState(() {
        _showGroupSettingsHint = true;
      });
      await prefs.setBool('isFirstTime', false);
    }
  }

  void _setCode(String newCode) async {
    final prefs = await SharedPreferences.getInstance();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final response = await ApiService().joinGroup(newCode, userProvider.userId.toString());

    if (response['success']) {
      await prefs.setString('leaderboard_code', newCode);
      setState(() {
        _code = newCode;
        _isGroupMode = true;
      });
      _loadData(newCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message']),
      ));
    }
  }

  void _removeCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leaderboard_code');
    setState(() {
      _code = null;
      _isGroupMode = false;
    });
    _loadData('all_time');
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      String selectedPeriod = 'all_time';
      switch (_tabController.index) {
        case 0:
          selectedPeriod = 'all_time';
          break;
        case 1:
          selectedPeriod = 'daily';
          break;
        case 2:
          selectedPeriod = 'weekly';
          break;
        case 3:
          selectedPeriod = 'monthly';
          break;
      }
      _loadData(selectedPeriod);
    }
  }

  void _loadData(String timePeriod) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    _futureLeaderboardData = ApiService().fetchUsersNew(_isGroupMode ? (_code ?? "") : "", timePeriod);
    List<User> users = await _futureLeaderboardData;

    if (_isGroupMode && (_code == null || users.isEmpty)) {
      setState(() {
        _isGroupEmpty = true;
      });
    } else {
      setState(() {
        _isGroupEmpty = false;
      });
    }

    int currentUserIndex = users.indexWhere((user) => user.id == currentUserId);

    if (currentUserIndex != -1 && currentUserIndex < 150) {
      userRank = currentUserIndex + 1;
      _isUserRankComputed = true;
      if (mounted) {
        setState(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToUserRank(currentUserIndex);
          });
        });
      }
    } else {
      userRank = null;
    }
  }

  void scrollToUserRank(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userRank == null || !_scrollController.hasClients || index >= 50) {
        return;
      }
      var itemPositionOffset = 104.0 * index;
      var screenHeight = MediaQuery.of(context).size.height;
      var centeredPositionOffset = itemPositionOffset - (screenHeight / 2) + (104.0 / 2);
      final offset = max(centeredPositionOffset, 0.0);
      _scrollController.animateTo(
        offset,
        duration: const Duration(seconds: 3),
        curve: Curves.easeOutQuad,
      );
    });
  }

  void _dismissHint() {
    setState(() {
      _showGroupSettingsHint = false;
    });
  }

  void _toggleGroupMode(bool isGroupMode) async {
    setState(() {
      _isGroupMode = isGroupMode;
    });
    _loadData('all_time');
  }

  Future<void> _toggleDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", isDarkMode);
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return SafeArea(
      child: Scaffold(
        backgroundColor: colors["background"],
        appBar: AppBar(
          backgroundColor: colors["background"],
          title: Text(
            'Liderlik Tablosu',
            style: GoogleFonts.poppins(
              color: colors["text"],
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: colors["text"],
            unselectedLabelColor: colors["unselectedText"],
            tabs: const [
              Tab(text: 'Tümü'),
              Tab(text: 'Günlük'),
              Tab(text: 'Haftalık'),
              Tab(text: 'Ay'),
            ],
          ),
          actions: [
            Switch(
              value: _isGroupMode,
              onChanged: (value) {
                _toggleGroupMode(value);
              },
              activeColor: Colors.pink,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[300],
            ),
            Text(
              _isGroupMode ? 'Grup' : 'Genel',
              style: TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.group, color: Colors.pink),
              onPressed: () {
                setState(() {
                  _isGroupSettingsVisible = !_isGroupSettingsVisible;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_isGroupSettingsVisible)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _groupCodeController,
                                decoration: InputDecoration(
                                  labelText: 'Grup Kodu',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  filled: true,
                                  fillColor: colors["inputBackground"],
                                  prefixIcon: Icon(Icons.group, color: Colors.pink),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.pink, // Background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (_groupCodeController.text.isNotEmpty) {
                                  _setCode(_groupCodeController.text);
                                }
                              },
                              child: Text(
                                'Gruba Katıl',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            if (_code != null)
                              IconButton(
                                icon: Icon(Icons.clear, color: Colors.red),
                                onPressed: _removeCode,
                              ),
                          ],
                        ),
                        if (_code != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Bir gruptasınız: $_code',
                              style: TextStyle(
                                color: colors["text"],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_code != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.red, // Background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _removeCode,
                              child: Text(
                                'Gruptan Ayrıl',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      LeaderboardList(timePeriod: 'all_time', code: _isGroupMode ? _code : "", scrollController: _scrollController, isDarkMode: _isDarkMode),
                      LeaderboardList(timePeriod: 'daily', code: _isGroupMode ? _code : "", scrollController: _scrollController, isDarkMode: _isDarkMode),
                      LeaderboardList(timePeriod: 'weekly', code: _isGroupMode ? _code : "", scrollController: _scrollController, isDarkMode: _isDarkMode),
                      LeaderboardList(timePeriod: 'monthly', code: _isGroupMode ? _code : "", scrollController: _scrollController, isDarkMode: _isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
            if (_isGroupEmpty)
              Center(
                child: Text(
                  'Grubunuz bulunmamaktadır, lütfen bir grup ekleyin.',
                  style: TextStyle(color: colors["text"], fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            if (_showGroupSettingsHint)
              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: GestureDetector(
                  onTap: _dismissHint,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Grup sağ köşedeki grup simgesine tıklayarak yapabilirsiniz.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomSheet: userRank != null && _isUserRankComputed
            ? Container(
          color: colors["bottomSheetBackground"],
          height: 50,
          child: Center(
            child: Text(
              'Sizin sıralamanız: #$userRank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: colors["bottomSheetText"],
              ),
            ),
          ),
        )
            : SizedBox.shrink(),
      ),
    );
  }
}

class LeaderboardList extends StatelessWidget {
  final String timePeriod;
  final String? code;
  final ScrollController scrollController;
  final bool isDarkMode;

  const LeaderboardList({Key? key, required this.timePeriod, this.code, required this.scrollController, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = isDarkMode ? darkModeColors : lightModeColors;
    Future<List<User>> users = ApiService().fetchUsersNew(code ?? "", timePeriod);

    return FutureBuilder<List<User>>(
      future: users,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: const LogoLoadingIndicator());
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No data available', style: TextStyle(color: Colors.grey));
        } else {
          return AnimationLimiter(
            child: ListView.builder(
              controller: scrollController,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildUserTile(snapshot.data![index], index + 1, colors, isDarkMode),
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

  Widget _buildUserTile(User user, int rank, Map<String, Color> colors, bool isDarkMode) {
    Color? backgroundColor = _getBackgroundColorForRank(rank, colors, isDarkMode);

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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: (rank <= 3 && isDarkMode) ? Colors.black : colors["text"],
              ),
              minFontSize: 10,
              maxLines: 1,
            ),
          ),
          AutoSizeText(
            '$cityInfo, $teamInfo',
            style: TextStyle(
              fontSize: 12,
              color: (rank <= 3 && isDarkMode) ? Colors.black : colors["text"],
            ),
            minFontSize: 10,
            maxLines: 1,
          ),
        ],
      ),
      subTitle: AutoSizeText(
        '${user.point} Points',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: (rank <= 3 && isDarkMode) ? Colors.black : colors["text"],
        ),
        minFontSize: 12,
        maxLines: 1,
      ),
      color: backgroundColor,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    );
  }

  Color? _getBackgroundColorForRank(int rank, Map<String, Color> colors, bool isDarkMode) {
    if (isDarkMode) {
      switch (rank) {
        case 1:
          return Colors.yellow[800]!;
        case 2:
          return Colors.grey[800]!;
        case 3:
          return Colors.brown[800]!;
        default:
          return colors["background"];
      }
    } else {
      switch (rank) {
        case 1:
          return Colors.yellow[100]!;
        case 2:
          return Colors.grey[100]!;
        case 3:
          return Colors.brown[100]!;
        default:
          return colors["background"];
      }
    }
  }

  Widget _getRankIndicator(int rank) {
    if (rank <= 3) {
      return Icon(
        Icons.emoji_events,
        color: rank == 1 ? Colors.yellow : rank == 2 ? Colors.grey : rank == 3 ? Colors.brown : Colors.black,
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
