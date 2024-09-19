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
  int _selectedTabIndex = 0;
  int? userRank;
  final ScrollController _scrollController = ScrollController();
  bool _isUserRankComputed = false;
  String? _code;
  bool _isGroupMode = false;
  bool _isDarkMode = false;
  bool _hasGroup = false;

  @override
  void initState() {
    super.initState();
    _loadData('all_time');
    _initPreferences();
    _loadDarkModePreference();
  }

  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString('leaderboard_code');
    if (_code != null && _code!.isNotEmpty) {
      setState(() {
        _isGroupMode = true;
        _hasGroup = true;
      });
      _loadData(_code!);
    } else {
      setState(() {
        _isGroupMode = false;
        _hasGroup = false;
      });
    }
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
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
        _hasGroup = true;
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
      _hasGroup = false;
    });
    _loadData('all_time');
  }

  void _loadData(String timePeriod) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    List<User> users = await ApiService().fetchUsersNew(_isGroupMode ? (_code ?? "") : "", timePeriod);

    users.sort((a, b) => b.point.compareTo(a.point));

    int currentUserIndex = users.indexWhere((user) => user.id == currentUserId);

    setState(() {
      if (currentUserIndex != -1) {
        userRank = currentUserIndex + 1;
        _isUserRankComputed = true;
      } else {
        userRank = null;
        _isUserRankComputed = false;
      }
    });

    if (_isUserRankComputed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToUserRank(currentUserIndex);
      });
    }
  }

  void scrollToUserRank(int index) {
    if (userRank == null || !_scrollController.hasClients || index >= 50) {
      return;
    }
    var itemPositionOffset = 104.0 * index;
    var screenHeight = MediaQuery.of(context).size.height;
    var centeredPositionOffset = itemPositionOffset - (screenHeight / 2) + (104.0 / 2);
    final offset = max(centeredPositionOffset, 0.0);
    _scrollController.animateTo(
      offset,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOutQuad,
    );
  }


  void _toggleGroupMode(bool isGroupMode) {
    setState(() {
      _isGroupMode = isGroupMode && _hasGroup;
    });
    _loadData(_isGroupMode ? (_code ?? '') : 'all_time');
    _updateUserRank();
  }
  void _updateUserRank() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;
    List<User> users = await ApiService().fetchUsersNew(_isGroupMode ? (_code ?? "") : "", _getTimePeriodForIndex(_selectedTabIndex));

    users.sort((a, b) => b.point.compareTo(a.point));

    int currentUserIndex = users.indexWhere((user) => user.id == currentUserId);

    setState(() {
      if (currentUserIndex != -1) {
        userRank = currentUserIndex + 1;
        _isUserRankComputed = true;
      } else {
        userRank = null;
        _isUserRankComputed = false;
      }
    });

    if (_isUserRankComputed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToUserRank(currentUserIndex);
      });
    }
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
        hasGroup: _hasGroup,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: _isDarkMode ? Color(0xFF1F1F1F) : colors["background"],
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Color(0xFF2C2C2C) : colors["background"],
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.school,
              color: Color(0xFF58CC02),
              size: 32,
            ),
            SizedBox(width: 8),
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Liderlik Tablosu',
              style: GoogleFonts.poppins(
                color: colors["text"],
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        centerTitle: false,
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
            icon: Icon(Icons.slow_motion_video, color: colors["text"]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.leaderscreen)),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(2.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, colors["cardBorder"]!, Colors.transparent],
              ),
            ),
            height: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCustomTabs(),
          if (!_hasGroup)
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF4D4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFFD580)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFF9600)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Grubunuz yok. Grup ayarlarından bir gruba katılabilirsiniz.',
                      style: TextStyle(color: Color(0xFFFF9600)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LeaderboardList(
              timePeriod: _getTimePeriodForIndex(_selectedTabIndex),
              code: _isGroupMode ? _code : "",
              scrollController: _scrollController,
              isDarkMode: _isDarkMode,
            ),
          ),
        ],
      ),
      bottomSheet: _buildUserRankBottomSheet(colors),
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      height: 50,
      color: _isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
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
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        _loadData(_getTimePeriodForIndex(index));
        _updateUserRank();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF58CC02) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : colors["text"],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  String _getTimePeriodForIndex(int index) {
    switch (index) {
      case 0: return 'all_time';
      case 1: return 'daily';
      case 2: return 'weekly';
      case 3: return 'monthly';
      default: return 'all_time';
    }
  }

  Widget _buildUserRankBottomSheet(Map<String, Color> colors) {
    return Container(
      color: Color(0xFF58CC02),
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
                  child: AutoSizeText(
                    userRank != null && _isUserRankComputed
                        ? 'Tebrikler! ${_isGroupMode ? "Grup" : "Genel"} Sıralamanız: #$userRank'
                        : 'Henüz sıralamada değilsiniz. Çalışmaya devam edin!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 12,
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
    return Container(
      color: isDarkMode ? Color(0xFF1F1F1F) : colors["background"],
      child: FutureBuilder<List<User>>(
        future: ApiService().fetchUsersNew(code ?? "", timePeriod),
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
            final sortedUsers = snapshot.data!..sort((a, b) => b.point.compareTo(a.point));
            return AnimationLimiter(
              child: ListView.builder(
                controller: scrollController,
                itemCount: sortedUsers.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _buildUserTile(context, sortedUsers[index], index + 1, colors),
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, User user, int rank, Map<String, Color> colors) {
    final isTopThree = rank <= 3;
    final backgroundColor = isTopThree
        ? _getBackgroundColorForRank(rank, isDarkMode)
        : isDarkMode ? Colors.grey[900] : colors["cardBackground"];
    final textColor = isTopThree && !isDarkMode ? Colors.white : colors["text"]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildLeadingWidget(context, rank, user),
        title: AutoSizeText(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          minFontSize: 14,
          maxFontSize: 16,
        ),
        subtitle: AutoSizeText(
          '${user.city ?? "Şehir Bilinmiyor"} • ${user.team ?? "Takım Bilinmiyor"}',
          style: TextStyle(
            color: textColor.withOpacity(0.7),
          ),
          maxLines: 1,
          minFontSize: 10,
          maxFontSize: 12,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoSizeText(
              '${user.point}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 1,
              minFontSize: 14,
              maxFontSize: 18,
            ),
            SizedBox(height: 4),
            AutoSizeText(
              '#$rank',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              minFontSize: 10,
              maxFontSize: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(BuildContext context, int rank, User user) {
    return GestureDetector(
      onTap: () => _showEnlargedImage(context, user),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://kelibu.net/storage/${user.avatar}'),
          ),
          if (rank <= 3)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getMedalColor(rank),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  _getMedalIcon(rank),
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
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
        );
      },
    );
  }


  Color _getBackgroundColorForRank(int rank, bool isDarkMode) {
    if (isDarkMode) {
      switch (rank) {
        case 1: return Colors.amber.shade900;
        case 2: return Colors.blueGrey.shade900;
        case 3: return Colors.brown.shade900;
        default: return Colors.grey.shade900;
      }
    } else {
      switch (rank) {
        case 1: return Colors.amber.shade500;
        case 2: return Colors.blueGrey.shade500;
        case 3: return Colors.brown.shade500;
        default: return Colors.white;
      }
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.blueGrey;
      case 3: return Colors.brown;
      default: return Colors.grey;
    }
  }

  IconData _getMedalIcon(int rank) {
    switch (rank) {
      case 1: return Icons.looks_one;
      case 2: return Icons.looks_two;
      case 3: return Icons.looks_3;
      default: return Icons.emoji_events;
    }
  }
}

class GroupSettingsPanel extends StatefulWidget {
  final String? currentCode;
  final Function(String) onJoinGroup;
  final Function() onLeaveGroup;
  final bool hasGroup;

  const GroupSettingsPanel({
    Key? key,
    this.currentCode,
    required this.onJoinGroup,
    required this.onLeaveGroup,
    required this.hasGroup,
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
              widget.hasGroup ? 'Grubu Güncelle' : 'Gruba Katıl',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Color(0xFF58CC02),
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
          if (widget.hasGroup) ...[
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