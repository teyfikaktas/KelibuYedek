import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart';
import 'package:provider/provider.dart';
import '../Models/category.dart';
import '../providers/user_provider.dart';
import '../shared_preferences/shared_preferences.dart';
import 'flashy_tab_bar2.dart'; // FlashyTabBar dosyanızın yolu
import 'package:kelibu/api.dart'; // ApiService dosyanızın yolu
import 'package:kelibu/screens/WordListScreen.dart';
import 'package:kelibu/screens/study_screen_star.dart';
import 'loadingIndicator.dart';
import 'study_screen.dart'; // StudyScreen'i içe aktar
import 'package:flutter_tts/flutter_tts.dart';

// Add path_provider package
import 'package:google_fonts/google_fonts.dart'; // Google Fonts'u import edin

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
  bool isLoading = true; // Yükleme durumunu takip etmek için
  late StarredWordsService _starredWordsService;

  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _starredWordsService = StarredWordsService(); // StarredWordsService nesnesini başlat

    WidgetsBinding.instance.addObserver(this); // Observer'ı ekleyin
    print('starwords');
    fetchWords();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Observer'ı kaldırın
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Sayfa odaklandığında (aktif hale geldiğinde) verileri yeniden yükle
      setState(() {
        isLoading = true; // Yükleme durumunu true yap
      });
      fetchWords().then((_) {
        // Asenkron işlem tamamlandığında isLoading'i güncelle
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }).catchError((error) {
        // Hata durumunda da isLoading'i güncelle
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      });
    }
  }


  Future<void> fetchWords() async {
      UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);
      int userId = userProvider.userId;
      var starredWordsSet = await _starredWordsService.loadAllStarredWordsAll();
      print('starredWordsSet');
      var starredWordsList = starredWordsSet.toList();

      var wordDetails = await ApiService().fetchWordsDetail(starredWordsList);
      if (mounted) {
        setState(() {
          words = wordDetails;
          filteredWords = wordDetails;
          isLoading = false; // Veriler yüklendikten sonra yükleme durumunu false yap
        });
      }

  }
  void filterWords(String query) {
    if (query.isNotEmpty) {
      List<WordDetail> tempList = words.where((word) => word.word.toLowerCase().contains(query.toLowerCase())).toList();
      setState(() => filteredWords = tempList);
    } else {
      setState(() => filteredWords = words);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFAF6), // Arka plan rengini burada ayarlayın
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar'ın arka plan rengi beyaz
        title: Text(
          'Yıldızlı Kelimelerim',
          style: GoogleFonts.poppins( // Başlık fontu GoogleFonts Poppins, renk pembe
            color: Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [ // Actions içerisine IconButton eklenmeli
          IconButton(
            icon: Icon(isPageView ? Icons.view_list : Icons.dashboard),
            onPressed: () {
              setState(() {
                isPageView = !isPageView; // Duruma göre ikon değişimi
                if (!isPageView) {
                  searchController.clear(); // Arama çubuğu temizleme
                  filterWords(''); // Filtreleme işlemi
                }
              });
            },
          ),
        ],
        iconTheme: IconThemeData(
          color: Colors.pink, // AppBar içerisindeki ikonların rengi pembe
        ),
      ),
      body: isLoading
          ? Center(child: LogoLoadingIndicator()) // Veriler yüklenirken yükleme göstergesi
          : Column(
        children: [
          if (isPageView) // Sadece liste görünümünde arama çubuğunu göster
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Ara",
                  hintText: "Kelime ara...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  ),
                ),
                onChanged: filterWords,
              ),
            ),
          Expanded(
            child: isPageView ?  buildListView() :buildPageView() ,
          ),
        ],
      ),
    );
  }

  Widget buildPageView() {
    // Sayfa görünümü widget'ı
    return PageView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        // Sayfa görünümü için widget oluşturma
        return buildWordCard(word);
      },
    );
  }

  Widget buildListView() {
    // Liste görünümü widget'ı
    return ListView.builder(
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        final word = filteredWords[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(
              word.image != null ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}" : "https://kelibu.net/images/defaultimage.png",
            ),
          ),
          title: Text(word.word, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          subtitle: Text(word.meaning),
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
                // Eğer pop işlemi sırasında bir değer döndürüldüyse (örneğin, kullanıcı bir işlem yaptıysa), sayfanın durumunu güncelleyin
                if (value != null) {
                  print('geri döndü,');
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

  Widget buildWordCard(WordDetail word) {
    try {
      // Kart görünümü için widget
      return Card(
        margin: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                word.image != null ? "https://cloud.phdakademi.com/uploads/kelibu.net/${word.image}" : "https://kelibu.net/images/defaultimage.png",
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(word.word, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(word.meaning, style: TextStyle(fontSize: 16)),
            ),
            IconButton(
              icon: Icon(Icons.volume_up),
              onPressed: () => speak(word.word), // Seslendirme fonksiyonunu çağır
            ),
          ],
        ),
      );
    } catch (e) {
      print('Hata oluştu: $e');
      // Hata durumunda bir boş Container veya başka bir widget döndürebilirsiniz
      return SizedBox();
    }
  }
}

