import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class MarketPage extends StatelessWidget {
  const MarketPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 30),
            const SizedBox(width: 8),
            const Text('Kelibu Market', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: AnimationLimiter(
        child: ListView(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              _buildLottieHeader(),
              _buildKelibuProBanner(context),
              _buildAdditionalBenefits(context),
              _buildPackageSets(context),
              _buildNormalPackages(context),
              _buildDiscountCampaign(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLottieHeader() {
    return Container(
      height: 200,
      child: Lottie.network(
        'https://assets9.lottiefiles.com/packages/lf20_xlmz9xwm.json',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildKelibuProBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kelibu PRO',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'EN İYİ DEĞER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tüm özelliklere sınırsız erişim!',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPricingOption('Aylık', '₺199'),
              _buildPricingOption('Yıllık', '₺899'),
              ElevatedButton(
                onPressed: () {
                  // Satın alma işlemi
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('HEMEN BAŞLA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOption(String period, String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalBenefits(BuildContext context) {
    final benefits = [
      {'icon': Icons.library_books, 'text': 'Tüm setlere erişim'},
      {'icon': Icons.new_releases, 'text': 'Tüm yeni özelliklere erken erişim'},
      {'icon': Icons.school, 'text': 'PhD Akademi dil kursu üyeliği %10 indirim'},
      {'icon': Icons.book, 'text': 'PhD Akademi Level 1-2-3 kitaplarına ücretsiz erişim'},
      {'icon': Icons.phone_android, 'text': 'SelfEnglish uygulamasında %25 indirim'},
      {'icon': Icons.track_changes, 'text': 'Özelleştirilmiş takip'},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Kelibu PRO Avantajları',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(benefit['icon'] as IconData, color: Colors.deepPurple, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      benefit['text'] as String,
                      style: const TextStyle(fontSize: 16, height: 1.3),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // PRO üyelik satın alma işlemi
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('PRO Üyelik Al', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPackageSets(BuildContext context) {
    final packageSets = [
      {'title': 'Akademi Seti', 'icon': Icons.school},
      {'title': 'Başlangıç Seti', 'icon': Icons.play_circle_filled},
      {'title': 'İleri Seviye Seti', 'icon': Icons.trending_up},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Özel Paket Setleri',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...packageSets.map((set) => _buildPackageSetTile(context, set['title'] as String, set['icon'] as IconData)),
      ],
    );
  }

  Widget _buildPackageSetTile(BuildContext context, String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPricingRow('Aylık', '₺29'),
                const SizedBox(height: 8),
                _buildPricingRow('3 Aylık', '₺50'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Satın alma işlemi
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Satın Al'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String period, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(period, style: const TextStyle(fontSize: 16)),
        Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNormalPackages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Normal Paketler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _buildPackageCard('Aylık Paket', '₺99'),
        _buildPackageCard('3 Aylık Paket', '₺169'),
      ],
    );
  }

  Widget _buildPackageCard(String title, String price) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                // Satın alma işlemi
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Satın Al'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountCampaign(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Özel Kampanya!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '3 ay boyunca %50 indirim',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Kampanya detayları
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('FIRSATI YAKALA', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}