import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

class KelibuProListWidget extends StatefulWidget {
  const KelibuProListWidget({Key? key}) : super(key: key);

  @override
  _KelibuProListWidgetState createState() => _KelibuProListWidgetState();
}

class _KelibuProListWidgetState extends State<KelibuProListWidget> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
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

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _isDarkMode ? Colors.white : Colors.black;
    final Color backgroundColor = _isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;
    final Color cardColor = _isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black87;

    return MaterialApp(
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
      ),
      home: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 30,
              ),
              const SizedBox(width: 8),
              Text(
                'Kelibu',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pro',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildListItem('Level 1', 'Temel kelimeleri öğren', Icons.emoji_objects, Colors.blue, context, 'assets/pdf/level1.pdf'),
            _buildListItem('Level 2', 'Cümle yapılarını geliştir', Icons.psychology, Colors.green, context, 'assets/pdf/level2.pdf'),
            _buildListItem('Level 3', 'Akıcı konuşmayı hedefle', Icons.workspace_premium, Colors.orange, context, 'assets/pdf/level3.pdf'),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle, IconData icon, Color iconColor, BuildContext context, String pdfPath) {
    final Color cardColor = _isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black87;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      color: cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: textColor.withOpacity(0.7),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: iconColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewer(pdfAssetPath: pdfPath),
            ),
          );
        },
      ),
    );
  }
}

class PDFViewer extends StatefulWidget {
  final String pdfAssetPath;

  const PDFViewer({Key? key, required this.pdfAssetPath}) : super(key: key);

  @override
  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  late PdfViewerController _pdfViewerController;
  late ScreenshotController _screenshotController;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isDarkMode = false;
  bool _isDrawingMode = false;
  bool _isAddingText = false;
  bool _isDrawingCircle = false;
  bool _isPanningMode = true;
  bool _isEraserMode = false;
  String _textToAdd = '';
  Map<int, List<DrawnItem>> _drawnItemsByPage = {};
  Color _currentColor = Colors.red;
  double _currentStrokeWidth = 2.0;
  Offset? _circleStart;
  Offset? _textPosition;
  double _currentFontSize = 16.0;
  double _baseScaleFactor = 1.0;
  double _pdfScale = 1.0;
  double _circleRadius = 20.0;
  final GlobalKey pdfViewerKey = GlobalKey();

  Color get primaryColor => _isDarkMode ? Colors.white : Colors.black;
  Color get backgroundColor => _isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _screenshotController = ScreenshotController();
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool("darkMode") ?? false;
    });
  }

  void _startAddingText() {
    setState(() {
      _isAddingText = true;
      _isDrawingMode = false;
      _isDrawingCircle = false;
      _isPanningMode = false;
      _isEraserMode = false;
    });
    _showTextInputDialog();
  }

  void _showTextInputDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempFontSize = _currentFontSize;
        Color tempColor = _currentColor;
        String tempText = _textToAdd;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              title: Text('Metin Ekle', style: TextStyle(color: textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      tempText = value;
                    },
                    decoration: InputDecoration(
                      hintText: "Metni girin",
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Yazı Boyutu:', style: TextStyle(color: textColor)),
                      Expanded(
                        child: Slider(
                          value: tempFontSize,
                          min: 8,
                          max: 72,
                          divisions: 64,
                          label: tempFontSize.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              tempFontSize = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.color_lens, color: tempColor),
                    label: Text('Renk Seç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tempColor.withOpacity(0.2),
                    ),
                    onPressed: () {
                      _showColorPickerDialog(setState, tempColor);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('İptal', style: TextStyle(color: primaryColor)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isAddingText = false;
                      _isPanningMode = true;
                    });
                  },
                ),
                TextButton(
                  child: Text('Tamam', style: TextStyle(color: primaryColor)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _currentFontSize = tempFontSize;
                    _currentColor = tempColor;
                    _textToAdd = tempText;
                    _showTextPositionIndicator();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showColorPickerDialog(StateSetter setState, Color tempColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Renk Seçin'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (Color color) {
                setState(() {
                  tempColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTextPositionIndicator() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Metni eklemek istediğiniz yere dokunun'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showGoToPageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String pageNumber = '';
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text('Sayfaya Git', style: TextStyle(color: textColor)),
          content: TextField(
            style: TextStyle(color: textColor),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              pageNumber = value;
            },
            decoration: InputDecoration(
              hintText: "Sayfa numarası girin",
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('İptal', style: TextStyle(color: primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Git', style: TextStyle(color: primaryColor)),
              onPressed: () {
                int? page = int.tryParse(pageNumber);
                if (page != null && page > 0 && page <= _totalPages) {
                  _pdfViewerController.jumpToPage(page);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Geçersiz sayfa numarası')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addDrawnItem(DrawnItem item) {
    int page = _currentPage;
    if (_drawnItemsByPage[page] == null) {
      _drawnItemsByPage[page] = [];
    }
    _drawnItemsByPage[page]!.add(item);
  }

  Offset _convertToPdfCoordinates(Offset globalPosition) {
    RenderBox? renderBox = pdfViewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      Offset localPosition = renderBox.globalToLocal(globalPosition);
      Offset pdfPosition = (localPosition + _pdfViewerController.scrollOffset) / _pdfViewerController.zoomLevel;
      return pdfPosition;
    } else {
      return globalPosition;
    }
  }

  Future<void> _saveScreenshot() async {
    final imageUint8List = await _screenshotController.capture();
    if (imageUint8List != null) {
      try {
        final result = await SaverGallery.saveImage(
          imageUint8List,
          quality: 100,
          name: "screenshot_${DateTime.now().millisecondsSinceEpoch}.png",
          androidRelativePath: "Pictures/Screenshots",
          androidExistNotSave: false, // Her zaman kaydet, varsa üzerine yaz
        );

        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ekran görüntüsü başarıyla galeriye kaydedildi.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ekran görüntüsü kaydedilemedi: ${result.errorMessage}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ekran görüntüsü alınamadı.')),
      );
    }
  }  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 30,
            ),
            const SizedBox(width: 8),
            Text(
              'Kelibu',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Pro',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: backgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KelibuDoodle (Beta)',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'Sayfa: $_currentPage / $_totalPages',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
          Container(
            height: 50,
            color: backgroundColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildIconButton(Icons.edit, Colors.red, 'Kalem'),
                  _buildIconButton(Icons.brush, Colors.blue, 'Fırça'),
                  _buildIconButton(Icons.circle_outlined, Colors.green, 'Daire'),
                  _buildIconButton(Icons.text_fields, Colors.orange, 'Metin Ekle', onPressed: _startAddingText),
                  _buildIconButton(Icons.pan_tool, Colors.cyan, 'Gezinme', onPressed: () {
                    setState(() {
                      _isPanningMode = true;
                      _isDrawingMode = false;
                      _isAddingText = false;
                      _isDrawingCircle = false;
                      _isEraserMode = false;
                    });
                  }),
                  _buildIconButton(Icons.save_alt, Colors.purple, 'Kaydet', onPressed: _saveScreenshot),
                  _buildIconButton(Icons.search, Colors.indigo, 'Sayfaya Git', onPressed: _showGoToPageDialog),
                  _buildIconButton(Icons.zoom_in, Colors.brown, 'Yakınlaştır', onPressed: () {
                    _pdfViewerController.zoomLevel += 0.25;
                  }),
                  _buildIconButton(Icons.zoom_out, Colors.brown, 'Uzaklaştır', onPressed: () {
                    _pdfViewerController.zoomLevel -= 0.25;
                  }),
                  _buildIconButton(Icons.delete, Colors.red, 'Silgi', onPressed: () {
                    setState(() {
                      _isEraserMode = true;
                      _isDrawingMode = false;
                      _isAddingText = false;
                      _isDrawingCircle = false;
                      _isPanningMode = false;
                    });
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: Stack(
                children: [
                  SfPdfViewer.asset(
                    widget.pdfAssetPath,
                    key: pdfViewerKey,
                    controller: _pdfViewerController,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      setState(() {
                        _totalPages = details.document.pages.count;
                      });
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      setState(() {
                        _currentPage = details.newPageNumber;
                      });
                    },
                    enableDoubleTapZooming: true,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,
                    onZoomLevelChanged: (PdfZoomDetails details) {
                      setState(() {
                        _pdfScale = details.newZoomLevel;
                      });
                    },
                  ),
                  Positioned.fill(
                    child: GestureDetector(
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      onScaleEnd: _handleScaleEnd,
                      child: CustomPaint(
                        painter: DrawingPainter(
                          _drawnItemsByPage,
                          _pdfViewerController,
                          _currentPage,
                        ),
                        child: Container(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildIconButton(IconData icon, Color color, String tooltip, {VoidCallback? onPressed}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed ??
                  () {
                setState(() {
                  _isDrawingMode = icon == Icons.edit || icon == Icons.brush;
                  _isAddingText = false;
                  _isDrawingCircle = icon == Icons.circle_outlined;
                  _isPanningMode = false;
                  _isEraserMode = false;
                  _currentColor = color;
                  if (icon == Icons.edit) {
                    _currentStrokeWidth = 2.0;
                  } else if (icon == Icons.brush) {
                    _currentStrokeWidth = 5.0;
                  }
                });
              },
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScaleFactor = _pdfViewerController.zoomLevel;
    Offset globalPosition = details.focalPoint;
    Offset pdfPosition = _convertToPdfCoordinates(globalPosition);
    if (_isDrawingMode) {
      setState(() {
        _addDrawnItem(DrawnItem(
          points: [pdfPosition],
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          type: DrawnItemType.freehand,
          page: _currentPage,
        ));
      });
    } else if (_isAddingText) {
      setState(() {
        _textPosition = pdfPosition;
        _addDrawnItem(DrawnItem(
          points: [pdfPosition],
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          type: DrawnItemType.text,
          text: _textToAdd,
          fontSize: _currentFontSize,
          page: _currentPage,
        ));
        _isAddingText = false;
        _isPanningMode = true;
      });
    } else if (_isDrawingCircle) {
      setState(() {
        _circleStart = pdfPosition;
      });
    } else if (_isEraserMode) {
      _eraseAtPoint(pdfPosition);
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    Offset globalPosition = details.focalPoint;
    Offset pdfPosition = _convertToPdfCoordinates(globalPosition);
    if (_isDrawingMode) {
      setState(() {
        _drawnItemsByPage[_currentPage]!.last.points.add(pdfPosition);
      });
    } else if (_isDrawingCircle && _circleStart != null) {
      setState(() {
        _circleRadius = (_circleStart! - pdfPosition).distance;
      });
    } else if (_isPanningMode) {
      _pdfViewerController.zoomLevel = (_baseScaleFactor * details.scale).clamp(1.0, 3.0);
      _pdfViewerController.jumpTo(
        xOffset: _pdfViewerController.scrollOffset.dx - details.focalPointDelta.dx,
        yOffset: _pdfViewerController.scrollOffset.dy - details.focalPointDelta.dy,
      );
    } else if (_isEraserMode) {
      _eraseAtPoint(pdfPosition);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isDrawingCircle && _circleStart != null) {
      setState(() {
        _addDrawnItem(DrawnItem(
          points: [_circleStart!],
          color: _currentColor,
          strokeWidth: _currentStrokeWidth,
          type: DrawnItemType.circle,
          radius: _circleRadius,
          page: _currentPage,
        ));
        _circleStart = null;
        _circleRadius = 20.0;
      });
    }
  }

  void _eraseAtPoint(Offset point) {
    setState(() {
      _drawnItemsByPage[_currentPage]?.removeWhere((item) {
        if (item.type == DrawnItemType.freehand) {
          return item.points.any((p) => (p - point).distance < 20 / _pdfViewerController.zoomLevel);
        } else if (item.type == DrawnItemType.circle) {
          return (item.points.first - point).distance < (item.radius ?? 0);
        } else if (item.type == DrawnItemType.text) {
          return (item.points.first - point).distance < 20 / _pdfViewerController.zoomLevel;
        }
        return false;
      });
    });
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }
}

class DrawnItem {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final DrawnItemType type;
  final String? text;
  final double? radius;
  final double? fontSize;
  final int page;

  DrawnItem({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.type,
    this.text,
    this.radius,
    this.fontSize,
    required this.page,
  });
}

enum DrawnItemType { freehand, circle, text }

class DrawingPainter extends CustomPainter {
  final Map<int, List<DrawnItem>> drawnItemsByPage;
  final PdfViewerController pdfController;
  final int currentPage;

  DrawingPainter(this.drawnItemsByPage, this.pdfController, this.currentPage);

  @override
  void paint(Canvas canvas, Size size) {
    for (var item in drawnItemsByPage[currentPage] ?? []) {
      final paint = Paint()
        ..color = item.color
        ..strokeWidth = item.strokeWidth
        ..style = PaintingStyle.stroke;

      switch (item.type) {
        case DrawnItemType.freehand:
          if (item.points.length > 1) {
            final path = Path();
            path.moveTo(
              item.points.first.dx * pdfController.zoomLevel - pdfController.scrollOffset.dx,
              item.points.first.dy * pdfController.zoomLevel - pdfController.scrollOffset.dy,
            );
            for (int i = 1; i < item.points.length; i++) {
              path.lineTo(
                item.points[i].dx * pdfController.zoomLevel - pdfController.scrollOffset.dx,
                item.points[i].dy * pdfController.zoomLevel - pdfController.scrollOffset.dy,
              );
            }
            canvas.drawPath(path, paint);
          }
          break;
        case DrawnItemType.circle:
          if (item.points.isNotEmpty && item.radius != null) {
            Offset center = Offset(
              item.points.first.dx * pdfController.zoomLevel - pdfController.scrollOffset.dx,
              item.points.first.dy * pdfController.zoomLevel - pdfController.scrollOffset.dy,
            );
            double scaledRadius = item.radius! * pdfController.zoomLevel;
            canvas.drawCircle(center, scaledRadius, paint);
          }
          break;
        case DrawnItemType.text:
          if (item.points.isNotEmpty && item.text != null) {
            final textSpan = TextSpan(
              text: item.text,
              style: TextStyle(
                color: item.color,
                fontSize: (item.fontSize ?? 16) * pdfController.zoomLevel,
              ),
            );
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            Offset position = Offset(
              item.points.first.dx * pdfController.zoomLevel - pdfController.scrollOffset.dx,
              item.points.first.dy * pdfController.zoomLevel - pdfController.scrollOffset.dy,
            );
            textPainter.paint(canvas, position);
          }
          break;
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.drawnItemsByPage != drawnItemsByPage ||
        oldDelegate.pdfController.zoomLevel != pdfController.zoomLevel ||
        oldDelegate.pdfController.scrollOffset != pdfController.scrollOffset ||
        oldDelegate.currentPage != currentPage;
  }
}


class ColorfulDoodleText extends StatelessWidget {
  final String text;
  final double fontSize;

  const ColorfulDoodleText({
    Key? key,
    required this.text,
    this.fontSize = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DoodleTextPainter(text: text, fontSize: fontSize),
      child: Container(
        padding: EdgeInsets.all(fontSize / 2),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

class _DoodleTextPainter extends CustomPainter {
  final String text;
  final double fontSize;
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  _DoodleTextPainter({required this.text, required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
      color: Colors.black,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final random = math.Random(42);  // Sabit bir tohum kullanarak tutarlı rastgelelik sağlıyoruz

    for (int i = 0; i < text.length; i++) {
      final charOffset = textPainter.getOffsetForCaret(TextPosition(offset: i), Rect.zero);
      final charSize = textPainter.size.height;

      final paint = Paint()
        ..color = colors[random.nextInt(colors.length)]
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      for (int j = 0; j < 3; j++) {  // Her karakter için 3 karalama çizgisi
        final startX = charOffset.dx + random.nextDouble() * charSize * 0.2;
        final startY = charOffset.dy + random.nextDouble() * charSize;
        final endX = startX + random.nextDouble() * charSize * 0.6;
        final endY = startY + (random.nextDouble() - 0.5) * charSize * 0.6;

        final controlPoint1X = startX + (endX - startX) / 3 + (random.nextDouble() - 0.5) * charSize * 0.2;
        final controlPoint1Y = startY + (endY - startY) / 3 + (random.nextDouble() - 0.5) * charSize * 0.2;
        final controlPoint2X = startX + 2 * (endX - startX) / 3 + (random.nextDouble() - 0.5) * charSize * 0.2;
        final controlPoint2Y = startY + 2 * (endY - startY) / 3 + (random.nextDouble() - 0.5) * charSize * 0.2;

        final path = Path()
          ..moveTo(startX, startY)
          ..cubicTo(controlPoint1X, controlPoint1Y, controlPoint2X, controlPoint2Y, endX, endY);

        canvas.drawPath(path, paint);
      }
    }

    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}