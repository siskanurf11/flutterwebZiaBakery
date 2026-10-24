
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPesananPage extends StatefulWidget {
  const RiwayatPesananPage({super.key});

  @override
  State<RiwayatPesananPage> createState() => _RiwayatPesananPageState();
}

class _RiwayatPesananPageState extends State<RiwayatPesananPage> {
  static const Color cokelat = Color(0xFF8B5E3C);
  static const Color cokelatGelap = Color(0xFF5D321D);
  static const Color krem = Color(0xFFFFF8F0);

  List<Map<String, dynamic>> riwayatPesanan = [];
  bool isLoading = true;
  String filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  Future<void> _loadRiwayat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getStringList('riwayat_pesanan') ?? [];
      final hasil = <Map<String, dynamic>>[];

      for (final item in data) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            hasil.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        riwayatPesanan = hasil;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  int _angka(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  String _formatRupiah(dynamic value) {
    final teks = _angka(value).toString();
    final hasil = StringBuffer();

    for (int i = 0; i < teks.length; i++) {
      if (i > 0 && (teks.length - i) % 3 == 0) {
        hasil.write('.');
      }
      hasil.write(teks[i]);
    }

    return 'Rp${hasil.toString()}';
  }

  String _formatTanggal(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    final tanggal = DateTime.tryParse(value.toString());
    if (tanggal == null) return value.toString();

    final waktu = tanggal.toLocal();

    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year}';
  }

  bool _pesananSelesai(Map<String, dynamic> pesanan) {
    final status =
        (pesanan['status']?.toString() ?? '').toLowerCase().trim();

    return status == 'selesai';
  }

  bool _pesananDibatalkan(Map<String, dynamic> pesanan) {
    final status =
        (pesanan['status']?.toString() ?? '').toLowerCase().trim();

    return status.contains('batal') || status.contains('gagal');
  }

  Color _warnaStatus(String status) {
    final teks = status.toLowerCase();

    if (teks.contains('batal') || teks.contains('gagal')) {
      return Colors.red.shade700;
    }
    if (teks.contains('menunggu')) {
      return Colors.orange.shade800;
    }
    if (teks.contains('selesai')) {
      return Colors.green.shade700;
    }

    return cokelatGelap;
  }

  Color _latarStatus(String status) {
    final teks = status.toLowerCase();

    if (teks.contains('batal') || teks.contains('gagal')) {
      return Colors.red.shade50;
    }
    if (teks.contains('menunggu')) {
      return Colors.orange.shade50;
    }
    if (teks.contains('selesai')) {
      return Colors.green.shade50;
    }

    return const Color(0xFFF1E5DC);
  }

  List<Map<String, dynamic>> _ambilItems(
    Map<String, dynamic> pesanan,
  ) {
    final data = pesanan['items'];
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> get _pesananTersaring {
    if (filterStatus == 'Semua') return riwayatPesanan;

    return riwayatPesanan.where((pesanan) {
      final status =
          (pesanan['status']?.toString() ?? '').toLowerCase();

      if (filterStatus == 'Menunggu') {
        return status.contains('menunggu');
      }
      if (filterStatus == 'Selesai') {
        return status.trim() == 'selesai';
      }
      if (filterStatus == 'Dibatalkan') {
        return status.contains('batal') || status.contains('gagal');
      }

      return true;
    }).toList();
  }

  Future<void> _simpanSemuaRiwayat() async {
    final prefs = await SharedPreferences.getInstance();

    final data = riwayatPesanan
        .map((pesanan) => jsonEncode(pesanan))
        .toList();

    final berhasil = await prefs.setStringList(
      'riwayat_pesanan',
      data,
    );

    if (!berhasil) {
      throw Exception('Data riwayat gagal disimpan.');
    }
  }

  Future<void> _selesaikanPesanan(
    Map<String, dynamic> pesanan,
  ) async {
    if (_pesananSelesai(pesanan) || _pesananDibatalkan(pesanan)) {
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: krem,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Selesaikan Pesanan?',
            style: TextStyle(
              color: cokelatGelap,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Pastikan pesanan sudah diterima dan pembayaran telah '
            'diselesaikan. Status pesanan akan berubah menjadi Selesai '
            'dan kamu bisa memberikan rating serta ulasan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: cokelatGelap),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: cokelatGelap,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Selesaikan'),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true || !mounted) return;

    final statusSebelumnya = pesanan['status'];

    try {
      setState(() {
        pesanan['status'] = 'Selesai';
      });

      await _simpanSemuaRiwayat();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pesanan selesai! Sekarang kamu bisa memberi rating dan ulasan.',
          ),
          backgroundColor: cokelatGelap,
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        pesanan['status'] = statusSebelumnya;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status gagal disimpan. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bukaFormUlasan(
    Map<String, dynamic> pesanan,
    int indexItem, {
    VoidCallback? onUpdated,
  }) async {
    if (!_pesananSelesai(pesanan)) return;

    final items = pesanan['items'];

    if (items is! List ||
        indexItem < 0 ||
        indexItem >= items.length ||
        items[indexItem] is! Map) {
      return;
    }

    final item = Map<String, dynamic>.from(items[indexItem] as Map);
    final namaProduk = item['nama']?.toString() ?? 'Produk kue';

    int rating = _angka(item['rating']);

    final controller = TextEditingController(
      text: item['ulasan']?.toString() ?? '',
    );

    String? error;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: krem,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: const Text(
                  'Rating & Ulasan',
                  style: TextStyle(
                    color: cokelatGelap,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaProduk,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cokelatGelap,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Bagaimana produk ini?',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final bintang = index + 1;

                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                rating = bintang;
                                error = null;
                              });
                            },
                            icon: Icon(
                              bintang <= rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xFFE5A323),
                              size: 35,
                            ),
                          );
                        }),
                      ),
                      Center(
                        child: Text(
                          rating == 0
                              ? 'Pilih rating'
                              : '$rating dari 5 bintang',
                          style: const TextStyle(
                            color: cokelat,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Ulasan produk',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cokelatGelap,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        maxLength: 300,
                        decoration: InputDecoration(
                          hintText:
                              'Ceritakan rasa, kualitas, atau kemasan kue...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5D4C5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE5D4C5),
                            ),
                          ),
                        ),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: cokelatGelap),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cokelatGelap,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (rating == 0) {
                        setDialogState(() {
                          error =
                              'Silakan pilih rating bintang terlebih dahulu.';
                        });
                        return;
                      }

                      if (controller.text.trim().isEmpty) {
                        setDialogState(() {
                          error =
                              'Silakan tulis ulasan produk terlebih dahulu.';
                        });
                        return;
                      }

                      final daftarItems = pesanan['items'];

                      if (daftarItems is! List ||
                          indexItem >= daftarItems.length ||
                          daftarItems[indexItem] is! Map) {
                        setDialogState(() {
                          error =
                              'Data produk tidak ditemukan. Silakan coba lagi.';
                        });
                        return;
                      }

                      // Buat salinan agar data lama bisa dipulihkan
                      // jika penyimpanan gagal.
                      final itemLama = Map<String, dynamic>.from(
                        daftarItems[indexItem] as Map,
                      );

                      final itemBaru = Map<String, dynamic>.from(
                        itemLama,
                      );

                      itemBaru['rating'] = rating;
                      itemBaru['ulasan'] = controller.text.trim();
                      itemBaru['tanggalUlasan'] =
                          DateTime.now().toIso8601String();

                      try {
                        // Perbarui data item yang sesuai.
                        daftarItems[indexItem] = itemBaru;

                        // Simpan seluruh riwayat tanpa menghapus
                        // pesanan atau item lainnya.
                        await _simpanSemuaRiwayat();

                        if (!mounted || !dialogContext.mounted) return;

                        // Perbarui halaman riwayat.
                        setState(() {});

                        // Tutup dialog rating.
                        Navigator.pop(dialogContext);

                        // Perbarui isi Detail Pesanan yang masih terbuka.
                        onUpdated?.call();

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Rating dan ulasan berhasil disimpan.',
                            ),
                            backgroundColor: cokelatGelap,
                          ),
                        );
                      } catch (_) {
                        // Kembalikan item ke kondisi sebelumnya
                        // jika penyimpanan gagal.
                        daftarItems[indexItem] = itemLama;

                        if (!dialogContext.mounted) return;

                        setDialogState(() {
                          error =
                              'Ulasan gagal disimpan. Silakan coba lagi.';
                        });
                      }
                    },
                    child: const Text('Simpan Ulasan'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  void _bukaDetail(Map<String, dynamic> pesanan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: krem,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _buildDetailSheet(
              pesanan,
              setSheetState: setSheetState,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: krem,
      appBar: AppBar(
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cokelatGelap,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRiwayat,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: cokelat),
            )
          : riwayatPesanan.isEmpty
              ? _buildKosong()
              : RefreshIndicator(
                  color: cokelat,
                  onRefresh: _loadRiwayat,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      const Text(
                        'Pesanan Saya',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: cokelatGelap,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${riwayatPesanan.length} pesanan tersimpan',
                        style: TextStyle(
                          color: Colors.brown.shade400,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _filterChip('Semua'),
                            _filterChip('Menunggu'),
                            _filterChip('Selesai'),
                            _filterChip('Dibatalkan'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_pesananTersaring.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Tidak ada pesanan dengan status ini.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ..._pesananTersaring.map(_buildKartuPesanan),
                    ],
                  ),
                ),
    );
  }

  Widget _filterChip(String label) {
    final aktif = filterStatus == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: aktif,
        onSelected: (_) {
          setState(() => filterStatus = label);
        },
        selectedColor: cokelatGelap,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: aktif ? Colors.white : cokelatGelap,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(
          color: aktif ? cokelatGelap : const Color(0xFFE5D4C5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildKartuPesanan(Map<String, dynamic> pesanan) {
    final status = pesanan['status']?.toString() ?? 'Pesanan dibuat';
    final id = pesanan['id']?.toString() ?? '-';
    final tanggal = _formatTanggal(pesanan['tanggal']);
    final jumlah = _angka(pesanan['jumlah']);
    final total = _angka(pesanan['total']);
    final items = _ambilItems(pesanan);

    final namaProduk = items.isEmpty
        ? 'Detail produk tidak tersedia'
        : items.first['nama']?.toString() ?? 'Produk kue';

    final gambar =
        items.isNotEmpty ? items.first['gambar']?.toString() ?? '' : '';

    final produkLain = items.length - 1;
    final selesai = _pesananSelesai(pesanan);
    final dibatalkan = _pesananDibatalkan(pesanan);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE0D5)),
        boxShadow: [
          BoxShadow(
            color: cokelatGelap.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: cokelat,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pesanan #$id',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: cokelatGelap,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _latarStatus(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _warnaStatus(status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.only(left: 27),
              child: Text(
                tanggal,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF0E7DF)),
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    width: 66,
                    height: 66,
                    color: krem,
                    child: gambar.isEmpty
                        ? const Icon(Icons.cake_outlined, color: cokelat)
                        : Image.asset(
                            gambar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.cake_outlined, color: cokelat),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaProduk,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: cokelatGelap,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        produkLain > 0
                            ? '+ $produkLain jenis produk lainnya'
                            : '$jumlah item',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Divider(height: 1, color: Color(0xFFF0E7DF)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total pembayaran',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(total),
                        style: const TextStyle(
                          color: cokelatGelap,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _bukaDetail(pesanan),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cokelatGelap,
                    side: const BorderSide(color: cokelat),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lihat Detail',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!selesai && !dibatalkan) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _selesaikanPesanan(pesanan),
                  icon: const Icon(Icons.check_circle_outline, size: 19),
                  label: const Text('Selesaikan Pesanan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cokelat,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
            if (selesai) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _bukaDetail(pesanan),
                  icon: const Icon(Icons.star_outline_rounded, size: 19),
                  label: const Text('Beri Rating & Ulasan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cokelatGelap,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSheet(
    Map<String, dynamic> pesanan, {
    required StateSetter setSheetState,
  }) {
    // Data dibaca ulang setiap Detail Pesanan dibangun kembali.
    final items = _ambilItems(pesanan);
    final id = pesanan['id']?.toString() ?? '-';
    final status = pesanan['status']?.toString() ?? 'Pesanan dibuat';
    final selesai = _pesananSelesai(pesanan);
    final dibatalkan = _pesananDibatalkan(pesanan);

    final metodePengambilan =
        pesanan['metodePengambilan']?.toString() ?? '';
    final metodePembayaran =
        pesanan['metodePembayaran']?.toString() ?? '-';
    final alamat = pesanan['alamat']?.toString() ?? '';
    final catatan = pesanan['catatan']?.toString() ?? '';
    final tanggalAmbil =
        pesanan['tanggalPengambilan']?.toString() ?? '';
    final waktuAmbil =
        pesanan['waktuPengambilan']?.toString() ?? '';
    final kodeVoucher = pesanan['kodeVoucher']?.toString() ?? '';

    final subtotalTersimpan = pesanan['subtotal'];
    final subtotal = subtotalTersimpan != null
        ? _angka(subtotalTersimpan)
        : items.fold<int>(
            0,
            (sum, item) => sum + _angka(item['subtotal']),
          );

    final diskonVoucher = _angka(pesanan['diskonVoucher']);
    final total = _angka(pesanan['total']);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cokelat.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: cokelatGelap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detail Pesanan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cokelatGelap,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _bagianDetail(
                    judul: 'Informasi Pesanan',
                    ikon: Icons.receipt_outlined,
                    isi: [
                      _barisDetail('Nomor Pesanan', id),
                      _barisDetail(
                        'Tanggal Pesanan',
                        _formatTanggal(pesanan['tanggal']),
                      ),
                      _barisDetail('Metode Pembayaran', metodePembayaran),
                      _barisDetail(
                        'Jumlah Produk',
                        '${_angka(pesanan['jumlah'])} item',
                      ),
                      _barisDetail(
                        'Status Pesanan',
                        status,
                        valueColor: _warnaStatus(status),
                        bold: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!selesai && !dibatalkan)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _selesaikanPesanan(pesanan);
                          if (mounted) {
                            setSheetState(() {});
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Selesaikan Pesanan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cokelat,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  _bagianDetail(
                    judul: 'Daftar Produk',
                    ikon: Icons.shopping_bag_outlined,
                    isi: [
                      if (items.isEmpty)
                        const Text('Detail produk tidak tersedia.')
                      else
                        ...List.generate(items.length, (index) {
                          final item = items[index];
                          final nama = item['nama']?.toString() ?? 'Kue';
                          final gambar = item['gambar']?.toString() ?? '';
                          final qty = _angka(item['jumlah']);
                          final harga = _angka(item['harga']);
                          final hargaAsli = _angka(item['hargaAsli']);
                          final itemSubtotal = item['subtotal'] != null
                              ? _angka(item['subtotal'])
                              : harga * qty;
                          final rating = _angka(item['rating']);
                          final ulasan = item['ulasan']?.toString() ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 66,
                                        height: 66,
                                        color: krem,
                                        child: gambar.isEmpty
                                            ? const Icon(
                                                Icons.cake_outlined,
                                                color: cokelat,
                                              )
                                            : Image.asset(
                                                gambar,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                  Icons.cake_outlined,
                                                  color: cokelat,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: cokelatGelap,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$qty item × ${_formatRupiah(harga)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (hargaAsli > harga &&
                                              hargaAsli > 0) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Harga awal ${_formatRupiah(hargaAsli)}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 5),
                                          Text(
                                            _formatRupiah(itemSubtotal),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: cokelatGelap,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (selesai) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await _bukaFormUlasan(
                                          pesanan,
                                          index,
                                          onUpdated: () {
                                            setSheetState(() {});
                                          },
                                        );
                                      },
                                      icon: Icon(
                                        rating > 0
                                            ? Icons.star_rounded
                                            : Icons.rate_review_outlined,
                                        color: const Color(0xFFE5A323),
                                      ),
                                      label: Text(
                                        rating > 0
                                            ? 'Ulasan: $rating/5 bintang · Edit Ulasan'
                                            : 'Beri Rating & Ulasan',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cokelatGelap,
                                        side: const BorderSide(color: cokelat),
                                        alignment: Alignment.centerLeft,
                                      ),
                                    ),
                                  ),
                                  if (rating > 0 && ulasan.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(top: 5),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: krem,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '“$ulasan”',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: cokelatGelap,
                                        ),
                                      ),
                                    ),
                                ],
                                const Divider(height: 22),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bagianDetail(
                    judul: 'Penerimaan Pesanan',
                    ikon: Icons.local_shipping_outlined,
                    isi: [
                      _barisDetail(
                        'Cara Menerima',
                        metodePengambilan.isNotEmpty
                            ? metodePengambilan
                            : (alamat.isNotEmpty
                                ? 'Diantar ke Alamat'
                                : 'Tidak tersedia'),
                      ),
                      if (alamat.isNotEmpty) _barisDetail('Alamat', alamat),
                      if (tanggalAmbil.isNotEmpty)
                        _barisDetail(
                          'Tanggal Pengambilan',
                          _formatTanggal(tanggalAmbil),
                        ),
                      if (waktuAmbil.isNotEmpty)
                        _barisDetail('Waktu Pengambilan', waktuAmbil),
                      _barisDetail(
                        'Catatan Pesanan',
                        catatan.isEmpty ? 'Tidak ada catatan' : catatan,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bagianDetail(
                    judul: 'Ringkasan Pembayaran',
                    ikon: Icons.payments_outlined,
                    isi: [
                      _barisDetail('Subtotal', _formatRupiah(subtotal)),
                      if (kodeVoucher.isNotEmpty)
                        _barisDetail('Kode Voucher', kodeVoucher),
                      if (diskonVoucher > 0)
                        _barisDetail(
                          'Diskon Voucher',
                          '-${_formatRupiah(diskonVoucher)}',
                          valueColor: Colors.green.shade700,
                        ),
                      const Divider(height: 22),
                      _barisDetail(
                        'Total Pembayaran',
                        _formatRupiah(total),
                        bold: true,
                        valueColor: cokelatGelap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bagianDetail({
    required String judul,
    required IconData ikon,
    required List<Widget> isi,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE0D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, color: cokelat, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cokelatGelap,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...isi,
        ],
      ),
    );
  }

  Widget _barisDetail(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 4,
            child: SizedBox(),
          ),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 78,
              color: cokelat.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Riwayat Pesanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cokelatGelap,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesanan yang tersimpan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadRiwayat,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: cokelatGelap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}