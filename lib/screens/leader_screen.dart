import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/Models/user.dart';
import 'package:getwidget/getwidget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globalDart/urls.dart';
import '../variables.dart';
import 'loadingIndicator.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<User>> _futureLeaderboardData;
  int _selectedTabIndex = 0;
  int? userRank;
  User? currentUser;
  final ScrollController _scrollController = ScrollController();
  bool _isUserRankComputed = false;
  String? _code;
  bool _isGroupMode = false;
  bool _isGroupSettingsVisible = false;
  final TextEditingController _groupCodeController = TextEditingController();
  bool _showGroupSettingsHint = false;
  bool _isGroupEmpty = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadData('all_time');
    _initPreferences();
    _checkFirstTime();
    _loadDarkModePreference();
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

  void _toggleGroupMode(bool isGroupMode) async {
    setState(() {
      _isGroupMode = isGroupMode;
    });
    _loadData('all_time');
  }
  void _showGroupSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GroupSettingsPanel(
        currentCode: _code,
        onJoinGroup: _setCode,
        onLeaveGroup: _removeCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors["background"],
        elevation: 0,
        title: Text(
          'Liderlik Tablosu',
          style: GoogleFonts.poppins(
            color: colors["text"],
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isGroupMode ? Icons.group : Icons.public,
              color: colors["text"],
            ),
            onPressed: () => _toggleGroupMode(!_isGroupMode),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colors["text"]),
            onPressed: _showGroupSettingsPanel,
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: colors["text"]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.leaderscreen)),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: colors["cardBorder"],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCustomTabs(),
          Expanded(
            child: _buildLeaderboardContent(colors),
          ),
        ],
      ),
      bottomSheet: _buildUserRankBottomSheet(colors),
    );
  }
  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        primary: color,
        shape: CircleBorder(),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabItem('Tümü', 0),
          _buildTabItem('Günlük', 1),
          _buildTabItem('Haftalık', 2),
          _buildTabItem('Ay', 3),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        _loadData(_getTimePeriodForIndex(index));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _getTimePeriodForIndex(int index) {
    switch (index) {
      case 0:
        return 'all_time';
      case 1:
        return 'daily';
      case 2:
        return 'weekly';
      case 3:
        return 'monthly';
      default:
        return 'all_time';
    }
  }

  Widget _buildGroupSettings(Map<String, Color> colors) {
    return Padding(
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
                  primary: Colors.pink,
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
                  primary: Colors.red,
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
    );
  }

  Widget _buildLeaderboardContent(Map<String, Color> colors) {
    if (_isGroupMode && _isGroupEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_off,
                size: 64,
                color: colors["text"],
              ),
              SizedBox(height: 16),
              AutoSizeText(
                'Grubunuz bulunmamaktadır',
                style: TextStyle(
                  color: colors["text"],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: 14,
              ),
              SizedBox(height: 8),
              AutoSizeText(
                'Lütfen bir grup ekleyin veya oluşturun',
                style: TextStyle(
                  color: colors["text"],
                  fontSize: 16,
                ),
                maxLines: 2,
                minFontSize: 12,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LeaderboardList(
      timePeriod: _getTimePeriodForIndex(_selectedTabIndex),
      code: _isGroupMode ? _code : "",
      scrollController: _scrollController,
      isDarkMode: _isDarkMode,
    );
  }

  Widget _buildUserRankBottomSheet(Map<String, Color> colors) {
    return Container(
      color: Color(0xFF58CC02), // Duolingo'nun karakteristik yeşil rengi
      height: 70,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                userRank != null ? Icons.emoji_events : Icons.directions_run,
                color: Colors.white,
                size: 32,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    userRank != null && _isUserRankComputed
                        ? 'Tebrikler! Sıralamanız: #$userRank'
                        : 'Henüz sıralamada değilsiniz. Çalışmaya devam edin!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Icon(
                userRank != null ? Icons.celebration : Icons.emoji_objects,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaderboardList extends StatelessWidget {
  final String timePeriod;
  final String? code;
  final ScrollController scrollController;
  final bool isDarkMode;

  const LeaderboardList({
    Key? key,
    required this.timePeriod,
    this.code,
    required this.scrollController,
    required this.isDarkMode,
  }) : super(key: key);

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
          return Center(
            child: AutoSizeText(
              'Veri bulunamadı',
              style: TextStyle(color: colors["text"], fontSize: 18),
              maxLines: 1,
              minFontSize: 14,
            ),
          );
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
                      child: _buildUserTile(context, snapshot.data![index], index + 1, colors, isDarkMode),
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

  Widget _buildUserTile(BuildContext context, User user, int rank, Map<String, Color> colors, bool isDarkMode) {
    Color? backgroundColor = _getBackgroundColorForRank(rank, colors, isDarkMode);
    Color textColor = (rank <= 3 && isDarkMode) ? Colors.black : colors["text"]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              child: AutoSizeText(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                minFontSize: 14,
                maxFontSize: 18,
                maxLines: 1,
              ),
            ),
            // Avatar
            GestureDetector(
              onTap: () => _showEnlargedAvatar(context, user),
              child: Hero(
                tag: 'avatar_${user.id}',
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage('https://kelibu.net/storage/${user.avatar}'),
                ),
              ),
            ),
            SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    minFontSize: 14,
                    maxFontSize: 16,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  AutoSizeText(
                    '${user.city ?? "Şehir Bilinmiyor"}, ${user.team ?? "Bilgi Verilmemiştir."}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                    ),
                    minFontSize: 10,
                    maxFontSize: 12,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Points
            Container(
              width: 70, // Biraz daha geniş
              alignment: Alignment.centerRight,
              child: AutoSizeText(
                '${user.point}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                minFontSize: 14,
                maxFontSize: 18,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showEnlargedAvatar(BuildContext context, User user) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, _, __) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Hero(
                tag: 'avatar_${user.id}',
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage('https://kelibu.net/storage/${user.avatar}'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ));
  }

  Color? _getBackgroundColorForRank(int rank, Map<String, Color> colors, bool isDarkMode) {
    if (isDarkMode) {
      switch (rank) {
        case 1:
          return Colors.yellow[700];
        case 2:
          return Colors.grey[700];
        case 3:
          return Colors.brown[700];
        default:
          return colors["background"];
      }
    } else {
      switch (rank) {
        case 1:
          return Colors.yellow[50];
        case 2:
          return Colors.grey[50];
        case 3:
          return Colors.brown[50];
        default:
          return colors["background"];
      }
    }
  }

  Widget _getRankIndicator(int rank) {
    if (rank <= 3) {
      IconData iconData;
      Color iconColor;
      switch (rank) {
        case 1:
          iconData = Icons.looks_one;
          iconColor = Colors.yellow[700]!;
          break;
        case 2:
          iconData = Icons.looks_two;
          iconColor = Colors.grey[700]!;
          break;
        case 3:
          iconData = Icons.looks_3;
          iconColor = Colors.brown[700]!;
          break;
        default:
          iconData = Icons.emoji_events;
          iconColor = Colors.black;
      }
      return Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, size: 20, color: iconColor),
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

class GroupSettingsPanel extends StatefulWidget {
  final String? currentCode;
  final Function(String) onJoinGroup;
  final Function() onLeaveGroup;

  const GroupSettingsPanel({
    Key? key,
    this.currentCode,
    required this.onJoinGroup,
    required this.onLeaveGroup,
  }) : super(key: key);

  @override
  _GroupSettingsPanelState createState() => _GroupSettingsPanelState();
}

class _GroupSettingsPanelState extends State<GroupSettingsPanel> {
  final TextEditingController _groupCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _groupCodeController.text = widget.currentCode ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Grup Ayarları',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1CB0F6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _groupCodeController,
              decoration: InputDecoration(
                hintText: 'Grup Kodu Girin',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.group, color: Color(0xFF1CB0F6)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(fontSize: 18),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            child: Text(
              widget.currentCode != null ? 'Grubu Güncelle' : 'Gruba Katıl',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              primary: Color(0xFF58CC02),
              onPrimary: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              if (_groupCodeController.text.isNotEmpty) {
                widget.onJoinGroup(_groupCodeController.text);
                Navigator.pop(context);
              }
            },
          ),
          if (widget.currentCode != null) ...[
            SizedBox(height: 16),
            TextButton(
              child: Text(
                'Gruptan Ayrıl',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFFF4B4B),
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                widget.onLeaveGroup();
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}