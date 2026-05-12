import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/screens/game_mod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import 'AddWordPage.dart';
import 'loadingIndicator.dart';

class WordSetDetailPage extends StatefulWidget {
  final int setId;
  final String setName;

  const WordSetDetailPage({
    Key? key,
    required this.setId,
    required this.setName,
  }) : super(key: key);

  @override
  _WordSetDetailPageState createState() => _WordSetDetailPageState();
}

class _WordSetDetailPageState extends State<WordSetDetailPage> {
  bool _isDarkMode = false;
  bool _isLoading = true;
  Map<String, dynamic>? _wordSetData;
  List<dynamic> _words = [];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadWordSetDetail();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Future<void> _loadWordSetDetail() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final data = await apiService.getWordSetDetail(widget.setId);

      setState(() {
        _wordSetData = data;
        _words = data['words'] ?? [];
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);

      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Detay yüklenemedi',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black87,
        ),
        title: Text(
          widget.setName,
          style: GoogleFonts.nunito(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: _isLoading ? LogoLoadingIndicator() : _buildContent(),
      floatingActionButton: Container(
        width: 64.w,
        height: 64.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF58CC02).withOpacity(0.4),
              blurRadius: 16,
              offset: Offset(0, 8),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Kelime ekle sayfasına git
              _showAddWordDialog();
            },
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 36.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_words.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // İstatistik kartı
        _buildStatsCard(),

        SizedBox(height: 16.h),

        // 🎮 HEMEN OYNA BUTONU
        _buildPlayButton(),

        SizedBox(height: 16.h),

        // Kelime listesi
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _words.length,
            itemBuilder: (context, index) {
              final word = _words[index];
              return _buildWordCard(word);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Color(0xFF58CC02),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF58CC02).withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final wordList = _words.map((word) => word['id']).toList();
            final wordsString = wordList.join(', ');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameModeScreen(
                  studySetName: wordsString,
                  classroomId: -2,
                  studySetId: -2,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Hemen Oyna',
                  style: GoogleFonts.nunito(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1CB0F6), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1CB0F6).withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.article,
                label: 'Kelime',
                value: '${_words.length}',
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: _wordSetData?['is_public'] == true
                    ? Icons.public
                    : Icons.lock,
                label: 'Durum',
                value: _wordSetData?['is_public'] == true ? 'Açık' : 'Özel',
              ),
              Container(
                width: 1,
                height: 40.h,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                icon: Icons.calendar_today,
                label: 'Oluşturulma',
                value: _formatDate(_wordSetData?['created_at']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28.sp),
        SizedBox(height: 8.h),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(dynamic word) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey[300]!)
                .withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Kelime detayına git veya çevir
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              children: [
                // İngilizce kelime
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word['english'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        word['turkish'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 14.sp,
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (word['sentence'] != null &&
                          word['sentence'].toString().isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          word['sentence'],
                          style: GoogleFonts.nunito(
                            fontSize: 12.sp,
                            fontStyle: FontStyle.italic,
                            color:
                                _isDarkMode ? Colors.white54 : Colors.black38,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Sil butonu
                IconButton(
                  onPressed: () => _removeWord(word['id']),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.sp),
            decoration: BoxDecoration(
              color: Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.article_outlined,
              size: 64.sp,
              color: Color(0xFF58CC02),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Henüz kelime yok',
            style: GoogleFonts.nunito(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Kelime eklemek için + butonuna tıklayın',
            style: GoogleFonts.nunito(
              fontSize: 16.sp,
              color: _isDarkMode ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWordSet(String newName) async {
    try {
      final apiService = ApiService();
      await apiService.updateWordSet(
        setId: widget.setId,
        setName: newName,
      );

      setState(() {
        _wordSetData?['set_name'] = newName;
      });

      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Set güncellendi',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFF58CC02),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Güncelleme başarısız',
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 16.sp),
        ),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    }
  }

  Future<void> _deleteWordSet() async {
    try {
      final apiService = ApiService();
      await apiService.deleteWordSet(widget.setId);

      Get.back(); // Detay sayfasından çık
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Set silindi',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Silme başarısız',
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 16.sp),
        ),
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    }
  }

  void _showAddWordDialog() async {
    // ✅ await ile sonucu bekle
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWordPage(
          setId: widget.setId,
          setName: widget.setName,
        ),
      ),
    );

    // ✅ Eğer kelime eklendiyse refresh et
    if (result == true) {
      _loadWordSetDetail();
    }
  }

  Future<void> _removeWord(int wordId) async {
    // Onay dialogu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Kelimeyi Sil',
          style: GoogleFonts.nunito(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Bu kelimeyi setten çıkarmak istediğinize emin misiniz?',
          style: GoogleFonts.nunito(
            fontSize: 16.sp,
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'İptal',
              style: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sil',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // İptal edildiyse çık
    if (confirm != true) return;

    try {
      final apiService = ApiService();

      // API'den sil
      await apiService.removeWordFromSet(
        setId: widget.setId,
        wordId: wordId,
      );

      // Local'den sil
      setState(() {
        _words.removeWhere((word) => word['id'] == wordId);
      });

      // Başarı mesajı
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Kelime setten çıkarıldı',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF58CC02),
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      );
    } catch (e) {
      // Hata mesajı
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Kelime silinemedi',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) return 'Bugün';
      if (difference == 1) return 'Dün';
      if (difference < 7) return '$difference gün önce';

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
