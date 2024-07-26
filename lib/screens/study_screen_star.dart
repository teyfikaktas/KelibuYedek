import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared_preferences/shared_preferences.dart';
import '../variables.dart';

class CustomLoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitChasingDots( // Circle türündeki yükleme göstergesi
        color: Theme.of(context).primaryColor, // Yükleme göstergesi rengi
        size: 50.0, // Yükleme göstergesi boyutu
      ),
    );
  }
}

class StudyScreenStar extends StatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;

  StudyScreenStar({required this.words, required this.classroomId, required this.studySetId});

  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreenStar> {
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  ValueNotifier<bool> starredStatusWord = ValueNotifier<bool>(true);
  late PageController _sentencePageController;
  bool isLoading = true; // Yeni durum değişkeni
  bool _showOnlyStarred = false; // Yıldızlı kelimeleri göstermek için eklediğimiz kontrol değişkeni
  bool _shouldSpeak = true;  // Sayfa değiştirildiğinde seslendirme yapılması gerekip gerekmediğini kontrol eder

  ValueNotifier<int> _currentSentenceIndex = ValueNotifier<int>(0);
  late PageController _pageController;
  ValueNotifier<int> _selectedPageIndex = ValueNotifier<int>(0);
  TextEditingController _searchController = TextEditingController(); // Kelime arama için kontrolcü
  List<WordDetail> filteredWords = []; // Filtrelenmiş kelimeleri içerecek liste
  int currentWordIndex = 0; // Geçerli kelimenin indeksi
  int userID = 2;
  ValueNotifier<int> animatedStarredCount = ValueNotifier(0);
  Map<int, bool> starredStatus = {};
  FlutterTts flutterTts = FlutterTts();
  Map<int, PageController> _sentencePageControllers = {};
  Map<int, List<String>> exampleSentences = {}; // Yeni değişken
  Map<int, ValueNotifier<int>> _currentSentenceIndices = {};
  int _targetPageIndex = -1;  // Hedef kelimenin indeksini saklamak için bir değişken
  bool _isDarkMode = false; // Dark mode durumu

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _showExitConfirmationDialog();
    return true;
  }

  void _showExitConfirmationDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Çıkmak istediğinize emin misiniz?'),
        content: Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('Evet'),
          ),
        ],
      ),
    ).then((value) => value ?? false ? Navigator.of(context).pop(true) : null);
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);
    filteredWords = widget.words; // Başlangıçta tüm kelimeleri göster

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userID = userProvider.userId;

    _sentencePageController = PageController(initialPage: 0);
    for (var word in widget.words) {
      _sentencePageControllers[word.id] = PageController(initialPage: 0);
    }
    _loadDarkModePreference();
    loadExampleSentences();

    // İlk kelimenin seslendirilmesi için ekleme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.words.isNotEmpty) {
        speak(widget.words.first.word);
      }
    });
  }

  int itemsPerPage = 5; // Her seferinde yüklenecek kelime sayısı
  int currentPage = 0; // Başlangıçta yüklenecek sayfa numarası

  List<WordDetail> getDisplayedWords() {
    // Eğer yıldızlı kelimeleri göster seçeneği aktifse, yalnızca yıldızlı kelimelerin listesini döndür
    if (_showOnlyStarred) {
      return widget.words.where((word) => starredNotifiers[word.id]?.value ?? false).toList();
    }
    // Değilse, tüm kelimeleri döndür
    return widget.words;
  }

  Future<void> loadExampleSentences() async {
    try {
      List<String> terms = widget.words.map((word) => word.word).toList();
      Map<String, List<String>> sentences = await ApiService().fetchExampleSentencesBulk(terms);

      setState(() {
        for (var word in widget.words) {
          exampleSentences[word.id] = sentences[word.word] ?? ["Cümle bulunamadı"];
        }
        isLoading = false; // Yükleme tamamlandığında
      });
    } catch (e) {
      print('Hata: $e');
      setState(() {
        isLoading = false; // Hata durumunda
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectedPageIndex.dispose();
    _searchController.dispose();
    _sentencePageController.dispose();
    for (var controller in _sentencePageControllers.values) {
      controller.dispose();
    }
// Kontrolcüyü temizle
    super.dispose();
  }

  void speak(String text) async {
    print(text);
    await flutterTts.setLanguage("en-US");
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  Future<void> loadStarredWords() async {
    try {
      List<int> wordIds = widget.words.map((word) => word.id).toList();
      Map<int, bool> starredResults = await ApiService().checkStarredBulk(wordIds, widget.studySetId, userID);
      // starredNotifiers Map'ini ValueNotifier'larla doldurun
      setState(() {
        starredNotifiers = starredResults.map((key, value) => MapEntry(key, ValueNotifier(value)));
      });
    } catch (e) {
      print('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Cihazın geri tuşuna basıldığında yapılacak işlem
        Navigator.of(context).pop('true');
        // false döndürmek geri tuşunun varsayılan işlevini engeller, true ise izin verir.
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: _isDarkMode ? darkModeColors["background"] : lightModeColors["background"],
          appBar: AppBar(
            title: ValueListenableBuilder<int>(
              valueListenable: _selectedPageIndex,
              builder: (_, currentPageIndex, __) {
                // Yıldızlı kelime modu aktif olduğunda, yıldızlı kelimelerin sayısını kullan
                int wordCount = _showOnlyStarred ? getDisplayedWords().length : widget.words.length;
                return Text(
                  'Kelime Öğren (${currentPageIndex + 1}/$wordCount)',
                  style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
            backgroundColor: Colors.teal,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop('true'),
            ),
            actions: <Widget>[
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                    setState(() {
                      _showOnlyStarred = false;
                    });
                  },
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: ValueListenableBuilder<int>(
              valueListenable: _selectedPageIndex,
              builder: (context, value, child) {
                return Column(
                  children: [
                    SafeArea( // SafeArea eklemesi
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController, // Kontrolcüyü kullanarak kelime arama
                          decoration: InputDecoration(
                            hintText: 'Kelime Ara',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (searchQuery) {
                            // Kelime arama işlemini burada yapabilirsiniz
                            filterWords(searchQuery);
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: getDisplayedWords().length, // Yıldızlı kelimeleri filtreleyerek itemCount'u ayarlayın
                        itemBuilder: (context, index) {
                          WordDetail word = filteredWords[index];
                          return ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    word.word,
                                    style: TextStyle(
                                      color: value == index ? Colors.blue : _isDarkMode ? darkModeColors["text"] : lightModeColors["text"],
                                    ),
                                  ),
                                ),
                                // Yıldızlı durumu göstermek için bir ikon ekleyin
                              ],
                            ),
                            onTap: () {
                              _shouldSpeak = false; // Sayfa değiştirme işlemi sırasında seslendirme yapmama
                              Navigator.of(context).pop(true); // Drawer'ı kapat
                              int originalIndex = widget.words.indexOf(word);
                              _targetPageIndex = index;  // Hedef kelimenin indeksini ayarla

                              _pageController.animateToPage(
                                originalIndex,
                                duration: Duration(milliseconds: 500), // Sayfa geçiş süresi
                                curve: Curves.easeInOut, // Animasyon eğrisi
                              );
                              setState(() {
                                currentWordIndex = originalIndex; // Geçerli kelimenin indeksini güncelle
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          body: isLoading ? Center(child: CustomLoadingIndicator()) : buildPageView(),
        ),
      ),
    );
  }

  Widget buildPageView() {
    List<WordDetail> displayedWords = getDisplayedWords();
    return PageView.builder(
      controller: _pageController,
      itemCount: displayedWords.length, // itemCount'u güncelleyin
      itemBuilder: (context, index) {
        return buildWordDetail(displayedWords[index]); // displayedWords listesini kullanarak detayı oluştur
      },
      onPageChanged: (index) async {
        _selectedPageIndex.value = index; // Sayfanın indeksini güncelle

        // Yıldızlı kelimeleri göster seçeneği aktifse ve yıldızlı kelimeler varsa, yalnızca bu kelimeleri seslendir
        List<WordDetail> displayedWords = getDisplayedWords();
        if (_showOnlyStarred && displayedWords.isNotEmpty) {
          if (_shouldSpeak) {
            if (index == _targetPageIndex) {  // Eğer hedef kelimeye ulaşıldıysa
              _targetPageIndex = -1;  // Hedef indeksi sıfırla
              speak(displayedWords[index].word); // Yıldızlı kelimeyi seslendir
              _shouldSpeak = true;  // Gelecek sayfa değişiklikleri için seslendirme yeteneğini aktif et
            }
          }
        } else if (!_showOnlyStarred) {
          if (index == _targetPageIndex) {  // Eğer hedef kelimeye ulaşıldıysa
            _targetPageIndex = -1;  // Hedef indeksi sıfırla
            speak(widget.words[index].word);  // Hedef kelimeyi seslendir
            _shouldSpeak = true;  // Gelecek sayfa değişiklikleri için seslendirme yeteneğini aktif et
          }
        }

        var userProvider = Provider.of<UserProvider>(context, listen: false);
        int currentPoints = userProvider.point; // Mevcut puanı al ve int'e çevir. Eğer çevrilemezse 0 varsay.
        userProvider.addPoint((currentPoints + 1)); // Puanı 3 artır ve güncelle.
        await ApiService().updateUserPointTimePeriod(userProvider.userId, currentPoints, 1); // API üzerinden puanı güncelleyin
        _currentSentenceIndex.value = 0; // Bu satırı ekleyin.
      },
    );
  }

  void _toggleStarStatus() {
    starredStatusWord.value = !starredStatusWord.value;
    setState(() {

    });
  }

  Widget buildWordDetail(WordDetail word) {
    String? imageUrl = word.image;
    print(imageUrl);
    String fullImageUrl = imageUrl != null
        ? "https://cloud.phdakademi.com/uploads/kelibu.net/$imageUrl"
        : "https://kelibu.net/images/defaultimage.png";
    var controller = _sentencePageControllers[word.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (imageUrl != null)
            Image.network(
              fullImageUrl,
              width: 100,
              height: 100,
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                // Burada resim yüklenemediğinde gösterilecek alternatif bir resmi belirleyebilirsiniz.
                return Image.asset('assets/logo.png', width: 100, height: 100);
              },
            ),

          SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child:
              Text(
                word.word,
                style: GoogleFonts.roboto(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up),
                onPressed: () => speak(word.word),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: ValueListenableBuilder<bool>(
                  valueListenable: starredStatusWord,
                  builder: (context, value, child) {
                    return Icon(
                      value ? Icons.star : Icons.star_border,
                      color: Colors.yellow,
                      size: 36,
                    );
                  },
                ),
                onPressed: () => _toggleStarDelete(word),
              )
            ],
          ),
          Text(
            '${word.type}',
            style: GoogleFonts.roboto(fontSize: 18, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
          ),
          Text(
            word.meaning,
            style: GoogleFonts.roboto(fontSize: 24, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
          ),
          SizedBox(height: 30),
          Text(
            'Örnek Cümleler:',
            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          buildSentencePageView(exampleSentences[word.id] ?? ["Cümle bulunamadı"], _sentencePageControllers[word.id]!),
          if (word.synonyms.isNotEmpty) ...[
            Text(
              'Eş Anlamlılar:',
              style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            buildSynonymsSection(word.synonyms),
          ],
          if (word.derivations.isNotEmpty)
            buildDerivationsSection(word.derivations),
          if (word.collocations.isNotEmpty)
            buildCollocationsSection(word.collocations),
        ],
      ),
    );
  }

  void _toggleStar(WordDetail word, ValueNotifier<bool> isStarredNotifier) async {
    try {
      // API çağrısını yap
      await ApiService().starWord(word.id, widget.classroomId, widget.studySetId, userID);

      // Yıldızlanma durumunu tersine çevir
      bool newStatus = !isStarredNotifier.value;
      isStarredNotifier.value = newStatus;

      // starredStatus ve animatedStarredCount değerlerini güncelle (varsa)
      starredStatus[word.id] = newStatus;
      _updateStarredWordCount();

    } catch (e) {
      print('Hata: $e'); // Hata durumunu işleme
    }
  }

  void _toggleStarDelete(WordDetail word) {
    starredStatusWord.value = false;
    StarredWordsService().removeWordFromAllById(word.id);
  }

  void _updateStarredWordCount() {
    int newCount = starredStatus.values.where((isStarred) => isStarred).length;
    animatedStarredCount.value = newCount; // Bu satırı ekledim
  }




  TableRow buildTableRow(String term, String meaning) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            term,
            style: GoogleFonts.roboto(fontSize: 18, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meaning,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.teal),
          ),
        ),
      ],
    );
  }

  Widget buildSynonymsSection(List<Synonym> synonyms) {
    // Synonym nesnelerini 'tanim' özelliğine göre filtrele
    var uniqueSynonyms = synonyms.map((s) => s.tanim).toSet().map(
          (tanim) => synonyms.firstWhere((s) => s.tanim == tanim),
    ).toList();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: uniqueSynonyms.map((synonym) => InkWell(
        onTap: () => speak(synonym.tanim),
        splashColor: Colors.teal[300], // Tıklanma sırasında su efekti rengi
        highlightColor: Colors.teal[200], // Tıklanma sırasında arka plan rengi
        child: Chip(
          label: Text(synonym.tanim),
          backgroundColor: Colors.teal[100],
        ),
      )).toList(),
    );
  }

  Widget buildCollocationsSection(List<Collocation> collocations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Collocations",
            style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: collocations.length,
          itemBuilder: (context, index) {
            Collocation collocation = collocations[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => speak(collocation.definition),
                // Burada null check yaparak varsayılan bir renk atayabiliriz
                splashColor: Colors.teal[300]?.withOpacity(0.1) ?? Colors.teal.withOpacity(0.1),
                highlightColor: Colors.teal[200]?.withOpacity(0.1) ?? Colors.teal.withOpacity(0.1),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? darkModeColors["cardBackground"] : lightModeColors["cardBackground"],
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Icon(Icons.group_work, color: Colors.teal),
                    title: Text(
                      collocation.definition,
                      style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
                    ),
                    subtitle: collocation.anlam != null ? Text(
                      collocation.anlam!,
                      style: GoogleFonts.roboto(fontSize: 16, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
                    ) : null,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget buildDerivationsSection(List<Derivation> derivations) {
    // Her tip için filtrasyon yap
    var verbs = derivations.where((d) => d.type.toLowerCase() == 'verb').toList();
    var nouns = derivations.where((d) => d.type.toLowerCase() == 'noun').toList();
    var adjectives = derivations.where((d) => d.type.toLowerCase() == 'adjective').toList();
    var adverbs = derivations.where((d) => d.type.toLowerCase() == 'adverb').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Türemeler",
            style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
        if (verbs.isNotEmpty) buildDerivationList("Fiiller", verbs, Icons.run_circle, Colors.lightBlueAccent),
        if (nouns.isNotEmpty) buildDerivationList("İsimler", nouns, Icons.account_balance, Colors.amber),
        if (adjectives.isNotEmpty) buildDerivationList("Sıfatlar", adjectives, Icons.adjust, Colors.purpleAccent),
        if (adverbs.isNotEmpty) buildDerivationList("Zarflar", adverbs, Icons.airplanemode_active, Colors.greenAccent),
        SizedBox(height: 20),
      ],
    );
  }

  Widget buildDerivationList(String title, List<Derivation> derivations, IconData icon, Color iconColor) {
    // Map'e dönüştürerek ve sonra listeye çevirerek tekrar edenleri filtrele
    var uniqueDerivations = Map<String, Derivation>.fromIterable(derivations,
        key: (item) => item.definition,
        value: (item) => item).values.toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: _isDarkMode ? darkModeColors["cardBackground"] : lightModeColors["cardBackground"],
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              title,
              style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ),
          Column(
            children: uniqueDerivations.map((derivation) => Material(
              color: Colors.transparent, // Material'in arka plan rengini şeffaf yap
              child: InkWell(
                onTap: () => speak(derivation.definition),
                splashColor: iconColor.withOpacity(0.1), // Tıklanma efektinin rengi
                highlightColor: iconColor.withOpacity(0.1), // Tıklama sırasındaki arka plan rengi
                child: ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(
                    derivation.definition,
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
                  ),
                  subtitle: derivation.anlam != null ? Text(
                    derivation.anlam!,
                    style: GoogleFonts.roboto(fontSize: 16, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
                  ) : null,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildSentencePageView(List<String> sentences, PageController controller) {
    return Column(
      children: [
        Container(
          height: 200,
          child: PageView.builder(
            controller: controller,
            itemCount: sentences.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () => speak(sentences[index]),
                child: Container(
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? darkModeColors["cardBackground"] : lightModeColors["cardBackground"],
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      sentences[index],
                      style: GoogleFonts.roboto(fontSize: 18, color: _isDarkMode ? darkModeColors["text"] : lightModeColors["text"]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
            onPageChanged: (index) {
              _currentSentenceIndex.value = index;

            },
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _currentSentenceIndex,
          builder: (_, value, __) {
            return Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Text(
                '${value + 1}/${sentences.length}',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }

  void filterWords(String query) {
    setState(() {
      filteredWords = widget.words.where((word) {
        return word.word.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }
}
