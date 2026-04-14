import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alurautentikasi.dart';
import 'edit_profil.dart';
import 'dart:io';
import 'riwayat_pesanan.dart';
import 'main.dart'; // Impor appThemeNotifier
import 'notifikasi.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String phone = '';
  String? imagePath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('profile_name') ?? 'Pengguna';
      email = prefs.getString('profile_email') ?? '';
      phone = prefs.getString('profile_phone') ?? 'Belum ada nomor';
      imagePath = prefs.getString('profile_imagePath');
      isLoading = false;
    });
  }

  Future<void> _saveProfileData(String newName, String newEmail, String newPhone, String? newImagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', newName);
    await prefs.setString('profile_email', newEmail);
    await prefs.setString('profile_phone', newPhone);
    if (newImagePath != null && newImagePath.isNotEmpty) {
      await prefs.setString('profile_imagePath', newImagePath);
    } else {
      await prefs.remove('profile_imagePath');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[500],
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, {String? trailingText, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur belum tersedia')));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[700], size: 22),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const Spacer(),
            if (trailingText != null)
              Text(trailingText, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12)),
            if (trailingText != null) const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: isDark ? Colors.grey[600] : Colors.grey[400], size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: items.map((e) {
          int index = items.indexOf(e);
          return Column(
            children: [
              e,
              if (index != items.length - 1)
                Divider(height: 1, color: Theme.of(context).dividerColor, indent: 54, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).appBarTheme.foregroundColor)),
        centerTitle: true,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200], 
                      shape: BoxShape.circle,
                      image: (imagePath != null && imagePath!.isNotEmpty)
                          ? DecorationImage(
                              image: FileImage(File(imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                        const SizedBox(height: 4),
                        Text(phone, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildSectionHeader('Akun'),
            _buildMenuSection([
              _buildListTile('Kelola Profil', Icons.person_outline, onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      currentName: name,
                      currentEmail: email,
                      currentPhone: phone,
                      currentImagePath: imagePath,
                    ),
                  ),
                );
                
                if (result != null && result is Map<String, String>) {
                  final newName = result['name'] ?? name;
                  final newPhone = result['phone'] ?? phone;
                  final newImagePath = result['imagePath'];

                  setState(() {
                    name = newName;
                    phone = newPhone;
                    imagePath = newImagePath?.isEmpty == true ? null : newImagePath;
                  });
                  _saveProfileData(newName, email, newPhone, imagePath);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!')));
                }
              }),
              _buildListTile('Notifikasi', Icons.notifications_none, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
              }),
              _buildListTile('Riwayat Pesanan', Icons.history, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RiwayatPesananScreen()));
              }),
            ]),
            
            _buildSectionHeader('Preferensi'),
            _buildMenuSection([
              _buildListTile('Tentang Kami', Icons.info_outline),
            ]),

            _buildSectionHeader('Dukungan'),
            _buildMenuSection([
              _buildListTile('Pusat Bantuan', Icons.help_outline),
            ]),
            
            const SizedBox(height: 32),
            
            // Logout
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF330000) : Colors.red[50],
                  foregroundColor: isDark ? Colors.red[300] : Colors.red[600],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  // Berikan efek loading kecil/delay (Opsional)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sedang mengeluarkan akun...')),
                  );
                  
                  final prefs = await SharedPreferences.getInstance();
                  // Hapus seluruh data sesi secara aman
                  await prefs.clear();
                  
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}