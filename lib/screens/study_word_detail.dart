import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:kelibu/Models/wordDetaik.dart'; // WordDetail modelinizin importu
import 'package:kelibu/api.dart';
import 'package:kelibu/screens/flash_card.dart'; // FlashCardScreen sayfasının importu
import 'package:kelibu/providers/user_provider.dart'; // UserProvider importu
import 'package:provider/provider.dart';
import 'package:kelibu/screens/quiz.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kelibu/api.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'loadingIndicator.dart';


class StudyScreenWord extends StatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;

  StudyScreenWord({required this.words, required this.classroomId, required this.studySetId});

  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreenWord> {
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  late PageController _sentencePageController;
  bool isLoading = true; // Yeni durum değişkeni

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


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    filteredWords = widget.words; // Başlangıçta tüm kelimeleri göster
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      userID = userProvider.userId;
    });

    _sentencePageController = PageController(initialPage: 0);
    for (var word in widget.words) {
      _sentencePageControllers[word.id] = PageController(initialPage: 0);
    }
    loadStarredWords();
    loadExampleSentences();

  }
  int itemsPerPage = 5; // Her seferinde yüklenecek kelime sayısı
  int currentPage = 0; // Başlangıçta yüklenecek sayfa numarası

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Kelime Öğren', style: GoogleFonts.roboto()),
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
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
                      itemCount: filteredWords.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            filteredWords[index].word,
                            style: TextStyle(
                              color: value == index ? Colors.blue : Colors.black, // Renk değişimi
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(); // Drawer'ı kapat
                            int originalIndex = widget.words.indexOf(filteredWords[index]);
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
                    )
                ),
              ],
            );
          },
        ),
      ),
      body: isLoading ? Center(child: LogoLoadingIndicator()) : buildPageView(),

    );
  }
  Widget buildPageView() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.words.length,
      itemBuilder: (context, index) {
        return buildWordDetail(widget.words[index]);
      },
      onPageChanged: (index) {
        _selectedPageIndex.value = index;
        _currentSentenceIndex.value = 0; // Sayfa değiştiğinde değeri güncelle
        setState(() {
          currentWordIndex = index; // Geçerli kelimenin indeksini güncelle
        });
      },
    );
  }

  Widget buildWordDetail(WordDetail word) {
    String? imageUrl = word.image;
    String fullImageUrl = imageUrl != null
        ? "https://cloud.argethink.com/uploads/kelibu.net/$imageUrl"
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
              alignment: Alignment.topRight, // Resmi sağ üst köşeye hizalar
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
              ValueListenableBuilder<bool>(
                valueListenable: starredNotifiers[word.id] ?? ValueNotifier(false),
                builder: (context, isStarred, child) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      color: isStarred ? Colors.yellow : Colors.grey,
                      size: 36,
                    ),
                    onPressed: () {
                      _toggleStar(word, starredNotifiers[word.id]!);
                    },
                  );
                },
              ),
            ],
          ),
          Text(
            '${word.type}',
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.black87),
          ),
          Text(
            word.meaning,
            style: GoogleFonts.roboto(fontSize: 24, color: Colors.black54),
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
  void _updateStarredWordCount() {
    int newCount = starredStatus.values.where((isStarred) => isStarred).length;
    animatedStarredCount.value = newCount; // Bu satırı ekledim
  }
  Future<List<String>> _fetchSentenceForTerm(String term) async {
    try {
      var response = await ApiService().fetchExampleSentences(term);
      if (response.isNotEmpty) {
        // Her öğeyi String'e dönüştürüp yeni bir liste oluştur
        return response.map<String>((item) => item['cumle'].toString()).toList();
      } else {
        return ["Cümle bulunamadı"];
      }
    } catch (e) {
      print('Hata: $e');
      return ["Cümle yüklenemedi"];
    }
  }

  TableRow buildTableRow(String term, String meaning) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            term,
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.black87),
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
          physics: NeverScrollableScrollPhysics(), // ScrollView içindeki kaydırma işlevini devre dışı bırakır
          itemCount: collocations.length,
          itemBuilder: (context, index) {
            Collocation collocation = collocations[index];
            return InkWell(
              onTap: () => speak(collocation.definition),
              splashColor: Colors.teal[300], // Tıklanma sırasında su efekti rengi
              highlightColor: Colors.teal[200], // Tıklanma sırasında arka plan rengi
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: ListTile(
                  leading: Icon(Icons.group_work, color: Colors.teal),
                  title: Text(
                    collocation.definition,
                    style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: collocation.anlam != null ? Text(
                    collocation.anlam!,
                    style: GoogleFonts.roboto(fontSize: 16),
                  ) : null,
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
        color: Colors.white,
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
            children: uniqueDerivations.map((derivation) => InkWell(
              onTap: () => speak(derivation.definition),
              child: ListTile(
                leading: Icon(icon, color: iconColor),
                title: Text(
                  derivation.definition,
                  style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: derivation.anlam != null ? Text(
                  derivation.anlam!,
                  style: GoogleFonts.roboto(fontSize: 16),
                ) : null,
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
                    color: Colors.white,
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
                      style: GoogleFonts.roboto(fontSize: 18, color: Colors.black87),
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