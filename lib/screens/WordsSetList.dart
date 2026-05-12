import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/Models/product.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:kelibu/screens/loadingIndicator.dart';
import 'package:kelibu/screens/personelcollection/personelcollenction.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/sub_provider.dart';
import 'game_mod.dart';
import 'market_store.dart';

class WordSetsPage extends StatefulWidget {
  const WordSetsPage({Key? key}) : super(key: key);

  @override
  _WordSetsPageState createState() => _WordSetsPageState();
}

class _WordSetsPageState extends State<WordSetsPage> {
  // ✅ Tüm state'ler artık Rx
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Product> _filteredProducts = <Product>[].obs;
  final RxBool _isDarkMode = false.obs;
  final RxBool _isFreeMode = false.obs;
  final RxBool _isSearching = false.obs;
  final RxBool _isLoading = false.obs;
  final RxMap<int, bool> _pinnedProducts = <int, bool>{}.obs;
  final RxInt _searchHistoryCount = 0.obs;

  // Non-reactive
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _storage = GetStorage();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _checkFreeMode();
    _initializeData();
    _loadSearchHistoryCount();
  }

  Future<void> _initializeData() async {
    await _fetchProducts();
    await _loadPinnedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistoryCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searchHistory = prefs.getStringList('search_history') ?? [];
    _searchHistoryCount.value = searchHistory.length;
  }

  Future<void> _loadPinnedProducts() async {
    try {
      final pinnedSets = await _apiService.getPinnedSets();
      Map<int, bool> pinnedMap = {};

      for (var pinnedSet in pinnedSets) {
        final wordSetId = pinnedSet['word_set_id'] ?? pinnedSet['id'];
        final product = _products.firstWhereOrNull(
              (p) {
            return p.classroom?.id == wordSetId;
          },
        );
        if (product?.id != null) {
          pinnedMap[product!.id!] = true;
        }
      }

      _pinnedProducts.value = pinnedMap;

      await _storage.write(
        'pinnedProducts',
        _pinnedProducts.keys.toList(),
      );
    } catch (e) {
      final pinnedList = _storage.read<List>('pinnedProducts') ?? [];
      _pinnedProducts.value = Map.fromEntries(
        pinnedList.map((id) => MapEntry(id as int, true)),
      );
    }
  }

  Future<void> navigateToGameModeFromSearchHistory() async {
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
      List<int> searchHistoryIds = await _getSearchHistoryIds();

      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (searchHistoryIds.isEmpty) {
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

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameModeScreen(
            studySetName: searchHistoryIds.join(','),
            classroomId: 1,
            studySetId: 1,
          ),
        ),
      );

      if (result != null) {
        // Gerekirse sayfa yenileme işlemleri
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

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
      } catch (e) {}
    }

    return wordIds;
  }

  Future<void> _togglePin(int productId) async {
    HapticFeedback.mediumImpact();

    final product = _products.firstWhereOrNull((p) => p.id == productId);
    final wordSetId = product?.classroom?.id;

    if (wordSetId == null) {
      return;
    }

    try {
      if (_pinnedProducts.containsKey(productId)) {
        await _apiService.unpinWordSet(wordSetId);
        _pinnedProducts.remove(productId);

        _showSnackbar(
          icon: Icons.push_pin_outlined,
          message: 'Sabitleme kaldırıldı',
          color: Colors.green,
        );
      } else {
        await _apiService.pinWordSet(wordSetId);
        _pinnedProducts[productId] = true;

        _showSnackbar(
          icon: Icons.push_pin,
          message: 'Liste başına sabitlendi',
          color: Color(0xFF1CB0F6),
        );
      }

      await _storage.write(
        'pinnedProducts',
        _pinnedProducts.keys.toList(),
      );
    } on ApiException catch (e) {
      _showSnackbar(
        icon: Icons.error_outline,
        message: e.message,
        color: Colors.red,
      );
    } catch (e) {
      _showSnackbar(
        icon: Icons.error_outline,
        message: 'Bir hata oluştu',
        color: Colors.red,
      );
    }
  }

  void _showSnackbar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode.value = prefs.getBool("darkMode") ?? false;
  }

  Future<void> _fetchProducts() async {
    if (_isLoading.value) return;

    _isLoading.value = true;

    try {
      final products = await _apiService.fetchActiveProducts();

      if (mounted) {
        _products.value = products;
        _filteredProducts.value = products;
      }
    } catch (error) {
    } finally {
      if (mounted) {
        _isLoading.value = false;
      }
    }
  }

  Future<void> _checkFreeMode() async {
    try {
      final isFree = await ApiService().checkFreeMode();
      _isFreeMode.value = isFree;
    } catch (error) {}
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      _filteredProducts.value = _products.toList();
      return;
    }

    _filteredProducts.value = _products.where((product) {
      final title = product.classroom?.title?.toLowerCase() ?? '';
      return title.contains(query.toLowerCase());
    }).toList();
  }

  List<Product> _getSortedProducts() {
    final currentProducts = _filteredProducts.isNotEmpty ? _filteredProducts : _products;
    return List<Product>.from(currentProducts)
      ..sort((a, b) {
        final aPinned = _pinnedProducts[a.id ?? 0] ?? false;
        final bPinned = _pinnedProducts[b.id ?? 0] ?? false;
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return 0;
      });
  }

  void _toggleSearch() {
    if (_isSearching.value) {
      _searchController.clear();
      _filteredProducts.value = _products.toList();
    }
    _isSearching.value = !_isSearching.value;
    if (_isSearching.value) {
      _searchFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVip = Provider.of<SubscriptionProvider>(context).isVip;

    return Obx(() => Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode.value ? Colors.grey[900] : Colors.white,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        iconTheme: IconThemeData(
          color: _isDarkMode.value ? Colors.white : Colors.black87,
          size: 26.sp,
        ),
        titleSpacing: 0,
        leadingWidth: 50.w,
        title: _isSearching.value
            ? TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: GoogleFonts.nunito(
            color: _isDarkMode.value ? Colors.white : Colors.black87,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Set ara...',
            hintStyle: GoogleFonts.nunito(
              color: _isDarkMode.value ? Colors.white70 : Colors.black54,
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
                    color: _isDarkMode.value ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching.value ? Icons.close : Icons.search,
              color: _isDarkMode.value ? Colors.white : Colors.black87,
              size: 26.sp,
            ),
            onPressed: _toggleSearch,
          ),
          SizedBox(width: 12.w),
        ],
      ),
      body: Container(
        color: _isDarkMode.value ? Colors.grey[850] : Colors.white,
        child: Column(
          children: [
            _buildProBanner(isVip),
            Expanded(
              child: _isLoading.value && _products.isEmpty
                  ? Center(child: LogoLoadingIndicator())
                  : ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: _getSortedProducts().length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildRecentSearchesCard();
                  }
                  if (index == 1) {
                    return _buildPersonalCollectionCard();
                  }
                  return _buildProductItem(
                    _getSortedProducts()[index - 2],
                    index - 2,
                    isVip,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildPersonalCollectionCard() {
    return Container(
      height: 75.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonalCollectionPage(),
              ),
            );
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
    if (!isVip && !_isFreeMode.value) {
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
    final isUnlocked = _isFreeMode.value || isVip || product.id == 46 || product.id == 41;
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
                categoryName: product.classroom?.title ?? 'Varsayılan Başlık',
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
                        Icon(Icons.lock, color: Colors.white, size: 24.sp),
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

  Widget _buildRecentSearchesCard() {
    final searchCount = _searchHistoryCount.value;

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
  }
}