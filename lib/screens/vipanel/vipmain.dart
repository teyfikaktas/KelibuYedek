import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../doodle/doodle.dart';

class VipPageController extends GetxController {
  void showSetDetails(Map<String, dynamic> set) {
    Get.bottomSheet(
      PremiumSetDetailsSheet(set: set),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class VipPage extends StatelessWidget {
  final List<Map<String, dynamic>> allSets;
  final bool isWideScreen;
  final controller = Get.put(VipPageController());
  final isDarkMode = false.obs;

  VipPage({
    super.key,
    required this.allSets,
    required this.isWideScreen,
  }) {
    _loadDarkModePreference();
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('darkMode') ?? false;
  }

  Future<void> _toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = !isDarkMode.value;
    await prefs.setBool('darkMode', isDarkMode.value);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode.value
                  ? [
                      const Color(0xFF1A237E),
                      const Color(0xFF000A23),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
          ),
          child: AnimationConfiguration.synchronized(
            duration: const Duration(milliseconds: 375),
            child: ListView(
              padding: const EdgeInsets.only(top: 20),
              children: [
                // Dark Mode Toggle Button

                // Doodle
                SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: KelibuDoodlePromo(
                        color: isDarkMode.value
                            ? Colors.amber.shade200
                            : Colors.indigo.shade900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pro Badge
                // Live Quiz Beta
                SlideAnimation(
                  horizontalOffset: -50.0,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade700,
                              Colors.purple.shade900,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              top: -20,
                              child: Icon(
                                Icons.sports_esports,
                                size: 100,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.book,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'BETA',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Canlı Yarış',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Yakında arkadaşlarınızla canlı yarışabileceksiniz!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Sets
                SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildPremiumSets(),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildPremiumSets() {
    return Column(
      // Burada Obx kaldırıldı
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => Padding(
              // Sadece tema rengi değişen kısım Obx ile sarıldı
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Premium Setler',
                style: GoogleFonts.poppins(
                  fontSize: isWideScreen ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode.value ? Colors.white : Colors.indigo.shade900,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: allSets.length,
          itemBuilder: (context, index) {
            final set = allSets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildPremiumCard(context, set),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context, Map<String, dynamic> set) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final cardHeight = maxWidth * (isWideScreen ? 0.4 : 0.6);
        final imageHeight = cardHeight * 0.65;

        return GestureDetector(
          onTap: () => controller.showSetDetails(set),
          child: Obx(() => Container(
                height: cardHeight,
                decoration: BoxDecoration(
                  color: isDarkMode.value
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode.value
                        ? Colors.white.withOpacity(0.2)
                        : Colors.indigo.shade900.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl:
                                'https://kelibu.net/storage/${set["image"]}',
                            height: imageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: imageHeight,
                              color: isDarkMode.value
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDarkMode.value
                                        ? Colors.amber.shade200
                                        : Colors.indigo,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: imageHeight,
                              color: isDarkMode.value
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: (isDarkMode.value
                                        ? Colors.white
                                        : Colors.indigo)
                                    .withOpacity(0.3),
                                size: maxWidth * 0.1,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade700,
                                    Colors.amber.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: isWideScreen ? 18 : 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PRO',
                                    style: GoogleFonts.poppins(
                                      fontSize: isWideScreen ? 13 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                set["title"],
                                style: GoogleFonts.poppins(
                                  fontSize: isWideScreen
                                      ? maxWidth * 0.038
                                      : maxWidth * 0.042,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode.value
                                      ? Colors.white
                                      : Colors.indigo.shade900,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDarkMode.value
                                        ? Colors.amber.shade200
                                        : Colors.indigo)
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: isDarkMode.value
                                    ? Colors.amber.shade200
                                    : Colors.indigo.shade900,
                                size: maxWidth * 0.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        );
      },
    );
  }
}

class PremiumSetDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> set;

  const PremiumSetDetailsSheet({
    super.key,
    required this.set,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1A237E),
                  const Color(0xFF000A23),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          set["title"],
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : Colors.indigo.shade900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade700,
                              Colors.amber.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'PRO',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: 'https://kelibu.net/storage/${set["image"]}',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 220,
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.amber.shade200 : Colors.indigo,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 220,
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade100,
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: (isDark ? Colors.white : Colors.indigo)
                              .withOpacity(0.3),
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    set["description"],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: Colors.amber.withOpacity(0.3),
              ),
              child: Text(
                'Kapat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
