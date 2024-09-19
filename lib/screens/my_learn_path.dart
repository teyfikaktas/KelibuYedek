import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kelibu/screens/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/wordDetaik.dart';
import '../globalDart/urls.dart';
import '../providers/user_provider.dart';
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/study_screen_star.dart';
import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';
import 'game_screen_star.dart';
import 'loadingIndicator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StarredWordsScreen extends StatefulWidget {
  const StarredWordsScreen({Key? key}) : super(key: key);

  @override
  _StarredWordsScreenState createState() => _StarredWordsScreenState();
}

class _StarredWordsScreenState extends State<StarredWordsScreen> with WidgetsBindingObserver {
  bool isPageView = true;
  int _currentPage = 0;
  bool _hasMoreItems = true;
  Timer? _debounce;

  static const int _itemsPerPage = 20;
  ScrollController _scrollController = ScrollController();
  List<WordDetail> words = [];
  List<WordDetail> filteredWords = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  late StarredWordsService _starredWordsService;
  late List<WordDetail> wordDetails;
  String starredWordsString = "";
  final FlutterTts flutterTts = FlutterTts();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _starredWordsService = StarredWordsService();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    _initialize();
  }

  void _scrollListener() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        _hasMoreItems &&
        searchController.text.isEmpty) {
      fetchWords();
    }
  }

  Future<void> _initialize() async {
    await _loadDarkModePreference();
    await fetchWords();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      fetchWords();
    }
  }

  Future<void> fetchWords() async {
    setState(() {
      isLoading = true;
    });
    try {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      var starredWordsSet = await _starredWordsService.loadAllStarredWordsAll();
      var starredWordsList = starredWordsSet.toList();
      starredWordsString = starredWordsList.join(', ');

      List<WordDetail> newWordDetails = await ApiService().fetchWordsDetail(starredWordsList);

      setState(() {
        words = newWordDetails;
        filteredWords = words;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching words: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterWords(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (query.isEmpty) {
          filteredWords = words;
          _hasMoreItems = true;
        } else {
          filteredWords = words.where((word) =>
          word.word.toLowerCase().contains(query.toLowerCase()) ||
              word.meaning.toLowerCase().contains(query.toLowerCase())
          ).toList();
          _hasMoreItems = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;
    colors.putIfAbsent("shadow", () => Colors.grey.shade300);
    colors.putIfAbsent("text", () => Colors.black);
    colors.putIfAbsent("unselectedText", () => Colors.grey);
    colors.putIfAbsent("inputBackground", () => Colors.white);

    return Scaffold(
      backgroundColor: colors["background"]!,
      appBar: AppBar(
        backgroundColor: colors["background"]!,
        title: Text(
          'Yıldızlı Kelimelerim',
          style: GoogleFonts.poppins(
            color: colors["text"]!,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isPageView ? Icons.view_list : Icons.dashboard),
            color: colors["text"]!,
            onPressed: () {
              setState(() {
                isPageView = !isPageView;
                if (!isPageView) {
                  searchController.clear();
                  filterWords('');
                }
              });
            },
          ),
          _buildRoundedIconButton(Icons.slow_motion_video_sharp, Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoUrl: AppUrls.mystarwords)),
            );
          }),
        ],
        iconTheme: IconThemeData(
          color: colors["text"]!,
        ),
      ),
      body: Column(
        children: [
          _buildStudyButton(colors),
          if (isPageView) buildSearchBar(colors),
          if (isPageView) buildSearchInfo(colors),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: colors["buttonBackground"]))
                : words.isEmpty
                ? _buildEmptyState(colors)
                : isPageView ? buildListView(colors) : buildPageView(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: CircleBorder(),
        padding: EdgeInsets.all(12.sp),
      ),
      child: Icon(icon, color: Colors.white, size: 24.sp),
    );
  }

  Widget _buildStudyButton(Map<String, Color> colors) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => GameModeStarScreen(
              studySetName: starredWordsString,
              classroomId: -1,
              studySetId: -1,
            ),
          ));
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white, backgroundColor: Color(0xFF58CC02),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, size: 28),
            SizedBox(width: 12),
            Text(
              'ÇALIŞMAYA BAŞLA',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildSearchInfo(Map<String, Color> colors) {
    if (searchController.text.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: colors["background"],
      child: Text(
        "${filteredWords.length} sonuç bulundu",
        style: TextStyle(
          color: colors["text"]!.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget buildSearchBar(Map<String, Color> colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: colors["inputBackground"],
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: colors["shadow"]!.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Kelime veya anlam ara...",
            prefixIcon: Icon(Icons.search, color: colors["text"]!.withOpacity(0.5)),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: colors["text"]!.withOpacity(0.5)),
              onPressed: () {
                searchController.clear();
                filterWords('');
              },
            )
                : null,
            border: InputBorder.none,
            hintStyle: TextStyle(color: colors["unselectedText"]!.withOpacity(0.7)),
          ),
          onChanged: filterWords,
          style: TextStyle(color: colors["text"]),
        ),
      ),
    );
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Widget buildWordCard(WordDetail word, int index, Map<String, Color> colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: word.image != null
                    ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}"
                    : "https://kelibu.net/images/defaultimage.png",
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(child: LogoLoadingIndicator()),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        word.word,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors["text"],
                        ),
                        maxLines: 1,
                        minFontSize: 18,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (word.type != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors["buttonBackground"]!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AutoSizeText(
                          word.type == "full" ? "Tip bulunamadı" : word.type!,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors["buttonBackground"],
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          minFontSize: 10,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10),
                AutoSizeText(
                  word.meaning,
                  style: TextStyle(
                    fontSize: 18,
                    color: colors["text"],
                  ),
                  maxLines: 3,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => speak(word.word),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          color: colors["buttonBackground"],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.volume_up, color: colors["buttonText"], size: 20),
                            SizedBox(width: 5),
                            Text(
                              'Dinle',
                              style: TextStyle(color: colors["buttonText"], fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildListView(Map<String, Color> colors) {
    return ListView.builder(
        controller: _scrollController,
      itemCount: filteredWords.length + 1,
      itemBuilder: (context, index) {
        if (index < filteredWords.length) {
          final word = filteredWords[index];
          return buildListTile(word, colors);
        } else {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 50,
                  color: colors["buttonBackground"],
                ),
                SizedBox(height: 10),
                Text(
                  "Yıldızlı kelimelerin sonuna ulaştınız!",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors["text"],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 5),
                Text(
                  "Daha fazla kelime yıldızlayın, setleri keşfedin ve öğrenmeye devam edin!",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colors["text"],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget buildPageView(Map<String, Color> colors) {
    return PageView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return buildWordCard(word, index, colors);
      },
    );
  }

  Widget buildListTile(WordDetail word, Map<String, Color> colors) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors["cardBackground"],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => StudyScreenStar(
                words: [word],
                classroomId: 0,
                studySetId: word.id,
              ),
            ),
          ).then((value) {
            if (value != null) {
              fetchWords();
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: word.image != null
                      ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}"
                      : "https://kelibu.net/images/defaultimage.png",
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: LogoLoadingIndicator()),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/logo.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AutoSizeText(
                            word.word,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors["text"],
                            ),
                            maxLines: 1,
                            minFontSize: 14,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (word.type != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors["buttonBackground"]!.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AutoSizeText(
                              word.type == "full" ? "Tip bulunamadı" : word.type!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors["buttonBackground"],
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              minFontSize: 8,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    AutoSizeText(
                      word.meaning,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors["text"],
                      ),
                      maxLines: 2,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.volume_up, color: colors["buttonBackground"], size: 24),
                    onPressed: () => speak(word.word),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Map<String, Color> colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 80,
            color: colors["buttonBackground"],
          ),
          SizedBox(height: 20),
          Text(
            "Ups! Yıldızlı kelimeniz yok.",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors["text"],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Hadi biraz çalışalım ve yıldızları toplayalım!",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colors["text"],
            ),
          ),
        ],
      ),
    );
  }
}