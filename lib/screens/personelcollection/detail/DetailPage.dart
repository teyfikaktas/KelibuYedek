import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionDetailPage extends StatefulWidget {
  const CollectionDetailPage({Key? key}) : super(key: key);

  @override
  _CollectionDetailPageState createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  bool _isDarkMode = false;
  bool _isAddedToMyCollection = false;

  // Demo collection data
  final String collectionName = "TOEFL Vocabulary";
  final IconData collectionIcon = Icons.school;
  final String collectionAuthor = "English Teacher";
  final int wordCount = 156;
  final int downloads = 2341;
  final double rating = 4.8;
  final List<String> tags = ["English", "TOEFL", "Academic"];
  final bool isPopular = true;

  // Demo words data
  final List<Map<String, String>> words = [
    {
      'english': 'Serendipity',
      'turkish': 'Şans eseri güzel bir şey bulma',
      'pronunciation': '/ˌserənˈdɪpɪti/',
      'example': 'It was pure serendipity that we met at the coffee shop.',
      'exampleTurkish': 'Kahve dükkanında karşılaşmamız tamamen şans eseriydi.',
      'difficulty': 'Advanced',
    },
    {
      'english': 'Ubiquitous',
      'turkish': 'Her yerde bulunan',
      'pronunciation': '/juːˈbɪkwɪtəs/',
      'example': 'Smartphones have become ubiquitous in modern society.',
      'exampleTurkish':
          'Akıllı telefonlar modern toplumda her yerde bulunur hale geldi.',
      'difficulty': 'Advanced',
    },
    {
      'english': 'Ephemeral',
      'turkish': 'Geçici, kısa süreli',
      'pronunciation': '/ɪˈfemərl/',
      'example': 'The beauty of cherry blossoms is ephemeral.',
      'exampleTurkish': 'Kiraz çiçeklerinin güzelliği geçicidir.',
      'difficulty': 'Advanced',
    },
    {
      'english': 'Profound',
      'turkish': 'Derin, köklü',
      'pronunciation': '/prəˈfaʊnd/',
      'example': 'The book had a profound impact on my thinking.',
      'exampleTurkish': 'Kitap düşüncelerim üzerinde derin bir etki bıraktı.',
      'difficulty': 'Intermediate',
    },
    {
      'english': 'Ambiguous',
      'turkish': 'Belirsiz, muğlak',
      'pronunciation': '/æmˈbɪɡjuəs/',
      'example': 'His answer was deliberately ambiguous.',
      'exampleTurkish': 'Cevabı kasıtlı olarak belirsizdi.',
      'difficulty': 'Intermediate',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Color get _primaryColor => Color(0xFF1CB0F6);

  void _addToMyCollection() {
    HapticFeedback.mediumImpact();
    setState(() => _isAddedToMyCollection = true);

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
            child: Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '"$collectionName" favorilere eklendi! (Demo)',
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
      duration: Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );
  }

  void _removeFromMyCollection() {
    HapticFeedback.lightImpact();
    setState(() => _isAddedToMyCollection = false);

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
            child: Icon(Icons.remove_circle, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            'Favorilerden kaldırıldı',
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
      duration: Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );
  }

  void _shareCollection() {
    HapticFeedback.lightImpact();
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
            child: Icon(Icons.share, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            'Koleksiyon paylaşıldı!',
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
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 280.h,
            floating: false,
            pinned: true,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -50,
                      top: 50,
                      child: Icon(
                        collectionIcon,
                        size: 200.sp,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 100.h, 20.w, 20.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon and popular badge
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16.sp),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  collectionIcon,
                                  color: Colors.white,
                                  size: 32.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              if (isPopular)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 6.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: _primaryColor,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'POPÜLER',
                                        style: GoogleFonts.nunito(
                                          color: _primaryColor,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Title
                          Text(
                            collectionName,
                            style: GoogleFonts.nunito(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8.h),

                          // Author
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12.r,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 16.sp,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'by $collectionAuthor',
                                style: GoogleFonts.nunito(
                                  fontSize: 16.sp,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Stats
                          Row(
                            children: [
                              _buildStat(Icons.quiz, '$wordCount'),
                              SizedBox(width: 20.w),
                              _buildStat(Icons.download, '$downloads'),
                              SizedBox(width: 20.w),
                              _buildStat(Icons.star, rating.toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _shareCollection,
                icon: Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Action buttons
                Container(
                  margin: EdgeInsets.all(16.sp),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAddedToMyCollection
                              ? _removeFromMyCollection
                              : _addToMyCollection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAddedToMyCollection
                                ? Colors.orange
                                : _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isAddedToMyCollection
                                    ? Icons.remove
                                    : Icons.add,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _isAddedToMyCollection
                                    ? 'Favorilerden Çıkar'
                                    : 'Favorilere Ekle',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            // Quiz başlat - demo
                            Get.snackbar(
                              "Quiz",
                              "Quiz özelliği geliştiriliyor!",
                              backgroundColor: _primaryColor,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.TOP,
                            );
                          },
                          icon: Icon(
                            Icons.play_arrow,
                            color: _primaryColor,
                            size: 28.sp,
                          ),
                          padding: EdgeInsets.all(16.sp),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tags
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Etiketler',
                        style: GoogleFonts.nunito(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: tags
                            .map((tag) => Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.nunito(
                                      fontSize: 14.sp,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // Words section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kelimeler (${words.length})',
                            style: GoogleFonts.nunito(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.snackbar(
                                "Tümünü Gör",
                                "Tüm kelimeler özelliği geliştiriliyor!",
                                backgroundColor: _primaryColor,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.TOP,
                              );
                            },
                            child: Text(
                              'Tümünü Gör',
                              style: GoogleFonts.nunito(
                                color: _primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Words list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final word = words[index];
                return _buildWordCard(word);
              },
              childCount: words.length,
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(height: 100.h),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 18.sp,
        ),
        SizedBox(width: 6.w),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16.sp,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(Map<String, String> word) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Get.snackbar(
              "Kelime Detayı",
              "Kelime detay sayfası geliştiriliyor!",
              backgroundColor: _primaryColor,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word['english'] ?? '',
                            style: GoogleFonts.nunito(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            word['pronunciation'] ?? '',
                            style: GoogleFonts.nunito(
                              fontSize: 14.sp,
                              color: _primaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(word['difficulty'] ?? '')
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getDifficultyColor(word['difficulty'] ?? '')
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        word['difficulty'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 12.sp,
                          color: _getDifficultyColor(word['difficulty'] ?? ''),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  word['turkish'] ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 16.sp,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.sp),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[700] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word['example'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 14.sp,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        word['exampleTurkish'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 13.sp,
                          color: _isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Color(0xFF4CAF50);
      case 'intermediate':
        return Color(0xFFFFC800);
      case 'advanced':
        return Color(0xFFFF5722);
      default:
        return Colors.grey;
    }
  }
}
