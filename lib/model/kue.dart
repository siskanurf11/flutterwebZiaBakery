class Kue {
  String _image;
  String _name;
  String _description;
  int _price;
  int _stock;
  String _category;
  int _diskon;

  Kue({
    required String image,
    required String name,
    required String description,
    required int price,
    required int stock,
    required String category,
    int diskon = 0,
  })
    : _image = image,
        _name = name,
        _description = description,
        _price = price,
        _stock = stock,
        _category = category,
        _diskon = diskon.clamp(0, 100);

  // Getter
  String get image => _image;
  String get name => _name;
  String get description => _description;
  int get price => _price;
  int get stock => _stock;
  String get category => _category;
  int get diskon => _diskon;

  // Setter
  set image(String value) => _image = value;
  set name(String value) => _name = value;
  set description(String value) => _description = value;
  set price(int value) => _price = value < 0 ? 0 : value;
  set stock(int value) => _stock = value < 0 ? 0 : value;
  set category(String value) => _category = value;

  set diskon(int value) {
    _diskon = value.clamp(0, 100);
  }

  // Mengecek apakah produk mendapatkan diskon
  bool get isOnSale => _diskon > 0;

  // Menghitung nominal potongan harga
  int get nominalDiskon => (_price * _diskon / 100).round();

  // Menghitung harga setelah diskon
  int get hargaSetelahDiskon => _price - nominalDiskon;

  // Format harga asli
  String getFormattedPrice() {
    return 'Rp${_price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  // Format harga setelah diskon
  String getFormattedHargaDiskon() {
    return 'Rp${hargaSetelahDiskon.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    )}';
  }

  // Informasi stok
  String getStockInfo() {
    if (_stock <= 0) {
      return 'Stok habis';
    } else if (_stock <= 5) {
      return 'Stok tersisa $_stock';
    } else {
      return 'Stok tersedia';
    }
  }

  // Mengecek ketersediaan produk
  bool isAvailable() {
    return _stock > 0;
  }
}
