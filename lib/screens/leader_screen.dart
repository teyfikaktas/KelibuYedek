import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/user.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/providers/user_provider.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  bool _isInstitutionMode = false;
  bool _isDarkMode = false;
  bool _hasInstitution = false;
  String? _institutionName;
  List<User>? _users;
  TextEditingController _searchController = TextEditingController();
  List<User>? _filteredUsers;
  bool _showScrollToTop = false;

  // Renk tanımlamaları
  final Map<String, Color> lightModeColors = {
    'background': Colors.white,
    'cardBackground': Colors.white,
    'text': Colors.black87,
    'selectedTab': Colors.green[400]!,
    'unselectedTab': Colors.grey,
    'textSelected': Colors.white,
    'textUnselected': Colors.green[400]!,
  };

  final Map<String, Color> darkModeColors = {
    'background': Color(0xFF121212),
    'cardBackground': Color(0xFF1E1E1E),
    'text': Colors.white,
    'selectedTab': Colors.amber[600]!,
    'unselectedTab': Colors.grey[700]!,
    'textSelected': Colors.white,
    'textUnselected': Colors.amber[600]!,
  };

  @override
  void initState() {
    super.initState();
    _initPreferences();
    _loadDarkModePreference();

    // Scroll controller listener'ı ekliyoruz
    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset >= 200;
      });
    });
  }

  Future<void> _loadLastSelectedMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isInstitutionMode = prefs.getBool("isInstitutionMode") ?? false;
    });
  }

  Future<void> _initPreferences() async {
    await _loadDarkModePreference();
    await _loadLastSelectedMode();
    _loadData(_getTimePeriodForIndex(_selectedTabIndex));
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void _loadData(String timePeriod) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;

    try {
      final response = await ApiService().fetchInstitutionUsersPointPeriod(
        timePeriod,
        _isInstitutionMode,
      );

      setState(() {
        _hasInstitution = response['has_institution'];
        _institutionName = response['institution_name'];
        _users =
            (response['users'] as List).map((u) => User.fromJson(u)).toList();

        _users!.sort((a, b) => b.point.compareTo(a.point));

        if (_hasInstitution && _isInstitutionMode) {
          int currentUserIndex =
              _users!.indexWhere((user) => user.id == currentUserId);
          if (currentUserIndex != -1) {
            userRank = currentUserIndex + 1;
            _isUserRankComputed = true;
          } else {
            userRank = null;
            _isUserRankComputed = false;
          }
        } else {
          userRank = _users!.indexWhere((user) => user.id == currentUserId) + 1;
          _isUserRankComputed = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veri yüklenirken bir hata oluştu: $e')),
      );
      setState(() {
        _users = [];
        _hasInstitution = false;
        _institutionName = null;
        userRank = null;
        _isUserRankComputed = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onModeChanged(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    if (mode == 'Kurumsal') {
      prefs.setBool("isInstitutionMode", true);
      setState(() {
        _isInstitutionMode = true;
      });
    } else {
      prefs.setBool("isInstitutionMode", false);
      setState(() {
        _isInstitutionMode = false;
      });
    }
    _loadData(_getTimePeriodForIndex(_selectedTabIndex));
  }

  void _filterUsers(String query) {
    if (!_isInstitutionMode) return;

    if (query.isEmpty) {
      setState(() {
        _filteredUsers = null;
      });
    } else {
      setState(() {
        _filteredUsers = _users
            ?.where(
                (user) => user.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        backgroundColor:
            _isInstitutionMode ? const Color(0xFFFFA726) : Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Icon(
            _isInstitutionMode ? Icons.business : Icons.emoji_events,
            color: _isInstitutionMode ? Colors.white : colors["text"],
            size: 24.sp,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isInstitutionMode ? 'Kurumsal\n2. SEZON' : '2. SEZON',
              style: GoogleFonts.poppins(
                color: _isInstitutionMode ? Colors.white : colors["text"],
                fontWeight: FontWeight.w900,
                fontSize: _isInstitutionMode ? 13.sp : 16.sp,
                height: _isInstitutionMode ? 1.1 : null,
                letterSpacing: 0.5,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                )
                .shimmer(
                  duration: 2000.ms,
                  color: _isInstitutionMode
                      ? Colors.white24
                      : Colors.amber.withOpacity(0.3),
                ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
            child: Row(
              children: [
                _buildModeButton(
                  title: 'Genel',
                  isSelected: !_isInstitutionMode,
                  color: Colors.green,
                ),
                SizedBox(width: 8.w),
                _buildModeButton(
                  title: 'Kurumsal',
                  isSelected: _isInstitutionMode,
                  color: Color(0xFFFFA726),
                ),
              ],
            ),
          ),
          _buildRoundedIconButton(Icons.slow_motion_video_sharp, Colors.green,
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      VideoPlayerScreen(videoUrl: AppUrls.leaderscreen)),
            );
          }),
        ],
        bottom: _isInstitutionMode
            ? PreferredSize(
                preferredSize: Size.fromHeight(60.h),
                child: Container(
                  margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Öğrenci ara...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search,
                          color: Color(0xFFFFA726), size: 22.sp),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                    onChanged: _filterUsers,
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isInstitutionMode && _institutionName != null)
                Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                  color: const Color(0xFFFFA726),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, color: Colors.white, size: 20.sp),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: AutoSizeText(
                          'Kurum: $_institutionName',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                          maxLines: 1,
                          minFontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildCustomTabs(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 80.h),
                  child: _hasInstitution || !_isInstitutionMode
                      ? LeaderboardList(
                          users: _filteredUsers ?? _users,
                          scrollController: _scrollController,
                          isDarkMode: _isDarkMode,
                        )
                      : NoInstitutionWidget(
                          onContactInstitution: () {
                            launch(
                                'mailto:destek@kelibu.com?subject=Kurumsal Kayıt Talebi&body=Merhaba, Kurumumuzun Liderlik Tablosuna eklenmesini talep ediyoruz.');
                          },
                        ),
                ),
              ),
            ],
          ),
          // Yukarı çıkma butonu
          Positioned(
            right: 16.w,
            bottom: 100.h,
            child: AnimatedOpacity(
              opacity: _showScrollToTop ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    customBorder: CircleBorder(),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isInstitutionMode
                            ? Color(0xFFFFA726)
                            : Colors.green[400],
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildUserRankBottomSheet(colors),
    );
  }

  Widget _buildCustomTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabItem('Tümü', 0),
          _buildTabItem('Gün', 1),
          _buildTabItem('Hafta', 2),
          _buildTabItem('Ay', 3),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required bool isSelected,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: () => _onModeChanged(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[300],
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRoundedIconButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: onPressed,
        child: Image.asset(
          'assets/videoplayer.png',
          width: 32.sp,
          height: 32.sp,
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedTabIndex = index;
                _filteredUsers = null;
                _searchController.clear();
              });
              _loadData(_getTimePeriodForIndex(index));
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors['selectedTab']?.withOpacity(0.95)
                    : colors['unselectedTab']?.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: isSelected
                    ? null
                    : Border.all(
                        color: colors['unselectedTab']!.withOpacity(0.3),
                        width: 1,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors['selectedTab']!.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected) ...[
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: colors['textSelected'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? colors['textSelected']
                            : colors['textUnselected']?.withOpacity(0.75),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13.sp,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildUserRankBottomSheet(Map<String, Color> colors) {
    final bool hasRank =
        userRank != null && userRank! > 0 && _isUserRankComputed;
    final Color sheetColor =
        _isInstitutionMode ? Color(0xFFFFA726) : Colors.green[400]!;

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: sheetColor,
        boxShadow: [
          BoxShadow(
            color: sheetColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Stack(
        children: [
          // Arkaplan deseni (opsiyonel)
          if (hasRank)
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.emoji_events,
                size: 80.sp,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          // Ana içerik
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasRank ? Icons.emoji_events : Icons.run_circle_outlined,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          hasRank
                              ? 'Tebrikler!'
                              : 'Henüz sıralamada değilsiniz!',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          minFontSize: 10,
                        ),
                        if (hasRank) ...[
                          SizedBox(height: 2.h),
                          AutoSizeText(
                            '${_isInstitutionMode ? "Kurumsal" : "Genel"} Sıralamanız: #$userRank',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            minFontSize: 10,
                          ),
                        ] else ...[
                          SizedBox(height: 2.h),
                          AutoSizeText(
                            'Çalışmalarınıza devam edin!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 12.sp,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            minFontSize: 10,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasRank ? Icons.military_tech : Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardList extends StatelessWidget {
  final List<User>? users;
  final ScrollController scrollController;
  final bool isDarkMode;

  const LeaderboardList({
    Key? key,
    required this.users,
    required this.scrollController,
    required this.isDarkMode,
  }) : super(key: key);

  void _showProfileImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.network(
                        'https://kelibu.net/storage/$imageUrl',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = isDarkMode ? darkModeColors : lightModeColors;
    if (users == null) {
      return Center(child: const LogoLoadingIndicator());
    } else if (users!.isEmpty) {
      // Burayı daha güzel bir boş durum göstergesiyle değiştirelim
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64.sp,
              color: colors["text"],
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              'Sıralama güncelleniyor...',
              style: GoogleFonts.poppins(
                color: colors["text"],
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              minFontSize: 14,
            ),
            SizedBox(height: 8.h),
            AutoSizeText(
              'Bu işlem birkaç saniye sürebilir',
              style: GoogleFonts.poppins(
                color: colors["text"]?.withOpacity(0.7),
                fontSize: 14.sp,
              ),
              maxLines: 1,
              minFontSize: 12,
            ),
            SizedBox(height: 24.h),
            const LogoLoadingIndicator(),
          ],
        ),
      );
    } else {
      return ListView.builder(
        controller: scrollController,
        itemCount: users!.length,
        itemBuilder: (context, index) {
          return _buildUserTile(
              context, users![index], index + 1, colors, isDarkMode);
        },
      );
    }
  }

  Widget _buildUserTile(BuildContext context, User user, int rank,
      Map<String, Color> colors, bool isDarkMode) {
    final isTopThree = rank <= 3;
    final backgroundColor = _getBackgroundColorForRank(rank, isDarkMode);
    final textColor = isTopThree ? Colors.white : colors["text"]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: isTopThree
            ? Border.all(
                color:
                    isDarkMode ? Colors.white24 : Colors.blue.withOpacity(0.3),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? (isDarkMode ? Colors.black26 : Colors.blue.withOpacity(0.2))
                : Colors.black.withOpacity(0.05),
            blurRadius: isTopThree ? 8 : 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: GestureDetector(
          onTap: () => _showProfileImage(context, user.avatar),
          child: _buildLeadingWidget(context, rank, user),
        ),
        title: AutoSizeText(
          user.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16.sp,
          ),
          maxLines: 1,
          minFontSize: 14,
          maxFontSize: 16,
        ),
        subtitle: AutoSizeText(
          '${user.city ?? "Şehir Bilinmiyor"} • ${user.team ?? "Takım Bilinmiyor"}',
          style: GoogleFonts.poppins(
            color: textColor.withOpacity(0.7),
            fontSize: 12.sp,
          ),
          maxLines: 1,
          minFontSize: 10,
          maxFontSize: 12,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AutoSizeText(
                  '${user.point}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                ),
                AutoSizeText(
                  '#$rank',
                  style: GoogleFonts.poppins(
                    color: textColor.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
            if (user.currentStreak != null && user.currentStreak! > 0) ...[
              SizedBox(width: 8.w),
              TweenAnimationBuilder(
                duration: Duration(milliseconds: 300),
                tween: Tween<double>(begin: 0.8, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: isTopThree
                              ? Colors.amber
                              : _getStreakColor(user.currentStreak!),
                          size: _getStreakSize(user.currentStreak!).sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${user.currentStreak}',
                          style: GoogleFonts.poppins(
                            color: isTopThree
                                ? Colors.amber
                                : _getStreakColor(user.currentStreak!),
                            fontWeight: FontWeight.bold,
                            fontSize:
                                (_getStreakSize(user.currentStreak!) - 4).sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStreakColor(int streak) {
    if (streak >= 30) return Colors.redAccent; // Efsanevi
    if (streak >= 20) return Colors.deepOrangeAccent; // Çok İyi
    if (streak >= 10) return Colors.orangeAccent; // İyi
    if (streak >= 5) return Colors.orange; // Başlangıç
    return Colors.grey.shade400; // Normal
  }

// Daha küçük boyutlar kullanalım
  double _getStreakSize(int streak) {
    if (streak >= 30) return 18; // Efsanevi
    if (streak >= 20) return 17; // Çok İyi
    if (streak >= 10) return 16; // İyi
    if (streak >= 5) return 15; // Başlangıç
    return 14; // Normal
  }

  Widget _buildStreakWidget(int streak, bool isTopThree) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: streak >= 20
                  ? _getStreakColor(streak).withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: isTopThree ? Colors.white : _getStreakColor(streak),
                  size: _getStreakSize(streak).sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  '$streak',
                  style: GoogleFonts.poppins(
                    color: isTopThree ? Colors.white : _getStreakColor(streak),
                    fontWeight: FontWeight.bold,
                    fontSize: (_getStreakSize(streak) - 2).sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingWidget(BuildContext context, int rank, User user) {
    IconData icon;
    Color iconColor;

    switch (rank) {
      case 1:
        icon = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case 2:
        icon = Icons.military_tech;
        iconColor = Colors.grey;
        break;
      case 3:
        icon = Icons.stars;
        iconColor = Colors.brown;
        break;
      default:
        icon = Icons.person;
        iconColor = Colors.blueGrey;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 24.r,
          backgroundImage:
              NetworkImage('https://kelibu.net/storage/${user.avatar}'),
        ),
        if (rank <= 3)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 12.sp,
                color: iconColor,
              ),
            ),
          ),
      ],
    );
  }

  Color _getBackgroundColorForRank(int rank, bool isDarkMode) {
    if (isDarkMode) {
      switch (rank) {
        case 1:
          return Color(0xFF2C3E50); // Koyu lacivert
        case 2:
          return Color(0xFF34495E); // Biraz daha açık lacivert
        case 3:
          return Color(0xFF445D6E); // En açık lacivert
        default:
          return Colors.grey.shade900;
      }
    } else {
      switch (rank) {
        case 1:
          return Color(0xFF1E88E5); // Mavi
        case 2:
          return Color(0xFF42A5F5); // Daha açık mavi
        case 3:
          return Color(0xFF64B5F6); // En açık mavi
        default:
          return Colors.white;
      }
    }
  }
}

class NoInstitutionWidget extends StatelessWidget {
  final VoidCallback onContactInstitution;

  const NoInstitutionWidget({Key? key, required this.onContactInstitution})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Color(0xFFFFA726);
    final Color backgroundColor = Colors.white;
    final Color textColor = Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80.sp,
            color: primaryColor,
          ),
          SizedBox(height: 20.h),
          Text(
            'Kelibu Kurumsal kaydınız bulunamadı',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            'Kurumunuz ile iletişime geçerek Kelibu Kurumsal üyeliği talep edebilirsiniz. Eğitim hayatınızda başarılar dileriz.',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
