
import 'package:flutter/material.dart';
import 'model/kue.dart';

class CakeCard extends StatelessWidget {
  final Kue cake;
  final bool isSaved;
  final double rating;
  final List<Map<String, dynamic>> reviews;
  final VoidCallback onSave;
  final VoidCallback onAddToCart;
  final VoidCallback onImageTap;

  const CakeCard({
    super.key,
    required this.cake,
    required this.isSaved,
    required this.rating,
    this.reviews = const [],
    required this.onSave,
    required this.onAddToCart,
    required this.onImageTap,
  });

  static const Color darkBrown = Color(0xFF5D321D);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color lightBrown = Color(0xFFE8D5C4);
  static const Color backgroundBrown = Color(0xFFFFF8F1);

  String _formatTanggal(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '';
    }

    try {
      final tanggal = DateTime.parse(value.toString()).toLocal();
      const bulan = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];

      return '${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
    } catch (_) {
      return '';
    }
  }

  void _bukaUlasan(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Ulasan ${cake.name}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: darkBrown,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 23),
                    const SizedBox(width: 5),
                    Text(
                      rating > 0 ? rating.toStringAsFixed(1) : '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${reviews.length} ulasan)',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Expanded(
                  child: reviews.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 48,
                                color: lightBrown,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Belum ada ulasan untuk produk ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            final nilai = double.tryParse(
                                  (review['rating'] ?? '').toString(),
                                ) ??
                                0;
                            final isi = (review['ulasan'] ?? '')
                                .toString()
                                .trim();
                            final tanggal = _formatTanggal(
                              review['tanggalUlasan'] ??
                                  review['tanggal'],
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(5, (i) {
                                      return Icon(
                                        i < nilai.round()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 20,
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      nilai.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: darkBrown,
                                      ),
                                    ),
                                  ],
                                ),
                                if (tanggal.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tanggal,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                                if (isi.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    isi,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 14, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: lightBrown.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: onImageTap,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  height: 155,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: backgroundBrown,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Image.asset(
                    cake.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.image_not_supported_outlined,
                        size: 45,
                        color: brown,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: onSave,
                    tooltip: isSaved ? 'Hapus dari tersimpan' : 'Simpan kue',
                    icon: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : brown,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cake.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () => _bukaUlasan(context),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 17,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: darkBrown,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Lihat ulasan (${reviews.length})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: brown,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    cake.getFormattedPrice(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cake.getStockInfo(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: cake.stock > 0 ? Colors.black54 : Colors.red,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cake.isAvailable() ? onAddToCart : null,
                      icon: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 16,
                      ),
                      label: Text(
                        cake.isAvailable() ? 'Tambah' : 'Habis',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
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
}