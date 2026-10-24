
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/kue.dart';

class CheckoutPage extends StatefulWidget {
  final Map<Kue, int> cart;
  final VoidCallback onOrderSuccess;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.onOrderSuccess,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController voucherController = TextEditingController();

  static const Color darkBrown = Color(0xFF5D321D);
  static const Color brown = Color(0xFF8B5E3C);
  static const Color lightBrown = Color(0xFFE8D5C4);
  static const Color backgroundBrown = Color(0xFFFFF8F1);

  String metodePengambilan = 'Ambil di Toko';
  String paymentMethod = 'Bayar di Toko';

  DateTime? selectedPickupDate;
  String? selectedPickupTime;

  bool isSaving = false;
  bool voucherApplied = false;
  String voucherMessage = '';
  bool voucherSuccess = false;

  final List<String> pickupTimes = [
    '09.00 - 10.00',
    '10.00 - 11.00',
    '11.00 - 12.00',
    '12.00 - 13.00',
    '13.00 - 14.00',
    '14.00 - 15.00',
    '15.00 - 16.00',
    '16.00 - 17.00',
  ];

  bool get isPickup => metodePengambilan == 'Ambil di Toko';

  @override
  void dispose() {
    addressController.dispose();
    noteController.dispose();
    voucherController.dispose();
    super.dispose();
  }

  int getSubtotal() {
    int total = 0;

    for (final entry in widget.cart.entries) {
      total += entry.key.hargaSetelahDiskon * entry.value;
    }

    return total;
  }

  int getVoucherDiscount() {
    if (!voucherApplied) return 0;

    int eligibleSubtotal = 0;

    for (final entry in widget.cart.entries) {
      final Kue cake = entry.key;

      // Voucher tidak ditumpuk dengan diskon produk.
      if (!cake.isOnSale) {
        eligibleSubtotal += cake.hargaSetelahDiskon * entry.value;
      }
    }

    return (eligibleSubtotal * 0.10).round();
  }

  int getTotal() {
    return getSubtotal() - getVoucherDiscount();
  }

  int getTotalItems() {
    int total = 0;

    for (final quantity in widget.cart.values) {
      total += quantity;
    }

    return total;
  }

  String formatRupiah(int value) {
    final String number = value.toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      result.write(number[i]);

      final int remaining = number.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp$result';
  }

  String formatTanggal(DateTime date) {
    const List<String> namaBulan = [
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

    return '${date.day} ${namaBulan[date.month - 1]} ${date.year}';
  }

  void terapkanVoucher() {
    final String kode = voucherController.text.trim().toUpperCase();

    setState(() {
      if (kode.isEmpty) {
        voucherApplied = false;
        voucherSuccess = false;
        voucherMessage = 'Masukkan kode voucher terlebih dahulu.';
      } else if (kode == 'ZIABAKERY10') {
        final bool adaProdukEligible = widget.cart.entries.any(
          (entry) => !entry.key.isOnSale,
        );

        if (!adaProdukEligible) {
          voucherApplied = false;
          voucherSuccess = false;
          voucherMessage =
              'Voucher tidak berlaku karena semua produk sudah diskon.';
        } else {
          voucherApplied = true;
          voucherSuccess = true;
          voucherMessage = 'Voucher berhasil digunakan! Diskon 10% berlaku.';
        }
      } else {
        voucherApplied = false;
        voucherSuccess = false;
        voucherMessage = 'Kode voucher tidak valid.';
      }
    });
  }

  void ubahMetodePengambilan(String value) {
    setState(() {
      metodePengambilan = value;

      if (value == 'Ambil di Toko') {
        paymentMethod = 'Bayar di Toko';
      } else {
        paymentMethod = 'COD';
      }
    });
  }

  Future<void> pilihTanggalPengambilan() async {
    final DateTime sekarang = DateTime.now();
    final DateTime hariIni =
        DateTime(sekarang.year, sekarang.month, sekarang.day);

    final DateTime? tanggal = await showDatePicker(
      context: context,
      initialDate: selectedPickupDate ?? hariIni,
      firstDate: hariIni,
      lastDate: DateTime(sekarang.year + 1, 12, 31),
      helpText: 'Pilih tanggal pengambilan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: brown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );

    if (tanggal != null && mounted) {
      setState(() {
        selectedPickupDate = tanggal;
      });
    }
  }

  Future<void> saveOrderToHistory({
    required String status,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> history =
        prefs.getStringList('riwayat_pesanan') ?? [];

    final List<Map<String, dynamic>> items =
        widget.cart.entries.map((entry) {
      final Kue cake = entry.key;
      final int quantity = entry.value;

      return <String, dynamic>{
        'nama': cake.name,
        'jumlah': quantity,
        'hargaAsli': cake.price,
        'harga': cake.hargaSetelahDiskon,
        'diskonProduk': cake.diskon,
        'subtotal': cake.hargaSetelahDiskon * quantity,
        'gambar': cake.image,
      };
    }).toList();

    final Map<String, dynamic> order = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tanggal': DateTime.now().toIso8601String(),
      'metodePengambilan': metodePengambilan,
      'metodePembayaran': paymentMethod,
      'alamat': isPickup ? '' : addressController.text.trim(),
      'catatan': noteController.text.trim(),
      'status': status,
      'jumlah': getTotalItems(),
      'subtotal': getSubtotal(),
      'kodeVoucher': voucherApplied ? 'ZIABAKERY10' : '',
      'diskonVoucher': getVoucherDiscount(),
      'total': getTotal(),
      'items': items,
      'tanggalPengambilan':
          isPickup ? selectedPickupDate!.toIso8601String() : '',
      'waktuPengambilan': isPickup ? selectedPickupTime! : '',
    };

    history.insert(0, jsonEncode(order));

    final bool saved =
        await prefs.setStringList('riwayat_pesanan', history);

    if (!saved) {
      throw Exception('Pesanan gagal disimpan.');
    }
  }

  Future<void> orderNow() async {
    if (isSaving) return;

    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong.')),
      );
      return;
    }

    if (!isPickup && addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman wajib diisi.')),
      );
      return;
    }

    if (isPickup && selectedPickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal pengambilan.'),
        ),
      );
      return;
    }

    if (isPickup && selectedPickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih waktu pengambilan.'),
        ),
      );
      return;
    }

    String status;

    if (paymentMethod == 'COD') {
      status = 'Menunggu pembayaran saat pesanan diterima';
    } else if (paymentMethod == 'QRIS') {
      status = 'Menunggu verifikasi pembayaran QRIS';
    } else {
      status = 'Menunggu pembayaran saat diambil di toko';
    }

    setState(() {
      isSaving = true;
    });

    try {
      await saveOrderToHistory(status: status);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Pesanan Berhasil',
              style: TextStyle(
                color: darkBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesanan kamu berhasil dibuat.'),
                  const SizedBox(height: 12),
                  Text('Subtotal: ${formatRupiah(getSubtotal())}'),
                  if (voucherApplied)
                    Text(
                      'Diskon voucher: -${formatRupiah(getVoucherDiscount())}',
                    ),
                  Text(
                    'Total pembayaran: ${formatRupiah(getTotal())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: brown,
                    ),
                  ),
                  Text('Jumlah produk: ${getTotalItems()}'),
                  Text('Cara menerima: $metodePengambilan'),
                  Text('Pembayaran: $paymentMethod'),
                  if (voucherApplied)
                    const Text('Voucher: ZIABAKERY10'),
                  if (isPickup) ...[
                    Text(
                      'Tanggal: ${formatTanggal(selectedPickupDate!)}',
                    ),
                    Text('Waktu: $selectedPickupTime'),
                  ] else ...[
                    Text('Alamat: ${addressController.text.trim()}'),
                  ],
                  if (noteController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Catatan: ${noteController.text.trim()}'),
                  ],
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      widget.onOrderSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pesanan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkBrown,
        ),
      ),
    );
  }

  Widget buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: widget.cart.entries.map((entry) {
          final Kue cake = entry.key;
          final int quantity = entry.value;
          final int harga = cake.hargaSetelahDiskon;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    cake.image,
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 65,
                        height: 65,
                        color: lightBrown,
                        child: const Icon(Icons.cake, color: brown),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cake.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBrown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (cake.isOnSale) ...[
                        Text(
                          cake.getFormattedPrice(),
                          style: const TextStyle(
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '${formatRupiah(harga)} x $quantity',
                          style: const TextStyle(color: brown),
                        ),
                      ] else
                        Text(
                          '${formatRupiah(harga)} x $quantity',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(harga * quantity),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: brown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildMetodePengambilan() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'Ambil di Toko',
            groupValue: metodePengambilan,
            activeColor: brown,
            title: const Text(
              'Ambil di Toko',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            subtitle: const Text(
              'Datang langsung untuk mengambil pesanan',
            ),
            secondary: const Icon(Icons.storefront, color: brown),
            onChanged: (value) {
              if (value != null) ubahMetodePengambilan(value);
            },
          ),
          const Divider(height: 1),
          RadioListTile<String>(
            value: 'COD',
            groupValue: metodePengambilan,
            activeColor: brown,
            title: const Text(
              'Diantar ke Alamat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            subtitle: const Text(
              'Pesanan diantar dan dibayar saat diterima',
            ),
            secondary: const Icon(Icons.delivery_dining, color: brown),
            onChanged: (value) {
              if (value != null) ubahMetodePengambilan(value);
            },
          ),
        ],
      ),
    );
  }

  Widget buildInformasiPenerimaan() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPickup) ...[
            const Text(
              'Tanggal Pengambilan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: pilihTanggalPengambilan,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: backgroundBrown,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lightBrown),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: brown),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedPickupDate == null
                            ? 'Pilih tanggal pengambilan'
                            : formatTanggal(selectedPickupDate!),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: brown,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Waktu Pengambilan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedPickupTime,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Pilih waktu pengambilan',
                prefixIcon: const Icon(
                  Icons.access_time,
                  color: brown,
                ),
                filled: true,
                fillColor: backgroundBrown,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: pickupTimes.map((time) {
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPickupTime = value;
                });
              },
            ),
          ] else ...[
            const Text(
              'Alamat Pengiriman',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan alamat lengkap',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: brown,
                ),
                filled: true,
                fillColor: backgroundBrown,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Catatan Pesanan (Opsional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Contoh: tulisan pada kue atau permintaan khusus',
              alignLabelWithHint: true,
              filled: true,
              fillColor: backgroundBrown,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMetodePembayaran() {
    final List<String> paymentOptions =
        isPickup ? ['Bayar di Toko', 'QRIS'] : ['COD', 'QRIS'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: paymentOptions.map((method) {
          final bool isQris = method == 'QRIS';

          return RadioListTile<String>(
            value: method,
            groupValue: paymentMethod,
            activeColor: brown,
            title: Text(
              method,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            subtitle: Text(
              isQris
                  ? 'Pembayaran melalui QRIS'
                  : method == 'COD'
                      ? 'Bayar saat pesanan diterima'
                      : 'Bayar ketika mengambil pesanan di toko',
            ),
            secondary: Icon(
              isQris
                  ? Icons.qr_code_2
                  : method == 'COD'
                      ? Icons.delivery_dining
                      : Icons.payments_outlined,
              color: brown,
            ),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                paymentMethod = value;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Punya Kode Voucher?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan ZIABAKERY10 untuk diskon 10% pada produk tanpa diskon.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: voucherController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !voucherApplied,
                  decoration: InputDecoration(
                    hintText: 'Masukkan kode voucher',
                    filled: true,
                    fillColor: backgroundBrown,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: voucherApplied
                    ? () {
                        setState(() {
                          voucherApplied = false;
                          voucherSuccess = false;
                          voucherMessage = 'Voucher dibatalkan.';
                          voucherController.clear();
                        });
                      }
                    : terapkanVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                child: Text(voucherApplied ? 'Batal' : 'Gunakan'),
              ),
            ],
          ),
          if (voucherMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              voucherMessage,
              style: TextStyle(
                color: voucherSuccess ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jumlah produk'),
              Text('${getTotalItems()} item'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cara menerima'),
              Flexible(
                child: Text(
                  isPickup ? 'Ambil di Toko' : 'Diantar ke Alamat',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pembayaran'),
              Text(paymentMethod),
            ],
          ),
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(formatRupiah(getSubtotal())),
            ],
          ),
          if (voucherApplied) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Diskon Voucher (10%)',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
                Text(
                  '-${formatRupiah(getVoucherDiscount())}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
              Text(
                formatRupiah(getTotal()),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBrown,
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkBrown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: widget.cart.isEmpty
          ? const Center(child: Text('Keranjang masih kosong.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Pesanan Kamu'),
                  buildOrderItems(),
                  const SizedBox(height: 22),
                  buildSectionTitle('Cara Menerima Pesanan'),
                  buildMetodePengambilan(),
                  const SizedBox(height: 22),
                  buildSectionTitle(
                    isPickup
                        ? 'Jadwal Pengambilan'
                        : 'Informasi Pengiriman',
                  ),
                  buildInformasiPenerimaan(),
                  const SizedBox(height: 22),
                  buildSectionTitle('Metode Pembayaran'),
                  buildMetodePembayaran(),
                  const SizedBox(height: 22),
                  buildSectionTitle('Voucher Diskon'),
                  buildVoucherSection(),
                  const SizedBox(height: 22),
                  buildSectionTitle('Ringkasan Pembayaran'),
                  buildPaymentSummary(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : orderNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Buat Pesanan',
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
    );
  }
}