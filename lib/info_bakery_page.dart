import 'package:flutter/material.dart';

class InfoBakeryPage extends StatelessWidget {
  const InfoBakeryPage({super.key});

  static const Color darkBrown = Color(0xFF5D321D);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color lightBrown = Color(0xFFE8D5C4);
  static const Color backgroundBrown = Color(0xFFFFF8F1);

  void showInfoDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<String> contents,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundBrown,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Icon(icon, color: brown),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: contents
                .map(
                  (content) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: darkBrown,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tutup',
              style: TextStyle(
                color: brown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final infoItems = [
      {
        'title': 'Tentang Kami',
        'subtitle': 'Kenali cerita dan perjalanan Zia Bakery.',
        'icon': Icons.storefront_rounded,
        'contents': [
          'Zia Bakery hadir untuk memberikan pilihan kue yang lezat, menarik, dan berkualitas bagi setiap pelanggan.',
          'Kami menyediakan berbagai pilihan kue tradisional, kue ulang tahun, brownies, dan pastry yang cocok untuk menemani aktivitas sehari-hari maupun momen spesial.',
          'Melalui website ini, pelanggan dapat melihat koleksi produk, memilih kue favorit, dan melakukan pemesanan dengan lebih mudah.',
          'Kami berharap setiap produk Zia Bakery dapat menghadirkan kebahagiaan dalam setiap kesempatan.',
        ],
      },
      {
        'title': 'Jam Operasional',
        'subtitle': 'Informasi waktu pelayanan dan pengambilan pesanan.',
        'icon': Icons.access_time_rounded,
        'contents': [
          'Zia Bakery siap melayani pelanggan yang ingin melihat produk maupun melakukan pemesanan selama jam operasional berlangsung.',
          'Senin–Sabtu: 09.00–17.00 WIB',
          'Minggu: Tutup',
          'Pelanggan disarankan melakukan pemesanan terlebih dahulu agar produk yang diinginkan dapat dipersiapkan sesuai kebutuhan.',
          'Untuk pesanan kue ulang tahun atau pesanan khusus, sebaiknya pesan lebih awal agar persiapannya lebih maksimal.',
        ],
      },
      {
        'title': 'Kontak Kami',
        'subtitle': 'Hubungi kami untuk bertanya atau memesan kue.',
        'icon': Icons.phone_rounded,
        'contents': [
          'Kami siap membantu pelanggan yang membutuhkan informasi mengenai produk, harga, ketersediaan stok, maupun pesanan khusus.',
          'WhatsApp: 0812-3456-7891',
          'Silakan hubungi kami untuk mendapatkan informasi lebih lanjut mengenai produk yang tersedia.',
          'Sampaikan nama produk dan jumlah yang diinginkan agar proses pemesanan dapat dilakukan dengan lebih mudah.',
        ],
      },
      {
        'title': 'Lokasi Toko',
        'subtitle': 'Informasi alamat toko dan pengambilan pesanan.',
        'icon': Icons.location_on_rounded,
        'contents': [
          'Zia Bakery berlokasi di kawasan yang mudah dijangkau oleh pelanggan.',
          'Alamat: Jl. Raya Bakery No. 10, Surabaya, Jawa Timur.',
          'Pelanggan dapat menggunakan informasi alamat tersebut sebagai acuan untuk mengetahui lokasi toko dan pengambilan pesanan.',
          'Pastikan jadwal pengambilan sesuai dengan waktu yang telah dipilih saat melakukan pemesanan.',
        ],
      },
      {
        'title': 'Email Toko',
        'subtitle': 'Hubungi kami melalui surat elektronik.',
        'icon': Icons.email_rounded,
        'contents': [
          'Zia Bakery menyediakan informasi kontak email untuk memudahkan pelanggan menyampaikan pertanyaan, masukan, maupun saran.',
          'Email: ziabakery@gmail.com',
          'Kamu dapat menggunakan email untuk menanyakan informasi produk atau menyampaikan pesan kepada Zia Bakery.',
          'Tuliskan subjek dan isi pesan dengan jelas agar informasi yang disampaikan mudah dipahami.',
        ],
      },
      {
        'title': 'Media Sosial',
        'subtitle': 'Ikuti informasi produk dan aktivitas toko.',
        'icon': Icons.camera_alt_rounded,
        'contents': [
          'Ikuti media sosial Zia Bakery untuk melihat koleksi kue, inspirasi kue ulang tahun, dan informasi produk terbaru.',
          'Instagram: @ziabakery',
          'TikTok: @ziabakery',
          'Media sosial menjadi tempat untuk mengenal produk Zia Bakery lebih dekat dan mendapatkan inspirasi untuk berbagai momen spesial.',
        ],
      },
    ];

    return Scaffold(
      backgroundColor: backgroundBrown,
      appBar: AppBar(
        backgroundColor: darkBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Informasi Zia Bakery',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: lightBrown,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cake_rounded,
                    color: darkBrown,
                    size: 42,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Selamat Datang di Zia Bakery!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Temukan berbagai pilihan kue favorit untuk menemani hari-harimu. '
                    'Kami menyediakan informasi produk, pemesanan, dan layanan '
                    'yang dirancang agar pengalaman berbelanja menjadi lebih mudah.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: darkBrown,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informasi Toko',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Pilih kotak informasi untuk mengetahui lebih lanjut tentang Zia Bakery.',
              style: TextStyle(
                fontSize: 13,
                color: brown,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: infoItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = infoItems[index];

                  return SizedBox(
                    width: 165,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          showInfoDialog(
                            context,
                            title: item['title'] as String,
                            icon: item['icon'] as IconData,
                            contents: List<String>.from(
                              item['contents'] as List<String>,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: lightBrown),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: lightBrown.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: darkBrown,
                                      size: 24,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: brown,
                                    size: 27,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['title'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: darkBrown,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Expanded(
                                child: Text(
                                  item['subtitle'] as String,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: brown,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Pertanyaan Umum',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 12),
            _buildFaq(
              question: 'Bagaimana cara memesan kue?',
              answer:
                  'Pilih produk yang diinginkan, masukkan ke keranjang, '
                  'kemudian lanjutkan ke halaman checkout untuk melengkapi '
                  'informasi pesanan.',
            ),
            _buildFaq(
              question: 'Apakah tersedia kue ulang tahun?',
              answer:
                  'Ya, Zia Bakery menyediakan kategori kue ulang tahun '
                  'dengan berbagai pilihan produk yang dapat dilihat di halaman beranda.',
            ),
            _buildFaq(
              question: 'Bagaimana cara melihat pesanan?',
              answer:
                  'Kamu dapat membuka menu Riwayat Pesanan untuk melihat '
                  'informasi pesanan yang telah dibuat beserta statusnya.',
            ),
            _buildFaq(
              question: 'Apakah bisa menambahkan catatan pesanan?',
              answer:
                  'Bisa. Kamu dapat menuliskan catatan khusus pada halaman checkout, '
                  'misalnya ucapan pada kue atau permintaan tertentu.',
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    color: brown,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Zia Bakery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manisnya Kue, Hangatnya Kebersamaan.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: brown.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaq({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lightBrown),
      ),
      child: ExpansionTile(
        iconColor: brown,
        collapsedIconColor: brown,
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkBrown,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: brown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}