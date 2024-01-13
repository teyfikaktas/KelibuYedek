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

class StudyScreen extends StatefulWidget {
  final List<WordDetail> words;
  final int classroomId;
  final int studySetId;

  StudyScreen({required this.words, required this.classroomId, required this.studySetId});

  @override
  _StudyScreenState createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  Map<int, ValueNotifier<bool>> starredNotifiers = {};
  late PageController _sentencePageController;
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

  Future<void> loadExampleSentences() async {
    for (var word in widget.words) {
      try {
        var sentences = await ApiService().fetchExampleSentences(word.word);
        if (sentences.isNotEmpty) {
          setState(() {
            exampleSentences[word.id] = sentences.map<String>((item) => item['cumle'].toString()).toList();
          });
        }
      } catch (e) {
        print('Hata: $e');
        exampleSentences[word.id] = ["Cümle yüklenemedi"];
      }
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Kelime Öğren', style: GoogleFonts.lato()),
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.words.length,
        itemBuilder: (context, index) {
          return buildWordDetail(widget.words[index]);
        },
        onPageChanged: (index) {
          _selectedPageIndex.value = index; // Sayfa değiştiğinde değeri güncelle
          setState(() {
            currentWordIndex = index; // Geçerli kelimenin indeksini güncelle
          });
        },
      ),
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
              Text(
                word.word,
                style: GoogleFonts.lato(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal),
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
            style: GoogleFonts.lato(fontSize: 18, color: Colors.black87),
          ),
          Text(
            word.meaning,
            style: GoogleFonts.lato(fontSize: 24, color: Colors.black54),
          ),
          SizedBox(height: 30),
          Text(
            'Örnek Cümleler:',
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          buildSentencePageView(exampleSentences[word.id] ?? ["Cümle bulunamadı"], _sentencePageControllers[word.id]!),
          if (word.collocations.isNotEmpty)
            buildCollocationsSection(word.collocations),
          if (word.derivations.isNotEmpty)
            buildDerivationsSection(word.derivations),
          if (word.synonyms.isNotEmpty) ...[
            Text(
              'Eş Anlamlılar:',
              style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            buildSynonymsSection(word.synonyms),
          ],
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
            style: GoogleFonts.lato(fontSize: 18, color: Colors.black87),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meaning,
            style: GoogleFonts.lato(fontSize: 18, color: Colors.teal),
          ),
        ),
      ],
    );
  }
  Widget buildSynonymsSection(List<Synonym> synonyms) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: synonyms.map((synonym) => Chip(
        label: Text(synonym.tanim),
        backgroundColor: Colors.teal[100],
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
            style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // ScrollView içindeki kaydırma işlevini devre dışı bırakır
          itemCount: collocations.length,
          itemBuilder: (context, index) {
            Collocation collocation = collocations[index];
            return Container(
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
                  collocation.term,
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  collocation.definition,
                  style: GoogleFonts.lato(fontSize: 16),
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
            style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
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
              style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: iconColor),
            ),
          ),
          Column(
            children: derivations.map((derivation) => ListTile(
              leading: Icon(icon, color: iconColor),
              title: Text(
                derivation.term,
                style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                derivation.definition,
                style: GoogleFonts.lato(fontSize: 16),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }


  Widget buildSentencePageView(List<String> sentences, PageController controller) {
    return Stack(
      alignment: Alignment.center,
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
                      style: GoogleFonts.lato(fontSize: 18, color: Colors.black87),
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
        Positioned(
          bottom: 10,
          child: ValueListenableBuilder<int>(
            valueListenable: _currentSentenceIndex,
            builder: (_, value, __) {
              return Container(
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