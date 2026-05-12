import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api.dart';
import '../AddWordPage.dart';
import '../loadingIndicator.dart';
import '../word_set_detail.dart';
import 'detail/DetailPage.dart';

class PersonalCollectionPage extends StatefulWidget {
  const PersonalCollectionPage({Key? key}) : super(key: key);

  @override
  _PersonalCollectionPageState createState() => _PersonalCollectionPageState();
}

class _PersonalCollectionPageState extends State<PersonalCollectionPage> {
  bool _isDarkMode = false;
  List<PersonalCollection> _collections = [];
  bool _isLoading = false; // ✅ Loading state

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _loadCollections();
  }

  Widget _buildDiscoverTab() {
    // Örnek paylaşılan koleksiyonlar
    final sharedCollections = [
      SharedCollection(
        id: 101,
        name: "TOEFL Vocabulary",
        icon: Icons.school,
        author: "English Teacher",
        authorAvatar: "assets/avatars/teacher.png",
        wordCount: 156,
        downloads: 2341,
        rating: 4.8,
        tags: ["English", "TOEFL", "Academic"],
        isPopular: true,
      ),
      SharedCollection(
        id: 102,
        name: "Travel Phrases",
        icon: Icons.flight,
        author: "World Explorer",
        authorAvatar: "assets/avatars/explorer.png",
        wordCount: 89,
        downloads: 1872,
        rating: 4.6,
        tags: ["Travel", "Phrases", "Practical"],
        isPopular: false,
      ),
      SharedCollection(
        id: 103,
        name: "Business English",
        icon: Icons.business_center,
        author: "Corporate Pro",
        authorAvatar: "assets/avatars/business.png",
        wordCount: 203,
        downloads: 3456,
        rating: 4.9,
        tags: ["Business", "Professional", "Meetings"],
        isPopular: true,
      ),
      SharedCollection(
        id: 104,
        name: "Daily Conversations",
        icon: Icons.chat,
        author: "Native Speaker",
        authorAvatar: "assets/avatars/native.png",
        wordCount: 127,
        downloads: 1234,
        rating: 4.7,
        tags: ["Conversation", "Daily", "Beginner"],
        isPopular: false,
      ),
    ];

    return Column(
      children: [
        // Arama çubuğu
        Container(
          margin: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            style: GoogleFonts.nunito(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Koleksiyon ara...',
              hintStyle: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ),

        // Popüler etiket
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Color(0xFFFFC800).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFFFC800), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: Color(0xFFFFC800),
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Popüler',
                      style: GoogleFonts.nunito(
                        color: Color(0xFFFFC800),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Koleksiyon listesi
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: sharedCollections.length,
            itemBuilder: (context, index) {
              final collection = sharedCollections[index];
              return _buildSharedCollectionCard(collection);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSharedCollectionCard(SharedCollection collection) {
    final colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF9600),
      Color(0xFF9C27B0),
      Color(0xFF4CAF50),
      Color(0xFFE91E63),
    ];
    final color = colors[collection.id.hashCode % colors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey[300]!)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Koleksiyon detayına git
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // İkon
                    Container(
                      width: 50.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        collection.icon,
                        color: color,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Başlık ve yazar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  collection.name,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (collection.isPopular)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFC800),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'POPÜLER',
                                    style: GoogleFonts.nunito(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'by ${collection.author}',
                            style: GoogleFonts.nunito(
                              fontSize: 14.sp,
                              color:
                                  _isDarkMode ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // İstatistikler
                Row(
                  children: [
                    _buildStatItem(Icons.download, '${collection.downloads}'),
                    SizedBox(width: 16.w),
                    _buildStatItem(Icons.star, collection.rating.toString()),
                  ],
                ),

                SizedBox(height: 12.h),

                // Etiketler
                Wrap(
                  spacing: 8.w,
                  children: collection.tags
                      .map((tag) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.nunito(
                                fontSize: 12.sp,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),

                SizedBox(height: 16.h),

                // İndir butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Koleksiyonu indir
                      _downloadCollection(collection);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Koleksiyonu İndir',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: _isDarkMode ? Colors.white54 : Colors.black54,
          size: 16.sp,
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 14.sp,
            color: _isDarkMode ? Colors.white54 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _downloadCollection(SharedCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionDetailPage(),
      ),
    );
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true; // ✅ Yükleniyor
    });

    try {
      final apiService = ApiService();
      final collections = await apiService.getMyWordSets();

      setState(() {
        _collections = collections
            .map((json) => PersonalCollection(
                  id: json['id'],
                  name: json['set_name'],
                  icon: Icons.collections_bookmark,
                  isShared: json['is_public'] ?? false,
                  wordCount: json['set_words_count'] ?? 0,
                  createdAt: DateTime.parse(json['created_at']),
                ))
            .toList();
        _isLoading = false; // ✅ Yükleme bitti
      });
    } catch (e) {
      setState(() {
        _collections = [];
        _isLoading = false; // ✅ Hata durumunda da dur
      });
    }
  }

  void _showCreateCollectionDialog() {
    final TextEditingController nameController = TextEditingController();
    bool isShared = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Yeni Koleksiyon',
            style: GoogleFonts.nunito(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İsim girişi
              Text(
                'Koleksiyon Adı',
                style: GoogleFonts.nunito(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: nameController,
                style: GoogleFonts.nunito(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'Örn: Günlük Kelimeler',
                  hintStyle: GoogleFonts.nunito(
                    color: _isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: _isDarkMode ? Colors.grey[700] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 20.h),

              // Paylaşım ayarı
              Container(
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.grey[700] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paylaşıma Açık',
                            style: GoogleFonts.nunito(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Diğer kullanıcılar (Yakında)',
                            style: GoogleFonts.nunito(
                              fontSize: 12.sp,
                              color:
                                  _isDarkMode ? Colors.white54 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isShared,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        setDialogState(() => isShared = value);
                      },
                      activeColor: Color(0xFF58CC02),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: GoogleFonts.nunito(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _createCollection(nameController.text.trim(),
                      Icons.collections_bookmark, isShared);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1CB0F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Oluştur',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<IconData> _getAvailableIcons() {
    return [
      Icons.book,
      Icons.school,
      Icons.translate,
      Icons.psychology,
      Icons.wb_sunny,
      Icons.nightlight_round,
      Icons.business_center,
      Icons.sports_soccer,
      Icons.music_note,
      Icons.palette,
      Icons.local_cafe,
      Icons.flight,
      Icons.pets,
      Icons.favorite,
      Icons.star,
    ];
  }

  void _createCollection(String name, IconData icon, bool isShared) async {
    try {
      // API'ye kaydet
      final apiService = ApiService();
      final box = await Hive.openBox('userBox');
      final userName = box.get('username')?.toString() as String;

      final result = await apiService.createWordSet(
        setName: name,
        founder: userName,
        isPublic: isShared,
        isCorporate: false,
      );

      if (result['success'] == true) {
        // Başarılı ise local'e de ekle
        final newCollection = PersonalCollection(
          id: result['data']['id'] ?? DateTime.now().millisecondsSinceEpoch,
          name: name,
          icon: icon,
          isShared: isShared,
          wordCount: 0,
          createdAt: DateTime.now(),
        );

        setState(() {
          _collections.insert(0, newCollection);
        });

        // SharedPreferences'a kaydet
        await _saveCollections();

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
                  result['message'] ?? 'Koleksiyon oluşturuldu!',
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
      }
    } on ApiException catch (e) {
      // Hata mesajı göster
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
                e.message,
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
        duration: Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      );
    } catch (e) {
      Get.snackbar(
        "",
        "",
        titleText: Container(),
        messageText: Text(
          'Bir hata oluştu. Lütfen tekrar deneyin.',
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

  Future<void> _saveCollections() async {
    // SharedPreferences'a koleksiyonları kaydet
    // JSON formatında kaydedeceğiz
  }

  void _showCollectionOptions(PersonalCollection collection) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.sp),
              child: Column(
                children: [
                  Text(
                    collection.name,
                    style: GoogleFonts.nunito(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _buildOptionTile(
                    icon: Icons.edit,
                    title: 'Düzenle',
                    onTap: () {
                      Navigator.pop(context);
                      // Düzenleme sayfasına git
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.add,
                    title: 'Kelime Ekle',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddWordPage(
                            setId: collection.id,
                            setName: collection.name,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.share,
                    title: 'Paylaş',
                    onTap: () {
                      Navigator.pop(context);
                      // Paylaşma işlemi
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.delete,
                    title: 'Sil',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(collection);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? (_isDarkMode ? Colors.white70 : Colors.black54),
        size: 24.sp,
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: color ?? (_isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showDeleteConfirmation(PersonalCollection collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Koleksiyonu Sil',
          style: GoogleFonts.nunito(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          '"${collection.name}" koleksiyonunu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: GoogleFonts.nunito(
            fontSize: 16.sp,
            color: _isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteCollection(collection);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sil',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteCollection(PersonalCollection collection) {
    setState(() {
      _collections.removeWhere((c) => c.id == collection.id);
    });
    _saveCollections();

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
              Icons.delete,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Koleksiyon silindi',
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
      duration: Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
        appBar: AppBar(
          backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: _isDarkMode ? Colors.white : Colors.black87,
            size: 24.sp,
          ),
          title: Text(
            "Kelime Setleri",
            style: GoogleFonts.nunito(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          centerTitle: false,
          actions: [
            // Keşfet butonu sağ üstte
            Container(
              margin: EdgeInsets.only(right: 16.w),
              child: IconButton(
                onPressed: () {
                  // ✅ Yakında açılacak mesajı
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
                            Icons.explore,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Keşfet özelliği yakında açılacak!',
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  );
                },
                icon: Container(
                  padding: EdgeInsets.all(8.sp),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF58CC02),
                        Color(0xFF4CAF50),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.explore,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? LogoLoadingIndicator()
            : (_collections.isEmpty
                ? _buildEmptyState()
                : _buildCollectionsList()),
        floatingActionButton: Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(0xFF1CB0F6),
                Color(0xFF0EA5E9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1CB0F6).withOpacity(0.4),
                blurRadius: 16,
                offset: Offset(0, 8),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showCreateCollectionDialog,
              borderRadius: BorderRadius.circular(20),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 36.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDiscoverSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.sp),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF58CC02), Color(0xFF4CAF50)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(Icons.explore, color: Colors.white, size: 24.sp),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Keşfet',
                      style: GoogleFonts.nunito(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // Content
              Expanded(
                child: _buildDiscoverContent(controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverContent(ScrollController controller) {
    final sharedCollections = [
      SharedCollection(
        id: 101,
        name: "TOEFL Vocabulary",
        icon: Icons.school,
        author: "English Teacher",
        authorAvatar: "assets/avatars/teacher.png",
        wordCount: 156,
        downloads: 2341,
        rating: 4.8,
        tags: ["English", "TOEFL", "Academic"],
        isPopular: true,
      ),
      SharedCollection(
        id: 102,
        name: "Travel Phrases",
        icon: Icons.flight,
        author: "World Explorer",
        authorAvatar: "assets/avatars/explorer.png",
        wordCount: 89,
        downloads: 1872,
        rating: 4.6,
        tags: ["Travel", "Phrases", "Practical"],
        isPopular: false,
      ),
      SharedCollection(
        id: 103,
        name: "Business English",
        icon: Icons.business_center,
        author: "Corporate Pro",
        authorAvatar: "assets/avatars/business.png",
        wordCount: 203,
        downloads: 3456,
        rating: 4.9,
        tags: ["Business", "Professional", "Meetings"],
        isPopular: true,
      ),
    ];

    return ListView(
      controller: controller,
      padding: EdgeInsets.all(16.sp),
      children: [
        // Arama
        Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            style: GoogleFonts.nunito(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Koleksiyon ara...',
              hintStyle: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _isDarkMode ? Colors.white54 : Colors.black54,
              ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ),
        SizedBox(height: 24.h),
        // Popüler tag
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFC800), Color(0xFFFF9600)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department,
                      color: Colors.white, size: 18.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Popüler Setler',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Collections
        ...sharedCollections
            .map((collection) => _buildDiscoverCard(collection)),
      ],
    );
  }

  Widget _buildDiscoverCard(SharedCollection collection) {
    final colors = [
      [Color(0xFF58CC02), Color(0xFF4CAF50)],
      [Color(0xFF1CB0F6), Color(0xFF0EA5E9)],
      [Color(0xFFFFC800), Color(0xFFFF9600)],
      [Color(0xFF9C27B0), Color(0xFF8E24AA)],
      [Color(0xFFE91E63), Color(0xFFC2185B)],
    ];
    final colorPair = colors[collection.id.hashCode % colors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colorPair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorPair[0].withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _downloadCollection(collection),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(20.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.sp),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(collection.icon,
                          color: Colors.white, size: 28.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            collection.name,
                            style: GoogleFonts.nunito(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'by ${collection.author}',
                            style: GoogleFonts.nunito(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (collection.isPopular)
                      Icon(Icons.local_fire_department,
                          color: Colors.white, size: 24.sp),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _buildWhiteStatItem(
                        Icons.article, '${collection.wordCount}'),
                    SizedBox(width: 16.w),
                    _buildWhiteStatItem(
                        Icons.download, '${collection.downloads}'),
                    SizedBox(width: 16.w),
                    _buildWhiteStatItem(Icons.star, '${collection.rating}'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhiteStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 16.sp),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.nunito(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
              color: (_isDarkMode ? Colors.white : Color(0xFF1CB0F6))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.collections_bookmark,
              size: 64.sp,
              color: _isDarkMode
                  ? Colors.white38
                  : Color(0xFF1CB0F6).withOpacity(0.6),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Henüz koleksiyonunuz yok',
            style: GoogleFonts.nunito(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              'İlk koleksiyonunuzu oluşturmak için aşağıdaki + butonuna tıklayın',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 16.sp,
                color: _isDarkMode ? Colors.white54 : Colors.black38,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return _buildCollectionCard(collection);
      },
    );
  }

  Widget _buildCollectionCard(PersonalCollection collection) {
    final colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF9600),
      Color(0xFF9C27B0),
      Color(0xFF4CAF50),
      Color(0xFFE91E63),
    ];
    final color = colors[collection.id.hashCode % colors.length];

    return Container(
      height: 120.h,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WordSetDetailPage(
                  setId: collection.id,
                  setName: collection.name,
                ),
              ),
            ).then((_) {
              _loadCollections();
            });
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
                          Icons.collections_bookmark,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            collection.name,
                            style: GoogleFonts.nunito(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (collection.isShared)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Paylaşımlı',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(collection.createdAt),
                              style: GoogleFonts.nunito(
                                fontSize: 12.sp,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        // ✅ DÜZENLE VE SİL BUTONLARI
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Düzenle
                            IconButton(
                              onPressed: () {
                                _showEditDialog(collection);
                              },
                              icon: Icon(
                                Icons.edit,
                                color: Colors.white.withOpacity(0.9),
                                size: 22.sp,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8.w),
                            // Sil
                            IconButton(
                              onPressed: () {
                                _showDeleteConfirmation(collection);
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.white.withOpacity(0.9),
                                size: 22.sp,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
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

// ✅ Düzenleme fonksiyonu ekle
  void _showEditDialog(PersonalCollection collection) {
    final nameController = TextEditingController(text: collection.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Seti Düzenle',
          style: GoogleFonts.nunito(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: GoogleFonts.nunito(
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            labelText: 'Set Adı',
            labelStyle: GoogleFonts.nunito(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
            filled: true,
            fillColor: _isDarkMode ? Colors.grey[700] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.nunito(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _updateWordSet(collection.id, nameController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1CB0F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Kaydet',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

// ✅ Güncelleme fonksiyonu ekle
  Future<void> _updateWordSet(int setId, String newName) async {
    try {
      final apiService = ApiService();
      await apiService.updateWordSet(
        setId: setId,
        setName: newName,
      );

      // Listeyi yenile
      _loadCollections();

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
            Text(
              'Set güncellendi',
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
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Dün';
    } else if (difference < 7) {
      return '$difference gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class PersonalCollection {
  final int id;
  final String name;
  final IconData icon;
  final bool isShared;
  final int wordCount;
  final DateTime createdAt;

  PersonalCollection({
    required this.id,
    required this.name,
    required this.icon,
    required this.isShared,
    required this.wordCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint,
      'isShared': isShared,
      'word_count': wordCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PersonalCollection.fromJson(Map<String, dynamic> json) {
    return PersonalCollection(
      id: json['id'],
      name: json['name'],
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      isShared: json['isShared'],
      wordCount: json['word_count'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}

class SharedCollection {
  final int id;
  final String name;
  final IconData icon;
  final String author;
  final String authorAvatar;
  final int wordCount;
  final int downloads;
  final double rating;
  final List<String> tags;
  final bool isPopular;

  SharedCollection({
    required this.id,
    required this.name,
    required this.icon,
    required this.author,
    required this.authorAvatar,
    required this.wordCount,
    required this.downloads,
    required this.rating,
    required this.tags,
    required this.isPopular,
  });
}
