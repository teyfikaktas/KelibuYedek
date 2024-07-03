import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/wordDetaik.dart';
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

class CustomCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final String assetImagePath;

  const CustomCircleAvatar({
    Key? key,
    required this.imageUrl,
    required this.assetImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl!)
          : AssetImage(assetImagePath) as ImageProvider,
    );
  }
}

class StarredWordsScreen extends StatefulWidget {
  const StarredWordsScreen({Key? key}) : super(key: key);

  @override
  _StarredWordsScreenState createState() => _StarredWordsScreenState();
}

class _StarredWordsScreenState extends State<StarredWordsScreen> with WidgetsBindingObserver {
  bool isPageView = true;
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
    _initialize();
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
      var starredWordsList = starredWordsSet.toList(); // Set'i List'e dönüştürme
      starredWordsString = starredWordsList.join(', ');

      wordDetails = await ApiService().fetchWordsDetail(starredWordsList);
      setState(() {
        words = wordDetails;
        filteredWords = wordDetails;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterWords(String query) {
    setState(() {
      filteredWords = query.isNotEmpty
          ? words.where((word) => word.word.toLowerCase().contains(query.toLowerCase())).toList()
          : words;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = _isDarkMode ? darkModeColors : lightModeColors;

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
        ],
        iconTheme: IconThemeData(
          color: colors["text"]!,
        ),
      ),
      body: isLoading
          ? Center(child: LogoLoadingIndicator())
          : Column(
        children: [
          if (isPageView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Ara",
                  hintText: "Kelime ara...",
                  prefixIcon: Icon(Icons.search, color: colors["text"]!),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    borderSide: BorderSide(color: colors["cardBorder"]!, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    borderSide: BorderSide(color: colors["cardBorder"]!, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    borderSide: BorderSide(color: colors["background"]!, width: 2.0),
                  ),
                  fillColor: colors["inputBackground"],
                  filled: true,
                  hintStyle: TextStyle(color: colors["unselectedText"]),
                ),
                onChanged: filterWords,
                style: TextStyle(color: colors["text"]),
              ),
            ),
          Expanded(
            child: isPageView ? buildListView(colors) : buildPageView(colors),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'floating_button_${Random().nextInt(1000)}',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => GameModeStarScreen(
              studySetName: starredWordsString,
              classroomId: -1,
              studySetId: -1,
            ),
          ));
        },
        child: Icon(
          Icons.videogame_asset,
          size: 30,
        ),
        backgroundColor: colors["buttonBackground"],
        foregroundColor: colors["buttonText"],
        tooltip: 'Yıldızlı Kelimelere Çalış',
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
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

  Widget buildListView(Map<String, Color> colors) {
    return ListView.builder(
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        final word = filteredWords[index];
        return ListTile(
          leading: CustomCircleAvatar(
            imageUrl: word.image != null ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}" : "",
            assetImagePath: "assets/logo.png",
          ),
          title: Text(
            word.word,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors["text"]),
          ),
          subtitle: Text(
            word.meaning,
            style: TextStyle(color: colors["text"]),
          ),
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
        );
      },
    );
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Widget buildWordCard(WordDetail word, int index, Map<String, Color> colors) {
    try {
      return Hero(
        tag: 'word_card_$index',
        child: Card(
          margin: EdgeInsets.all(8),
          color: colors["cardBackground"],
          child: Column(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: word.image != null ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}" : "https://kelibu.net/images/defaultimage.png",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  word.word,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors["text"]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  word.meaning,
                  style: TextStyle(fontSize: 16, color: colors["text"]),
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up, color: colors["text"]),
                onPressed: () => speak(word.word),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Hata oluştu: $e');
      return SizedBox();
    }
  }
}
