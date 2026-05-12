import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';

class AddWordPage extends StatefulWidget {
  final int setId;
  final String setName;

  const AddWordPage({
    Key? key,
    required this.setId,
    required this.setName,
  }) : super(key: key);

  @override
  _AddWordPageState createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  bool _isDarkMode = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isManualMode = false;
  List<WordSearchResult> _searchResults = [];
  Timer? _debounce;

  // Manuel ekleme için controller'lar
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _debounce?.cancel();

    super.dispose();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Future<void> _searchWord(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Debounce: Kullanıcı yazmayı bitirdikten 500ms sonra ara
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final apiService = ApiService();
        final results = await apiService.searchWords(query);

        setState(() {
          _searchResults = results.map((json) {
            return WordSearchResult(
              id: json['id'],
              word: json['word'] ?? '',
              meaning: json['meaning'] ?? '',
              example: json['example'] ?? '',
              type: json['type'] ?? 'noun',
            );
          }).toList();
          _isSearching = false;
        });
      } catch (e) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });

        Get.snackbar(
          "",
          "",
          titleText: Container(),
          messageText: Text(
            'Arama yapılırken hata oluştu',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.red,
          borderRadius: 16,
          duration: Duration(seconds: 2),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(16),
        );
      }
    });
  }

  Future<void> _addWordToSet(int wordId) async {
    try {
      final apiService = ApiService();
      await apiService.addWordToSet(
        wordSetId: widget.setId,
        wordId: wordId,
      );

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
                'Kelime başarıyla eklendi! 🎉',
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

      // ✅ Geri dönerken true gönder
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          e.message,
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Kelime eklenirken hata oluştu',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        borderRadius: 16,
        duration: Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Color(0xFF1A1A2E) : Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Color(0xFF16213E) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: Color(0xFF58CC02).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back,
              color: Color(0xFF58CC02),
              size: 20.sp,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelime Ekle',
              style: GoogleFonts.nunito(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
              ),
            ),
            Text(
              widget.setName,
              style: GoogleFonts.nunito(
                fontSize: 13.sp,
                color: _isDarkMode ? Colors.white70 : Color(0xFF718096),
              ),
            ),
          ],
        ),
        actions: [
          // Mod değiştirme toggle
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: _isDarkMode ? Color(0xFF0F1419) : Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDarkMode ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildModeButton(
                  icon: Icons.search,
                  label: 'Ara',
                  isSelected: !_isManualMode,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isManualMode = false);
                  },
                ),
                _buildModeButton(
                  icon: Icons.edit_note,
                  label: 'Manuel',
                  isSelected: _isManualMode,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isManualMode = true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isManualMode ? _buildManualMode() : _buildSearchMode(),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (_isDarkMode ? Colors.white54 : Color(0xFF718096)),
              size: 18.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (_isDarkMode ? Colors.white54 : Color(0xFF718096)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchMode() {
    return Column(
      children: [
        // Arama çubuğu
        Container(
          margin: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF16213E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDarkMode ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF58CC02).withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchWord(value);
            },
            style: GoogleFonts.nunito(
              color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Kelime ara...',
              hintStyle: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white38 : Color(0xFFA0AEC0),
                fontSize: 16.sp,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12.sp),
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                      icon: Icon(
                        Icons.clear,
                        color: _isDarkMode ? Colors.white54 : Color(0xFF718096),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            ),
          ),
        ),

        // Arama sonuçları veya boş durum
        Expanded(
          child: _isSearching
              ? Center(
                  child: Container(
                    padding: EdgeInsets.all(20.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : _searchResults.isEmpty
                  ? _buildEmptySearchState()
                  : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF58CC02).withOpacity(0.1),
                  Color(0xFF4CAF50).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Color(0xFF58CC02).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              _searchController.text.isEmpty
                  ? Icons.search
                  : Icons.sentiment_dissatisfied,
              size: 64.sp,
              color: Color(0xFF58CC02),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _searchController.text.isEmpty
                ? 'Kelime Ara'
                : 'Kelime Bulunamadı 🤔',
            style: GoogleFonts.nunito(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              _searchController.text.isEmpty
                  ? 'Yukarıdaki arama kutusuna kelime yazarak sözlükten arama yapabilirsiniz'
                  : 'Kelime Kelibu\'da yoksa ya İngilizce değildir ya da henüz eklenmemiştir. Çoklu dil desteğini en kısa sürede sizlerle buluşturacağımızın spoilerini da vermiş olalım 😉',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14.sp,
                color: _isDarkMode ? Colors.white60 : Color(0xFF718096),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultCard(result);
      },
    );
  }

  Widget _buildSearchResultCard(WordSearchResult result) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF58CC02).withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kelime ve tür
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.word,
                    style: GoogleFonts.nunito(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF58CC02).withOpacity(0.2),
                        Color(0xFF4CAF50).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF58CC02).withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    result.type,
                    style: GoogleFonts.nunito(
                      fontSize: 12.sp,
                      color: Color(0xFF58CC02),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Anlam
            Text(
              result.meaning,
              style: GoogleFonts.nunito(
                fontSize: 16.sp,
                color: _isDarkMode ? Colors.white70 : Color(0xFF4A5568),
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (result.example.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  color: Color(0xFF58CC02).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(0xFF58CC02).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      color: Color(0xFF58CC02),
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        result.example,
                        style: GoogleFonts.nunito(
                          fontSize: 14.sp,
                          color:
                              _isDarkMode ? Colors.white60 : Color(0xFF718096),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // Ekle butonu
            Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF58CC02).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _addWordToSet(result.id);
                },
                icon: Icon(Icons.add_circle, size: 22.sp, color: Colors.white),
                label: Text(
                  'Sete Ekle',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualMode() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bilgi kartı
          Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF58CC02).withOpacity(0.1),
                  Color(0xFF4CAF50).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color(0xFF58CC02).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'Manuel olarak kelime ekleyebilirsiniz',
                    style: GoogleFonts.nunito(
                      fontSize: 14.sp,
                      color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // Kelime girişi
          _buildInputField(
            label: 'Kelime',
            controller: _wordController,
            hint: 'Örn: apple',
            icon: Icons.translate,
          ),
          SizedBox(height: 20.h),

          // Anlam girişi
          _buildInputField(
            label: 'Anlam',
            controller: _meaningController,
            hint: 'Örn: elma',
            icon: Icons.lightbulb_outline,
            maxLines: 3,
          ),
          SizedBox(height: 20.h),

          // Örnek cümle girişi
          _buildInputField(
            label: 'Örnek Cümle (Opsiyonel)',
            controller: _exampleController,
            hint: 'Örn: I eat an apple every day',
            icon: Icons.format_quote,
            maxLines: 3,
          ),
          SizedBox(height: 32.h),

          // Ekle butonu
          Container(
            width: double.infinity,
            height: 60.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF58CC02).withOpacity(0.4),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Color(0xFF16213E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDarkMode ? Color(0xFF2D3748) : Color(0xFFE2E8F0),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF58CC02).withOpacity(0.05),
                blurRadius: 15,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.nunito(
              color: _isDarkMode ? Colors.white : Color(0xFF2D3748),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white38 : Color(0xFFA0AEC0),
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12.sp),
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
            ),
          ),
        ),
      ],
    );
  }
}

class WordSearchResult {
  final int id;
  final String word;
  final String meaning;
  final String example;
  final String type;

  WordSearchResult({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    required this.type,
  });
}
