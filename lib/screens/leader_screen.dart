import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
        currentUserId.toString(),
        timePeriod,
        _isInstitutionMode,
      );

      setState(() {
        _hasInstitution = response['has_institution'];
        _institutionName = response['institution_name'];
        _users = (response['users'] as List).map((u) => User.fromJson(u)).toList();

        // Kullanıcıları puanlarına göre azalan şekilde sıralama
        _users!.sort((a, b) => b.point.compareTo(a.point));

        if (_hasInstitution && _isInstitutionMode) {
          int currentUserIndex = _users!.indexWhere((user) => user.id == currentUserId);
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
      print("Error loading data: $e");
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

  /// Arama fonksiyonu (sadece kurumsal modda aktif)
  void _filterUsers(String query) {
    if (!_isInstitutionMode) return; // Arama sadece kurumsal modda aktif

    if (query.isEmpty) {
      setState(() {
        _filteredUsers = null;
      });
    } else {
      setState(() {
        _filteredUsers = _users
            ?.where((user) =>
            user.name.toLowerCase().contains(query.toLowerCase()))
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
        backgroundColor: _isInstitutionMode
            ? Colors.amber[600] // Kurumsal mod için sarımsı renk
            : (_isDarkMode ? darkModeColors["background"] : colors["background"]),
        elevation: 0,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _isInstitutionMode ? 'Kurumsal Liderlik' : 'Liderlik Tablosu',
            style: GoogleFonts.poppins(
              color: _isInstitutionMode ? Colors.white : colors["text"],
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
            ),
          ),
        ),
        actions: [
          // 'Genel' ve 'Kurumsal' modları için iki ayrı buton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => _onModeChanged('Genel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isInstitutionMode ? Colors.green : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Genel',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: () => _onModeChanged('Kurumsal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isInstitutionMode ? Colors.amber : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Kurumsal',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.play_circle_fill, color: colors["text"]),
            tooltip: 'Video İzle',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VideoPlayerScreen(videoUrl: AppUrls.leaderscreen),
                ),
              );
            },
          ),
        ],
        bottom: _isInstitutionMode
            ? PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Öğrenci adını girin",
                prefixIcon: Icon(Icons.search, color: Colors.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
              ),
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
              onChanged: _filterUsers,
            ),
          ),
        )
            : null,
      ),
      body: Column(
        children: [
          if (_isInstitutionMode && _institutionName != null)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.amber[600], // Kurumsal mod için sarımsı renk
              child: Center(
                child: AutoSizeText(
                  'Kurum: $_institutionName',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                  maxFontSize: 18,
                ),
              ),
            ),
          _buildCustomTabs(),
          Expanded(
            child: Padding(
              // Alt sağ kısmın yukarı çıkmasını önlemek için padding'i artırdık
              padding: EdgeInsets.only(bottom: 80.h),
              child: _hasInstitution || !_isInstitutionMode
                  ? LeaderboardList(
                users: _filteredUsers ?? _users,
                scrollController: _scrollController,
                isDarkMode: _isDarkMode,
              )
                  : NoInstitutionWidget(
                onContactInstitution: () {
                  // Kurumla iletişime geçmek için bir e-posta uygulaması açabilirsiniz
                  launch(
                      'mailto:destek@kelibu.com?subject=Kurumsal Kayıt Talebi&body=Merhaba, Kurumumuzun Liderlik Tablosuna eklenmesini talep ediyoruz.');
                },
              ),
            ),
          ),
        ],
      ),
      // Sağ alt köşede "En Üste Git" butonu
      floatingActionButton: FloatingActionButton(
        backgroundColor:
        _isInstitutionMode ? Colors.amber[600] : Colors.green[400],
        onPressed: () {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: Icon(Icons.arrow_upward, color: Colors.white, size: 20.sp),
        tooltip: 'En Üste Git',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Alt kısımda kullanıcı sıralamasını gösteren panel
      bottomSheet: _buildUserRankBottomSheet(colors),
    );
  }

  // _buildCustomTabs ve _buildTabItem metodlarını sınıf seviyesinde tanımlıyoruz.
  Widget _buildCustomTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabItem('Tümü', 0),
          _buildTabItem('Günlük', 1),
          _buildTabItem('Haftalık', 2),
          _buildTabItem('Aylık', 3),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            _filteredUsers = null; // Sekme değiştiğinde aramayı sıfırla
            _searchController.clear();
          });
          _loadData(_getTimePeriodForIndex(index));
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected ? colors['selectedTab'] : Colors.transparent,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected
                  ? colors['selectedTab']!
                  : colors['unselectedTab']!,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: isSelected ? colors['textSelected'] : colors['textUnselected'],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14.sp,
              ),
              overflow: TextOverflow.ellipsis,
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
    return Container(
      color: _isInstitutionMode ? Colors.amber[600] : Colors.green[400],
      height: 40.h,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                (userRank != null && userRank! > 0)
                    ? Icons.emoji_events
                    : Icons.run_circle_outlined,
                color: Colors.white,
                size: 32.sp,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AutoSizeText(
                    (userRank != null && userRank! > 0 && _isUserRankComputed)
                        ? 'Tebrikler! ${_isInstitutionMode ? "Kurumsal" : "Genel"} Sıralamanız: #$userRank'
                        : 'Henüz sıralamada değilsiniz! Çalışmalarınıza devam edin!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp, // Küçültülmüş font boyutu
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    minFontSize: 10,
                  ),
                ),
              ),
              Icon(
                (userRank != null && userRank! > 0)
                    ? Icons.military_tech
                    : Icons.lightbulb_outline,
                color: Colors.white,
                size: 32.sp,
              ),
            ],
          ),
        ),
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


  @override
  Widget build(BuildContext context) {
    final colors = isDarkMode ? darkModeColors : lightModeColors;
    if (users == null) {
      return Center(child: const LogoLoadingIndicator());
    } else if (users!.isEmpty) {
      return Center(
        child: AutoSizeText(
          'Veri bulunamadı',
          style: GoogleFonts.poppins(
              color: colors["text"], fontSize: 18.sp),
          maxLines: 1,
          minFontSize: 14,
        ),
      );
    } else {
      return ListView.builder(
        controller: scrollController,
        itemCount: users!.length,
        itemBuilder: (context, index) {
          return _buildUserTile(context, users![index], index + 1, colors, isDarkMode);
        },
      );
    }
  }

  Widget _buildUserTile(
      BuildContext context, User user, int rank, Map<String, Color> colors, bool isDarkMode) {
    final isTopThree = rank <= 3;
    final backgroundColor = isTopThree
        ? _getBackgroundColorForRank(rank, isDarkMode)
        : isDarkMode
        ? Colors.grey[900]
        : colors["cardBackground"];
    final textColor = isTopThree && !isDarkMode ? Colors.white : colors["text"]!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: _buildLeadingWidget(context, rank, user),
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AutoSizeText(
              '${user.point}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18.sp,
              ),
              maxLines: 1,
              minFontSize: 14,
              maxFontSize: 18,
            ),
            SizedBox(height: 4.h),
            AutoSizeText(
              '#$rank',
              style: GoogleFonts.poppins(
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
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
          return Colors.amber.shade900;
        case 2:
          return Colors.amber.shade700;
        case 3:
          return Colors.amber.shade500;
        default:
          return Colors.grey.shade900;
      }
    } else {
      switch (rank) {
        case 1:
          return Colors.amber.shade500;
        case 2:
          return Colors.amber.shade400;
        case 3:
          return Colors.amber.shade300;
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
    final Color primaryColor = Colors.amber[600]!; // Kurumsal mod rengi
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Kurum Ayarları',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amber[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _groupCodeController,
              decoration: InputDecoration(
                hintText: 'Kurum Kodu Girin',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.business, color: Colors.amber[600]),
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              ),
              style: GoogleFonts.poppins(fontSize: 18.sp),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            child: Text(
              widget.hasGroup ? 'Kurumu Güncelle' : 'Kuruma Katıl',
              style: GoogleFonts.poppins(fontSize: 18.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[600],
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
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
            SizedBox(height: 16.h),
            TextButton(
              child: Text(
                'Kurumdan Ayrıl',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  color: Colors.redAccent,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
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
