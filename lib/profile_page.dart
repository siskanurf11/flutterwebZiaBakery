import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color brown = Color(0xFF8B5E3C);
  static const Color darkBrown = Color(0xFF5D321D);
  static const Color lightBrown = Color(0xFFE8D5C4);
  static const Color cream = Color(0xFFFFF8F1);

  // DATA PROFILE
  String nama = 'Siska';
  String birthday = 'Tanggal lahir';
  String phone = '0812 3456 7890';
  String instagram = '@ziabakery';
  String email = 'siska@gmail.com';

  final TextEditingController namaController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    namaController.dispose();
    birthdayController.dispose();
    phoneController.dispose();
    instagramController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: darkBrown,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showEditProfile,
            tooltip: 'Edit Profile',
            icon: const Icon(
              Icons.edit_outlined,
              color: darkBrown,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 26),
                _buildAboutMe(),
                const SizedBox(height: 25),
                _buildSectionTitle('Informasi Pribadi'),
                const SizedBox(height: 10),
                _buildInformationList(),
                const SizedBox(height: 25),
                _buildSectionTitle('Pendidikan'),
                const SizedBox(height: 10),
                _buildEducation(),
                const SizedBox(height: 30),
                _buildEditButton(),
                const SizedBox(height: 12),
                _buildLogoutButton(),
                const SizedBox(height: 15),
                const Center(
                  child: Text(
                    'Zia Bakery',
                    style: TextStyle(
                      color: brown,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER PROFILE

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 105,
            height: 105,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: lightBrown,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: brown,
                    size: 60,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkBrown,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pembuat Website Zia Bakery',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: brown,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ABOUT ME

  Widget _buildAboutMe() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lightBrown),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: brown,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'About Me',
                style: TextStyle(
                  color: darkBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Saya merupakan mahasiswa S1 Teknik Informatika '
            'Universitas Negeri Surabaya yang tertarik pada teknologi '
            'dan pengembangan aplikasi. Website Zia Bakery dibuat '
            'sebagai proyek untuk menerapkan ilmu yang telah dipelajari.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // JUDUL BAGIAN

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkBrown,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // INFORMASI PRIBADI

  Widget _buildInformationList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lightBrown),
      ),
      child: Column(
        children: [
          _informationRow(
            icon: Icons.person_outline,
            title: 'Nama Lengkap',
            value: nama,
          ),
          _informationDivider(),
          _informationRow(
            icon: Icons.cake_outlined,
            title: 'Tanggal Lahir',
            value: birthday,
          ),
          _informationDivider(),
          _informationRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: email,
          ),
          _informationDivider(),
          _informationRow(
            icon: Icons.phone_android_outlined,
            title: 'Nomor HP',
            value: phone,
          ),
          _informationDivider(),
          _informationRow(
            icon: Icons.camera_alt_outlined,
            title: 'Instagram',
            value: instagram,
          ),
        ],
      ),
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: brown,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationDivider() {
    return Divider(
      height: 1,
      thickness: 0.7,
      color: lightBrown.withOpacity(0.7),
    );
  }

  // PENDIDIKAN

  Widget _buildEducation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: lightBrown),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.school_outlined,
            color: brown,
            size: 26,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'S1 Teknik Informatika',
                  style: TextStyle(
                    color: darkBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Universitas Negeri Surabaya',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TOMBOL EDIT PROFILE

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _showEditProfile,
        icon: const Icon(Icons.edit_outlined, size: 19),
        label: const Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: brown,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // TOMBOL LOGOUT

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout_outlined, size: 19),
        label: const Text('Log Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: brown,
          side: const BorderSide(color: brown),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // DIALOG EDIT PROFILE

  void _showEditProfile() {
    namaController.text = nama;
    birthdayController.text = birthday;
    phoneController.text = phone;
    instagramController.text = instagram;
    emailController.text = email;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(
                  controller: namaController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _editField(
                  controller: birthdayController,
                  label: 'Tanggal Lahir',
                  icon: Icons.cake_outlined,
                  hint: 'Contoh: 12 Januari 2005',
                ),
                const SizedBox(height: 12),
                _editField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _editField(
                  controller: phoneController,
                  label: 'Nomor HP',
                  icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _editField(
                  controller: instagramController,
                  label: 'Instagram',
                  icon: Icons.camera_alt_outlined,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  nama = namaController.text.trim();
                  birthday = birthdayController.text.trim();
                  phone = phoneController.text.trim();
                  instagram = instagramController.text.trim();
                  email = emailController.text.trim();
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil berhasil diperbarui.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: brown),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBrown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brown),
        ),
      ),
    );
  }

  // DIALOG LOGOUT

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              color: darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun?',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brown,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}