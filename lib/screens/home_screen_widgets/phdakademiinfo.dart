import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class PhdAkademiInfo extends StatelessWidget {
  final bool isDarkMode;

  const PhdAkademiInfo({Key? key, required this.isDarkMode}) : super(key: key);

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.phdakademi.com');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDarkMode ? Colors.indigo.shade900 : Colors.blue.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r), // Yuvarlaklığı koruduk
      ),
      elevation: 2, // Elevation değeri korundu
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w), // Margin azaltıldı
      child: InkWell(
        onTap: _launchURL,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: isDarkMode
            ? Colors.indigo.shade700.withOpacity(0.2)
            : Colors.blue.shade300.withOpacity(0.2), // Splash efekti hafifletildi
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h), // Padding azaltıldı
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol Kısım: Logo ve Başlık
              Row(
                children: [
                  Container(
                    width: 25.w, // Logo boyutu küçültüldü
                    height: 25.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(5.r), // İç boşluk azaltıldı
                      child: Image.asset('assets/phd.png'),
                    ),
                  ),
                  SizedBox(width: 4.w), // Boşluk azaltıldı
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PhD Akademi",
                        style: TextStyle(
                          color:
                          isDarkMode ? Colors.white : Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp, // Font boyutu küçültüldü
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 2.h), // Boşluk azaltıldı
                      Text(
                        "Profesyonel Dil Eğitimi", // İtalik kaldırıldı ve metin sadeleştirildi
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white70
                              : Colors.blueGrey.shade800,
                          fontSize: 7.sp, // Font boyutu küçültüldü
                          // İtalik stil kaldırıldı
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Sağ Kısım: İkon
              Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    color: isDarkMode
                        ? Colors.white70
                        : Colors.blueGrey.shade800,
                    size: 12.sp, // İkon boyutu küçültüldü
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
