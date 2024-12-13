import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/Models/category.dart';
import 'package:kelibu/screens/loadingIndicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class WordSetsPage extends StatefulWidget {
  const WordSetsPage({Key? key}) : super(key: key);

  @override
  _WordSetsPageState createState() => _WordSetsPageState();
}

class _WordSetsPageState extends State<WordSetsPage> {
  List<Package>? _packages;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _fetchPackages();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = !_isDarkMode;
      prefs.setBool("darkMode", _isDarkMode);
    });
  }

  Future<void> _fetchPackages() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int currentUserId = userProvider.userId;

    try {
      List<Package> packages =
          await ApiService().fetchCategories(currentUserId);
      setState(() {
        _packages = packages;
      });
    } catch (error) {
      print("API Error: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kelime Setleriniz",
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme:
            IconThemeData(color: _isDarkMode ? Colors.white : Colors.black87),
      ),
      body: Container(
        color: _isDarkMode ? Colors.grey[850] : Colors.white,
        child: _packages == null
            ? Center(child: LogoLoadingIndicator())
            : _packages!.isEmpty
                ? Center(
                    child: Text(
                      "Henüz kelime setiniz yok. Yeni setler ekleyerek öğrenmeye başlayın!",
                      style: GoogleFonts.nunito(
                        fontSize: 18.sp,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _packages!.length,
                    itemBuilder: (context, index) {
                      return _buildPackageItem(_packages![index], index);
                    },
                  ),
      ),
    );
  }

  Widget _buildPackageItem(Package package, int index) {
    final List<Color> colors = [
      Color(0xFF58CC02),
      Color(0xFF1CB0F6),
      Color(0xFFFFC800),
      Color(0xFFFF9600),
      Color(0xFFFF4B4B),
    ];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => _onListItemTap(package.classroom?.id ?? 0,
          package.classroom?.title ?? 'Varsayılan Başlık'),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: _isDarkMode ? color.withOpacity(0.7) : color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode ? Colors.black26 : color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.school,
                size: 100,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.classroom?.title ?? 'Varsayılan Başlık',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: 0.7,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onListItemTap(int categoryId, String categoryName) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => WordListScreen(
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    ));
  }
}
