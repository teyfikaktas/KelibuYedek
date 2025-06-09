import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kelibu/Models/product.dart';
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/Models/category.dart';
import 'package:kelibu/screens/loadingIndicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../providers/sub_provider.dart';
import '../providers/user_provider.dart';
import 'game_mod.dart';
import 'market_store.dart';

class WordSetsPage extends StatefulWidget {
  const WordSetsPage({Key? key}) : super(key: key);

  @override
  _WordSetsPageState createState() => _WordSetsPageState();
}

class _WordSetsPageState extends State<WordSetsPage> {
  List<Product>? _products;
  List<Product>? _filteredProducts;
  bool _isDarkMode = false;
  bool _isFreeMode = false;
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  final _storage = GetStorage();
  RxMap<int, bool> _pinnedProducts = RxMap<int, bool>({});
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _fetchProducts();
    _checkFreeMode();
    _loadPinnedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadPinnedProducts() {
    final pinnedList = _storage.read<List>('pinnedProducts') ?? [];
    _pinnedProducts.value = Map.fromEntries(
      pinnedList.map((id) => MapEntry(id as int, true)),
    );
  }
// WordSetsPage sınıfına bu method'u ekleyin

// WordSetsPage'deki navigateToGameModeFromSearchHistory method'unu bu şekilde güncelleyin

  Future<void> navigateToGameModeFromSearchHistory() async {
    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Center(
            child: LogoLoadingIndicator(),
          ),
        );
      },
    );

    try {
      // Arama geçmişindeki kelimelerin ID'lerini al
      List<int> searchHistoryIds = await _getSearchHistoryIds();

      // Dialog'u kapat
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (searchHistoryIds.isEmpty) {
        // Eğer arama geçmişi boşsa kullanıcıyı bilgilendir
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
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Önce sözlükten kelime arayın',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          borderRadius: 16,
          duration: Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        );
        return;
      }

      // GameModeScreen'e git - List<int>'i String'e çevir
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameModeScreen(
            studySetName: searchHistoryIds.join(','), // ID'leri virgülle ayırarak String yap
            classroomId: 1, // Sabit değer
            studySetId: 1,  // Sabit değer
          ),
        ),
      );

      if (result != null) {
        print('GameMode\'dan geri dönüldü');
        // Gerekirse sayfa yenileme işlemleri burada yapılabilir
      }
    } catch (e) {
      // Dialog'u güvenli şekilde kapat
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      print('Hata: $e');

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
            Text(
              'Bir hata oluştu: $e',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        borderRadius: 16,
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      );
    }
  }
// Arama geçmişindeki kelimelerin ID'lerini al
  Future<List<int>> _getSearchHistoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searchHistory = prefs.getStringList('search_history') ?? [];

    List<int> wordIds = [];
    final apiService = ApiService();

    for (String searchTerm in searchHistory) {
      try {
        final searchResult = await apiService.searchWord(searchTerm);
        if (searchResult != null) {
          wordIds.add(searchResult.id);
        }
      } catch (e) {
        print('Kelime ID alınırken hata: $searchTerm - $e');
      }
    }

    return wordIds;
  }

// Arama geçmişindeki kelime sayısını al
  Future<int> _getSearchHistoryCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searchHistory = prefs.getStringList('search_history') ?? [];
    return searchHistory.length;
  }
  Future<void> _togglePin(int productId) async {
    HapticFeedback.mediumImpact();

    if (_pinnedProducts.containsKey(productId)) {
      _pinnedProducts.remove(productId);
      Get.snackbar(
        "", // başlık boş bırakıyoruz çünkü custom title widget kullanacağız
        "", // mesaj boş bırakıyoruz çünkü custom message widget kullanacağız
        titleText: Container(), // başlığı gizle
        messageText: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.push_pin_outlined,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Sabitleme kaldırıldı',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF58CC02),
        borderRadius: 16,
        duration: Duration(seconds: 2),
        animationDuration: Duration(milliseconds: 500),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        barBlur: 5,
        overlayBlur: 0.5,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } else {
      _pinnedProducts[productId] = true;
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
                Icons.push_pin,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Liste başına sabitlendi',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF1CB0F6),
        borderRadius: 16,
        duration: Duration(seconds: 2),
        animationDuration: Duration(milliseconds: 500),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        barBlur: 5,
        overlayBlur: 0.5,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    }

    await _storage.write(
      'pinnedProducts',
      _pinnedProducts.keys.toList(),
    );
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return; // Çift istek göndermemek için

    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.fetchActiveProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (error) {
      print("API Error: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFreeMode() async {
    try {
      final isFree = await ApiService().checkFreeMode();
      setState(() => _isFreeMode = isFree);
    } catch (error) {
      print("Free Mode Error: $error");
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
      return;
    }

    setState(() {
      _filteredProducts = _products?.where((product) {
        final title = product.classroom?.title?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();
    });
  }

  List<Product> _getSortedProducts() {
    final currentProducts = (_filteredProducts ?? _products ?? []);
    return List.from(currentProducts)..sort((a, b) {
      final aPinned = _pinnedProducts[a.id ?? 0] ?? false;
      final bPinned = _pinnedProducts[b.id ?? 0] ?? false;
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isVip = Provider.of<SubscriptionProvider>(context).isVip;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black87,
          size: 26.sp,
        ),
        titleSpacing: 0,
        leadingWidth: 50.w,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.nunito(
            color: _isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Set ara...',
            hintStyle: GoogleFonts.nunito(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 18.sp,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
          onChanged: _onSearchChanged,
        )
            : Align(
          alignment: Alignment.center,
          child: Container(
            margin: EdgeInsets.only(right: 50.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 40.h,
                  width: 40.h,
                ),
                SizedBox(width: 12.w),
                Text(
                  "Kelime Setleri",
                  style: GoogleFonts.nunito(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: _isDarkMode ? Colors.white : Colors.black87,
              size: 26.sp,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredProducts = _products;
                }
                _isSearching = !_isSearching;
                if (_isSearching) {
                  _searchFocusNode.requestFocus();
                }
              });
            },
          ),
          SizedBox(width: 12.w),
        ],
      ),
      body: Container(
        color: _isDarkMode ? Colors.grey[850] : Colors.white,
        child: Column(
          children: [
            _buildProBanner(isVip),
            Expanded(
              child: _products == null
                  ? Center(child: LogoLoadingIndicator())
                  : Obx(() => ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: _getSortedProducts().length + 2, // +1 son arananlar kartı için
                itemBuilder: (context, index) {
                  // İlk öğe olarak son arananlar kartını göster
                  if (index == 0) {
                    return _buildRecentSearchesCard();
                  }
                  if (index == 1) {
                    return _buildPersonalCollectionCard(); // Yeni kart
                  }
                  // Diğer öğeler için gerçek index 1 azalmalı
                  return _buildProductItem(
                    _getSortedProducts()[index - 1],
                    index - 1,
                    isVip,
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPersonalCollectionCard() {
    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1), // Modern indigo
            Color(0xFF4F46E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Kişisel koleksiyon sayfasına git
          },
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.collections_bookmark,
                  size: 80.sp,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Benim Koleksiyonum',
                            style: GoogleFonts.nunito(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // "YAKINDA" rozeti
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'YAKINDA',
                            style: GoogleFonts.nunito(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Kendi kelime setlerini oluştur',
                      style: GoogleFonts.nunito(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProBanner(bool isVip) {
    if (!isVip && !_isFreeMode) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFB800), Color(0xFFFF9600)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MarketPage()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 45.h,
                  width: 45.h,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Kelibu',
                            style: GoogleFonts.nunito(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PRO',
                              style: GoogleFonts.nunito(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFB800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Premium özellikleri keşfet',
                        style: GoogleFonts.nunito(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 24.sp, color: Colors.white),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildProductItem(Product product, int index, bool isVip) {
    final colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF9600),
      Color(0xFFFF4B4B)
    ];
    final icons = [
      Icons.school,
      Icons.book,
      Icons.psychology,
      Icons.translate,
      Icons.menu_book
    ];
    final color = colors[index % colors.length];
    final icon = icons[index % icons.length];
    final isUnlocked = _isFreeMode || isVip || product.id == 46 || product.id == 41;
    final isPinned = _pinnedProducts[product.id ?? 0] ?? false;

    return Container(
      height: 100.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked
              ? () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordListScreen(
                categoryId: product.classroom?.id ?? 0,
                categoryName:
                product.classroom?.title ?? 'Varsayılan Başlık',
              ),
            ),
          )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 80.sp,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.classroom?.title ?? 'Varsayılan Başlık',
                            style: GoogleFonts.nunito(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnlocked)
                          GestureDetector(
                            onTap: () => _togglePin(product.id ?? 0),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              transform: Matrix4.identity()
                                ..translate(
                                  0.0,
                                  isPinned ? -4.0 : 0.0,
                                ),
                              child: Icon(
                                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: 0.0,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                        minHeight: 4.h,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlocked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 24.sp
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Premium',
                          style: GoogleFonts.nunito(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
// WordSetsPage'deki _buildRecentSearchesCard method'unu bu şekilde güncelleyin

  Widget _buildRecentSearchesCard() {
    return FutureBuilder<int>(
      future: _getSearchHistoryCount(),
      builder: (context, snapshot) {
        final searchCount = snapshot.data ?? 0;

        return Container(
          height: 100.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF9C27B0),
                Color(0xFF7B1FA2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF9C27B0).withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: searchCount > 0
                  ? () => navigateToGameModeFromSearchHistory()
                  : () {
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
                          Icons.search,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Önce sözlükten kelime arayın',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Color(0xFF9C27B0),
                  borderRadius: 16,
                  duration: Duration(seconds: 2),
                  snackPosition: SnackPosition.TOP,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      Icons.history,
                      size: 80.sp,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              searchCount > 0 ? Icons.star : Icons.search,
                              color: searchCount > 0 ? Colors.amber : Colors.white70,
                              size: 24.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Son Aradığım Kelimeler',
                                style: GoogleFonts.nunito(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$searchCount kelime',
                                style: GoogleFonts.nunito(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Spacer(),
                            Text(
                              searchCount > 0 ? 'Oyna!' : 'Henüz yok',
                              style: GoogleFonts.nunito(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: searchCount > 0 ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}