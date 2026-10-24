import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/kue.dart';
import 'data/kue_data.dart';
import 'cake_card.dart';
import 'checkout_page.dart';
import 'info_bakery_page.dart';

// ==========================================
// DATA FAVORIT DAN PENYIMPANAN PERMANEN
// ==========================================

const String favoriteProductsKey = 'zia_bakery_favorite_products';

final ValueNotifier<List<Kue>> favoriteProductsNotifier =
    ValueNotifier<List<Kue>>([]);

bool _favoriteProductsLoaded = false;
Future<void>? _loadingFavorites;

/// Memuat produk favorit dari SharedPreferences.
Future<void> loadFavoriteProducts() async {
  if (_favoriteProductsLoaded) return;

  _loadingFavorites ??= _loadSavedFavorites();

  try {
    await _loadingFavorites;
  } finally {
    _loadingFavorites = null;
  }
}

Future<void> _loadSavedFavorites() async {
  final prefs = await SharedPreferences.getInstance();

  final savedNames = prefs.getStringList(favoriteProductsKey) ?? [];

  final normalizedNames = savedNames
      .map((name) => name.trim().toLowerCase())
      .toSet();

  final favorites = kueData.where((cake) {
    return normalizedNames.contains(cake.name.trim().toLowerCase());
  }).toList();

  favoriteProductsNotifier.value = favorites;
  _favoriteProductsLoaded = true;
}

/// Menambah atau menghapus favorit dan menyimpannya secara permanen.
Future<void> toggleFavoriteProduct(Kue cake) async {
  await loadFavoriteProducts();

  final updatedFavorites =
      List<Kue>.from(favoriteProductsNotifier.value);

  final normalizedName = cake.name.trim().toLowerCase();

  final alreadyFavorite = updatedFavorites.any(
    (item) => item.name.trim().toLowerCase() == normalizedName,
  );

  if (alreadyFavorite) {
    updatedFavorites.removeWhere(
      (item) => item.name.trim().toLowerCase() == normalizedName,
    );
  } else {
    updatedFavorites.add(cake);
  }

  // Perbarui halaman Home dan Favorit secara langsung.
  favoriteProductsNotifier.value = updatedFavorites;

  // Simpan nama produk agar favorit tetap ada setelah aplikasi ditutup.
  final prefs = await SharedPreferences.getInstance();

  await prefs.setStringList(
    favoriteProductsKey,
    updatedFavorites.map((item) => item.name).toList(),
  );
}

// ==========================================
// HOME CONTENT
// ==========================================

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController searchController = TextEditingController();

  final Map<Kue, int> cart = {};
  final Map<Kue, double> ratings = {};
  final Map<Kue, List<Map<String, dynamic>>> productReviews = {};

  String searchText = '';

  static const Color darkBrown = Color(0xFF5D321D);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color lightBrown = Color(0xFFE8D5C4);
  static const Color backgroundBrown = Color(0xFFFFF8F1);

  final List<String> categories = const [
    'Kue Tradisional',
    'Kue Ulang Tahun',
    'Pastry',
    'Brownies',
    'Roti',
    'Minuman',
  ];

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      if (!mounted) return;

      setState(() {
        searchText = searchController.text.trim().toLowerCase();
      });
    });

    loadFavoriteProducts();
    loadProductRatings();
  }

  String normalisasiNama(dynamic value) {
    return value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // ==========================================
  // RATING DAN ULASAN
  // ==========================================

  Future<void> loadProductRatings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('riwayat_pesanan') ?? <String>[];

      final Map<String, List<double>> ratingData = {};
      final Map<String, List<Map<String, dynamic>>> reviewData = {};

      for (final orderJson in history) {
        try {
          final decoded = jsonDecode(orderJson);
          if (decoded is! Map) continue;

          final order = Map<String, dynamic>.from(decoded);
          final items = order['items'];

          if (items is! List) continue;

          for (final itemData in items) {
            if (itemData is! Map) continue;

            final item = Map<String, dynamic>.from(itemData);

            final nama = normalisasiNama(
              item['nama'] ?? item['name'] ?? '',
            );

            if (nama.isEmpty) continue;

            final rating = double.tryParse(
              (item['rating'] ?? '').toString().replaceAll(',', '.'),
            );

            if (rating == null || rating < 1 || rating > 5) continue;

            ratingData.putIfAbsent(nama, () => <double>[]);
            ratingData[nama]!.add(rating);

            final ulasan = (item['ulasan'] ?? item['review'] ?? '')
                .toString()
                .trim();

            if (ulasan.isNotEmpty) {
              reviewData.putIfAbsent(
                nama,
                () => <Map<String, dynamic>>[],
              );

              reviewData[nama]!.add({
                'rating': rating,
                'ulasan': ulasan,
                'tanggalUlasan':
                    item['tanggalUlasan'] ?? item['tanggal'] ?? '',
              });
            }
          }
        } catch (e) {
          debugPrint('Data riwayat dilewati: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        ratings.clear();
        productReviews.clear();

        for (final cake in kueData) {
          final nama = normalisasiNama(cake.name);
          final daftarRating = ratingData[nama] ?? <double>[];

          if (daftarRating.isNotEmpty) {
            final total = daftarRating.reduce((a, b) => a + b);
            ratings[cake] = total / daftarRating.length;
          }

          productReviews[cake] = List<Map<String, dynamic>>.from(
            reviewData[nama] ?? <Map<String, dynamic>>[],
          );
        }
      });
    } catch (e) {
      debugPrint('Gagal memuat rating dan ulasan: $e');
    }
  }

  double getRating(Kue cake) => ratings[cake] ?? 0.0;

  List<Map<String, dynamic>> getReviews(Kue cake) {
    return productReviews[cake] ?? [];
  }

  // ==========================================
  // PRODUK DAN FAVORIT
  // ==========================================

  List<Kue> getProductsByCategory(String category) {
    return kueData.where((cake) {
      final cocokNama = cake.name.toLowerCase().contains(searchText);
      return cake.category == category && cocokNama;
    }).toList();
  }

  Future<void> toggleSaved(Kue cake) async {
    try {
      await toggleFavoriteProduct(cake);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favoriteProductsNotifier.value.any(
              (item) =>
                  item.name.trim().toLowerCase() ==
                  cake.name.trim().toLowerCase(),
            )
                ? '${cake.name} ditambahkan ke favorit'
                : '${cake.name} dihapus dari favorit',
          ),
          backgroundColor: brown,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      debugPrint('Gagal menyimpan favorit: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan favorit. Silakan coba lagi.'),
          backgroundColor: darkBrown,
        ),
      );
    }
  }

  // ==========================================
  // KERANJANG
  // ==========================================

  void addToCart(Kue cake) {
    setState(() {
      final currentQuantity = cart[cake] ?? 0;

      if (currentQuantity < cake.stock) {
        cart[cake] = currentQuantity + 1;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cake.name} ditambahkan ke keranjang'),
            backgroundColor: brown,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah melebihi stok yang tersedia'),
            backgroundColor: darkBrown,
          ),
        );
      }
    });
  }

  void decreaseQuantity(Kue cake) {
    setState(() {
      if (!cart.containsKey(cake)) return;

      if (cart[cake]! > 1) {
        cart[cake] = cart[cake]! - 1;
      } else {
        cart.remove(cake);
      }
    });
  }

  int getCartItemCount() {
    return cart.values.fold(0, (total, quantity) => total + quantity);
  }

  int getCartTotal() {
    int total = 0;

    cart.forEach((cake, quantity) {
      total += cake.price * quantity;
    });

    return total;
  }

  String formatRupiah(int value) {
    final priceString = value.toString();
    String result = '';

    for (int i = 0; i < priceString.length; i++) {
      if (i > 0 && (priceString.length - i) % 3 == 0) {
        result += '.';
      }

      result += priceString[i];
    }

    return 'Rp$result';
  }

  // Stok berkurang setelah checkout berhasil.
  void processSuccessfulCheckout() {
    if (!mounted) return;

    setState(() {
      cart.forEach((cake, quantity) {
        cake.stock = (cake.stock - quantity).clamp(0, cake.stock);
      });

      cart.clear();
    });
  }

  // ==========================================
  // INFO BAKERY
  // ==========================================

  void openInfoBakery() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const InfoBakeryPage(),
      ),
    );
  }

  // ==========================================
  // DETAIL PRODUK
  // ==========================================

  Future<void> showCakeDetail(Kue cake) async {
    await loadProductRatings();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final screenSize = MediaQuery.of(dialogContext).size;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: screenSize.height * 0.88,
            ),
            child: SizedBox(
              width: screenSize.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              height: screenSize.width < 500 ? 170 : 210,
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: backgroundBrown,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Image.asset(
                                cake.image,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 48,
                                    color: brown,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            cake.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cake.description,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            cake.getFormattedPrice(),
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: brown,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cake.getStockInfo(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Rating produk',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 5),
                              Text(
                                getRating(cake) > 0
                                    ? getRating(cake).toStringAsFixed(1)
                                    : 'Belum ada rating',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkBrown,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (getReviews(cake).isNotEmpty)
                                Text(
                                  '(${getReviews(cake).length} ulasan)',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Ulasan pelanggan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (getReviews(cake).isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Belum ada ulasan untuk produk ini.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ...getReviews(cake).map((review) {
                              final nilai = double.tryParse(
                                    (review['rating'] ?? '').toString(),
                                  ) ??
                                  0;

                              final isi =
                                  (review['ulasan'] ?? '').toString();

                              final tanggal =
                                  (review['tanggalUlasan'] ?? '').toString();

                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: backgroundBrown,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 19,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 5),
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
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    if (isi.trim().isNotEmpty) ...[
                                      const SizedBox(height: 7),
                                      Text(
                                        isi,
                                        style: const TextStyle(height: 1.4),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: brown,
                              minimumSize: const Size(0, 46),
                              side: const BorderSide(color: brown),
                            ),
                            child: const Text('Tutup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: cake.isAvailable()
                                ? () {
                                    Navigator.pop(dialogContext);
                                    addToCart(cake);
                                  }
                                : null,
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                            ),
                            label: Text(
                              cake.isAvailable() ? 'Tambah' : 'Habis',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // KATEGORI
  // ==========================================

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Kue Tradisional':
        return Icons.cake_outlined;
      case 'Kue Ulang Tahun':
        return Icons.celebration_outlined;
      case 'Pastry':
        return Icons.bakery_dining;
      case 'Brownies':
        return Icons.cookie_outlined;
      case 'Roti':
        return Icons.breakfast_dining;
      case 'Minuman':
        return Icons.local_cafe_outlined;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Widget buildCategories() {
    final semuaKategori = ['Semua', ...categories];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: semuaKategori.length,
        itemBuilder: (context, index) {
          final nama = semuaKategori[index];

          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: lightBrown,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    nama == 'Semua'
                        ? Icons.grid_view_rounded
                        : getCategoryIcon(nama),
                    color: brown,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  nama,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: darkBrown,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildCategorySection(String title, List<Kue> products) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 365,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 18),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final cake = products[index];

              return CakeCard(
                cake: cake,
                isSaved: favoriteProductsNotifier.value.any(
                  (item) =>
                      item.name.trim().toLowerCase() ==
                      cake.name.trim().toLowerCase(),
                ),
                rating: getRating(cake),
                reviews: getReviews(cake),
                onSave: () => toggleSaved(cake),
                onAddToCart: () => addToCart(cake),
                onImageTap: () => showCakeDetail(cake),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // TAMPILAN KERANJANG
  // ==========================================

  void showCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Keranjang Saya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: cart.isEmpty
                        ? const Center(
                            child: Text(
                              'Keranjang masih kosong',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final cake = cart.keys.elementAt(index);
                              final quantity = cart[cake]!;

                              return ListTile(
                                leading: SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: Image.asset(
                                    cake.image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.cake, color: brown),
                                  ),
                                ),
                                title: Text(
                                  cake.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: darkBrown,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cake.getFormattedPrice()} x $quantity',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        decreaseQuantity(cake);
                                        setModalState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: brown,
                                      ),
                                    ),
                                    Text('$quantity'),
                                    IconButton(
                                      onPressed: () {
                                        addToCart(cake);
                                        setModalState(() {});
                                      },
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: brown,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: backgroundBrown,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: darkBrown,
                              ),
                            ),
                            Text(
                              formatRupiah(getCartTotal()),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: brown,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: cart.isEmpty
                                ? null
                                : () async {
                                    final cartCheckout =
                                        Map<Kue, int>.from(cart);

                                    Navigator.pop(sheetContext);

                                    await Navigator.push<void>(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => CheckoutPage(
                                          cart: cartCheckout,
                                          onOrderSuccess:
                                              processSuccessfulCheckout,
                                        ),
                                      ),
                                    );

                                    await loadProductRatings();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                            child: const Text(
                              'Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // HEADER DAN HALAMAN HOME
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: const BoxDecoration(
              color: brown,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zia Bakery 🍰',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Temukan kue favoritmu',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ikon keranjang dan Info Bakery berdampingan.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              tooltip: 'Keranjang',
                              onPressed: showCart,
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                color: Colors.white,
                              ),
                            ),
                            if (getCartItemCount() > 0)
                              Positioned(
                                right: 5,
                                top: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: darkBrown,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${getCartItemCount()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Info Bakery',
                          onPressed: openInfoBakery,
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari produk yang kamu suka...',
                      prefixIcon: Icon(Icons.search, color: brown),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          buildCategories(),
          const SizedBox(height: 10),

          ...categories.map(
            (category) => buildCategorySection(
              category,
              getProductsByCategory(category),
            ),
          ),

          if (searchText.isNotEmpty &&
              !kueData.any(
                (cake) => cake.name.toLowerCase().contains(searchText),
              ))
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Produk tidak ditemukan.',
                style: TextStyle(color: Colors.grey),
              ),
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ==========================================
// HALAMAN FAVORIT
// ==========================================

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  static const Color darkBrown = Color(0xFF5D321D);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color backgroundBrown = Color(0xFFFFF8F1);

  @override
  void initState() {
    super.initState();
    loadFavoriteProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBrown,
      body: ValueListenableBuilder<List<Kue>>(
        valueListenable: favoriteProductsNotifier,
        builder: (context, favorites, child) {
          if (favorites.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 70,
                      color: Color(0xFFE8D5C4),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum Ada Produk Favorit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBrown,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tekan ikon hati pada produk di Home '
                      'untuk menyimpannya di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final cake = favorites[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      cake.image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.cake_outlined,
                        size: 40,
                        color: brown,
                      ),
                    ),
                  ),
                  title: Text(
                    cake.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      cake.getFormattedPrice(),
                      style: const TextStyle(
                        color: brown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Hapus dari favorit',
                    onPressed: () async {
                      try {
                        await toggleFavoriteProduct(cake);
                      } catch (e) {
                        debugPrint('Gagal menghapus favorit: $e');

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gagal memperbarui favorit. Silakan coba lagi.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.favorite,
                      color: brown,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}