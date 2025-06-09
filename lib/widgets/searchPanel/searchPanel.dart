import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/screens/loadingIndicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Models/wordDetaik.dart';
import '../../api.dart';
import '../../screens/study_screen.dart';

class SearchDialog extends StatefulWidget {
  final bool isDarkMode;

  const SearchDialog({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _SearchDialogState createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchError = '';
  WordDetail? _searchResult;
  FocusNode _searchFocusNode = FocusNode();
  bool _showSearchPanel = true;
  List<String> _searchHistory = [];
  List<String> _allSearchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    // Otomatik olarak arama kutusuna odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // Arama geçmişini yükle
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allSearchHistory = prefs.getStringList('all_search_history') ?? [];
      _searchHistory = prefs.getStringList('search_history') ?? [];

      // Eğer _searchHistory boşsa ama _allSearchHistory doluysa, son 10 aramayı göster
      if (_searchHistory.isEmpty && _allSearchHistory.isNotEmpty) {
        _searchHistory = _allSearchHistory.take(10).toList();
      }
    });
  }

  // Arama geçmişine yeni kelime ekle
  Future<void> _addToSearchHistory(String term) async {
    if (term.isEmpty) return;

    // Geçmişte aynı kelime varsa önce onu kaldır
    _searchHistory.remove(term);
    _allSearchHistory.remove(term);

    // Yeni kelimeyi başa ekle
    _searchHistory.insert(0, term);
    _allSearchHistory.insert(0, term);

    // Geçmiş 10 kelimeyle sınırla (ana liste için)
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }

    // Geçmişi kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    await prefs.setStringList('all_search_history', _allSearchHistory);
  }

  // Arama geçmişinden kelime sil
  Future<void> _removeFromHistory(String term) async {
    setState(() {
      _searchHistory.remove(term);
      _allSearchHistory.remove(term);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    await prefs.setStringList('all_search_history', _allSearchHistory);
  }

  // Tüm arama geçmişini temizle
  Future<void> _clearSearchHistory() async {
    setState(() {
      _searchHistory.clear();
      _allSearchHistory.clear();
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    await prefs.setStringList('all_search_history', _allSearchHistory);
  }

  // Tüm arama geçmişini gösteren diyalog
  void _showAllSearchHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Kaydırma çubuğu göstergesi
            Container(
              margin: EdgeInsets.only(top: 10.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Tüm Arama Geçmişi",
                    style: GoogleFonts.nunito(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: widget.isDarkMode ? Colors.white : Color(0xFF4B4B4B),
                    ),
                  ),
                  Row(
                    children: [
                      if (_allSearchHistory.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                            color: widget.isDarkMode ? Colors.red[300] : Colors.red,
                          ),
                          onPressed: () {
                            _clearSearchHistory();
                            Navigator.of(context).pop();
                          },
                          tooltip: "Tümünü Temizle",
                        ),
                      IconButton(
                        icon: Icon(Icons.close,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
              height: 1,
            ),
            Expanded(
              child: _allSearchHistory.isEmpty
                  ? _buildEmptyHistoryState()
                  : ListView.separated(
                itemCount: _allSearchHistory.length,
                separatorBuilder: (context, index) => Divider(
                  color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  height: 1,
                  indent: 70.w,
                ),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      Icons.history,
                      color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    title: Text(
                      _allSearchHistory[index],
                      style: GoogleFonts.nunito(
                        fontSize: 16.sp,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18.sp,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: () {
                        _removeFromHistory(_allSearchHistory[index]);
                        if (_allSearchHistory.isEmpty) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {}); // Listeyi yenile
                        }
                      },
                    ),
                    onTap: () {
                      _searchController.text = _allSearchHistory[index];
                      Navigator.of(context).pop();
                      performSearch(_allSearchHistory[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Boş arama geçmişi durumunda gösterilecek widget
  Widget _buildEmptyHistoryState() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60.sp,
            color: widget.isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            "Henüz kelime aramadınız",
            style: GoogleFonts.nunito(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "Arama yaparak geçmişinizi oluşturabilirsiniz",
            style: GoogleFonts.nunito(
              fontSize: 16.sp,
              color: widget.isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: widget.isDarkMode ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 10),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(),
            if (_showSearchPanel)
              Flexible(child: _buildSearchPanel())
            else
              _buildResultPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: widget.isDarkMode ? Color(0xFF2C2C2E) : Color(0xFF58CC02),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "Kelime Ara",
                style: GoogleFonts.nunito(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 16.h),
          // Arama kutusu
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 18.sp,
            ),
            decoration: InputDecoration(
              hintText: "Kelime girin...",
              hintStyle: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 16.sp,
              ),
              filled: true,
              fillColor: widget.isDarkMode ? Color(0xFF2C2C2E) : Color(0xFFF0F0F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.search, color: Color(0xFF58CC02), size: 22.sp),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear,
                          color: widget.isDarkMode ? Colors.white70 : Colors.grey[600],
                          size: 20.sp),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF58CC02),
                      size: 22.sp,
                    ),
                    onPressed: () => performSearch(_searchController.text),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
            onSubmitted: (term) => performSearch(term),
            textInputAction: TextInputAction.search,
          ),

          // Hata mesajı
          if (_searchError.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                _searchError,
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ),

          // Arama Geçmişi Başlığı ve Kontroller
          if (_searchHistory.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 18.sp,
                    color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Son Aramalar",
                    style: GoogleFonts.nunito(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: widget.isDarkMode ? Colors.white : Color(0xFF4B4B4B),
                    ),
                  ),
                  Spacer(),
                  if (_searchHistory.length > 3)
                    TextButton(
                      child: Text(
                        "Tümünü Gör",
                        style: GoogleFonts.nunito(
                          fontSize: 14.sp,
                          color: widget.isDarkMode ? Colors.blue[300] : Colors.blue,
                        ),
                      ),
                      onPressed: _showAllSearchHistory,
                    ),
                  SizedBox(width: 4.w),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20.sp,
                      color: widget.isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: widget.isDarkMode ? Color(0xFF2C2C2E) : Colors.white,
                          title: Text(
                            "Arama Geçmişini Temizle",
                            style: GoogleFonts.nunito(
                              color: widget.isDarkMode ? Colors.white : Color(0xFF4B4B4B),
                            ),
                          ),
                          content: Text(
                            "Tüm arama geçmişiniz silinecek. Onaylıyor musunuz?",
                            style: GoogleFonts.nunito(
                              color: widget.isDarkMode ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text("İptal"),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text(
                                "Temizle",
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                _clearSearchHistory();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: "Geçmişi Temizle",
                  ),
                ],
              ),
            ),

          // Arama Geçmişi Listesi veya Boş Durum Mesajı
          _searchHistory.isEmpty
              ? Expanded(child: _buildEmptyHistoryState())
              : Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchHistory.length > 3 ? 3 : _searchHistory.length,
              separatorBuilder: (context, index) => Divider(
                color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                height: 1,
                indent: 48.w,
              ),
              itemBuilder: (context, index) {
                return _buildHistoryItem(_searchHistory[index]);
              },
            ),
          ),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String term) {
    return ListTile(
      dense: true,
      horizontalTitleGap: 0,
      leading: Icon(
        Icons.history,
        size: 18.sp,
        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      title: Text(
        term,
        style: GoogleFonts.nunito(
          fontSize: 15.sp,
          color: widget.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.close,
          size: 16.sp,
          color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        onPressed: () => _removeFromHistory(term),
      ),
      onTap: () {
        _searchController.text = term;
        performSearch(term);
      },
    );
  }

  Widget _buildResultPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Geri butonu
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  setState(() {
                    _showSearchPanel = true;
                  });
                },
              ),
              Text(
                "Arama Sonucu",
                style: GoogleFonts.nunito(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),

        Divider(
          color: widget.isDarkMode ? Colors.grey[800] : Colors.grey[300],
          height: 1,
        ),

        // Kelime detayları
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${_searchResult!.word}",
                      style: GoogleFonts.nunito(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.isDarkMode ? Colors.white : Color(0xFF4B4B4B),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Color(0xFF2C2C2E) : Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Text(
                  "${_searchResult!.meaning}",
                  style: GoogleFonts.nunito(
                    fontSize: 16.sp,
                    color: widget.isDarkMode ? Colors.white70 : Colors.grey[800],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.celebration, color: Colors.white, size: 20.sp),
                  label: Text(
                    "Detaylı Keşfet!",
                    style: GoogleFonts.nunito(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF9800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    elevation: 0,
                  ),
                  onPressed: () => _navigateToWordDetail(_searchResult!),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> performSearch(String term) async {
    if (term.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchError = '';
    });

    try {
      final apiService = ApiService();
      final searchResult = await apiService.searchWord(term);

      if (searchResult != null) {
        // Arama geçmişine ekle
        _addToSearchHistory(term);

        setState(() {
          _searchResult = searchResult;
          _showSearchPanel = false;
        });
      } else {
        setState(() {
          _searchError = 'Kelime bulunamadı';
        });
      }
    } catch (e) {
      setState(() {
        _searchError = 'Bir hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToWordDetail(WordDetail word) async {
    final apiService = ApiService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: LogoLoadingIndicator());
      },
    );

    try {
      List<int> wordIds = [word.id];
      List<WordDetail> detailedWords =
      await apiService.fetchWordsDetail(wordIds);

      if (detailedWords.isNotEmpty) {
        WordDetail detailedWord = detailedWords.first;
        Navigator.of(context).pop(); // Loading dialog'u kapat

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => StudyScreen(
            words: [detailedWord],
            classroomId: 0,
            studySetId: 0,
            isStarred: true,
          ),
        ));
      } else {
        throw Exception('Detaylı kelime bilgisi bulunamadı.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Loading dialog'u kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Kelime detayları yüklenirken bir hata oluştu.')),
      );
    }
  }
}

class SearchPanel extends StatelessWidget {
  final bool isDarkMode;

  const SearchPanel({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return SearchDialog(isDarkMode: isDarkMode);
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF3A3A3C) : Color(0xFF58CC02),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search,
                color: isDarkMode ? Colors.grey[300] : Colors.white,
                size: 24.sp),
            SizedBox(width: 8.w),
            Text(
              "Sözlük",
              style: GoogleFonts.nunito(
                color: isDarkMode ? Colors.grey[300] : Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}