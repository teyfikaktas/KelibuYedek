import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../variables.dart';
import '../game_mod.dart';
import 'WordQuizScreenGame.dart';

class QuizSettingsScreen extends StatefulWidget {
  final List<int> wordIds;

  const QuizSettingsScreen({
    super.key,
    required this.wordIds,
  });

  @override
  _QuizSettingsScreenState createState() => _QuizSettingsScreenState();
}

class _QuizSettingsScreenState extends State<QuizSettingsScreen> {
  bool _isDarkMode = false;
  final ApiService _apiService = ApiService();

  // Seçili değerler
  int selectedWordCount = 20;
  String selectedCategory = 'Karışık';
  String selectedQuestionType = 'Boşluk Doldurma';

  // Seçenekler
  final List<int> wordCounts = [10,20, 30, 40, 50];
  final List<String> categories = [
    'Karışık',
    'Fen Bilimleri',
    'Sağlık Bilimleri',
  ];
  final List<String> questionTypes = [
    'Boşluk Doldurma',
    'Anlam Eşleştirme',
    'Çoktan Seçmeli',
    'Doğru-Yanlış',
    'Kelime Tahmin',
  ];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    print(widget.wordIds);
    ApiService().sendUserLog(
      type: 'screen_entry',
      log: 'Kullanıcı quiz ayarları ekranına giriş yaptı.',
    );
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void _startQuiz() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CustomLoadingIndicator()),
      );

      List<Map<String, dynamic>> questions;

      if (selectedCategory == 'Karışık') {
        questions = await _apiService.getWordQuestionsByWordIds(
          wordIds: widget.wordIds,
          count: selectedWordCount,
        );
      } else {
        final allQuestions = await _apiService.getWordQuestionsByCategory(
          selectedCategory!,
        );
        allQuestions.shuffle();
        questions = allQuestions.take(selectedWordCount).toList();
      }

      Navigator.pop(context);

      if (questions.isEmpty) {
        _showNoQuestionsDialog();
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordQuizScreen(
            questions: questions,
            questionType: selectedQuestionType,
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNoQuestionsDialog() {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors["cardBackground"],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9600).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  size: 56,
                  color: Color(0xFFFF9600),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Soru Bulunamadı',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors["text"],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Bu kategori için henüz soru eklenmemiş.\nYakında eklenecek!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colors["text"]?.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1CB0F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'TAMAM',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Map<String, Color?> colors) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: colors["text"]?.withOpacity(0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildWordCountSelector(Map<String, Color?> colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors["iconBackground"],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.numbers,
                  color: colors["iconColor"],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Kelime Sayısı',
                style: GoogleFonts.poppins(
                  color: colors["text"],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: wordCounts.length,
            itemBuilder: (context, index) {
              final count = wordCounts[index];
              final isSelected = selectedWordCount == count;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedWordCount = count;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : colors["iconBackground"],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count.toString(),
                      style: GoogleFonts.poppins(
                        color: isSelected ? Colors.white : colors["text"],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(Map<String, Color?> colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors["iconBackground"],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.category_outlined,
                  color: colors["iconColor"],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Kategori',
                style: GoogleFonts.poppins(
                  color: colors["text"],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...categories.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : colors["iconBackground"],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.white : colors["iconColor"],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : colors["text"],
                          fontSize: 15,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeSelector(Map<String, Color?> colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors["iconBackground"],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.quiz_outlined,
                  color: colors["iconColor"],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Soru Tipi',
                style: GoogleFonts.poppins(
                  color: colors["text"],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...questionTypes.map((type) {
            final isSelected = selectedQuestionType == type;
            return Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedQuestionType = type;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : colors["iconBackground"],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.white : colors["iconColor"],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        type,
                        style: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : colors["text"],
                          fontSize: 15,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

    return Scaffold(
      backgroundColor: colors["background"],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors["background"],
        title: Row(
          children: [
            Icon(
              Icons.settings_outlined,
              color: colors["text"],
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Quiz Seçenekleri',
              style: GoogleFonts.poppins(
                color: colors["text"],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(
          color: colors["text"],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('SORU SAYISI', colors),
                  _buildWordCountSelector(colors),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors["cardBackground"],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Quiz\'i Başlat',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}