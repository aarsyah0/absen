import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';
import 'login_screen.dart'; // pastikan ada LoginScreen
import 'riwayat_screen.dart';

// Sesuaikan baseUrl sesuai environment:
// - Android emulator: 'http://10.0.2.2:8000'
// - iOS simulator: 'http://localhost:8000'
// - Perangkat nyata: 'http://<IP_PC>:8000'
// Untuk Web, gunakan host yang bisa diakses browser.
const String baseUrl = 'http://localhost:8000';

class ProfileScreen extends StatefulWidget {
  final String token;
  const ProfileScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> futureProfile;

  @override
  void initState() {
    super.initState();
    futureProfile = fetchProfile();
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final url = Uri.parse('$baseUrl/api/employee/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data'] as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  void _refresh() {
    setState(() {
      futureProfile = fetchProfile();
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Upload Foto Profil'),
                content: const Text('Yakin ingin mengganti foto profil?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok) return;

    final uri = Uri.parse('$baseUrl/api/employee/profile/photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${widget.token}';

    try {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final filename = picked.name;
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_photo',
            bytes,
            filename: filename,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', picked.path),
        );
      }
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diupload')),
        );
        _refresh();
      } else {
        String msg = 'Gagal upload foto';
        try {
          final b = jsonDecode(resp.body);
          msg = b['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saat upload: $e')));
    }
  }

  Future<void> _deletePhoto() async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Hapus Foto Profil'),
                content: const Text('Yakin ingin menghapus foto profil?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya'),
                  ),
                ],
              ),
        ) ??
        false;
    if (!ok) return;

    final uri = Uri.parse('$baseUrl/api/employee/profile/photo');
    try {
      final resp = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil dihapus')),
        );
        _refresh();
      } else {
        String msg = 'Gagal menghapus foto';
        try {
          final b = jsonDecode(resp.body);
          msg = b['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saat delete foto: $e')));
    }
  }

  Future<void> _logout() async {
    final uri = Uri.parse('$baseUrl/api/logout');
    try {
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token'); // key token sesuai simpanan Anda
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        String msg = 'Gagal logout';
        try {
          final b = jsonDecode(resp.body);
          msg = b['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saat logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: futureProfile,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FB),
            appBar: AppBar(
              title: const Text('Profil Saya'),
              backgroundColor: const Color(0xFF4F8DFD),
              elevation: 0,
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        // Error atau null
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FB),
            appBar: AppBar(
              title: const Text('Profil Saya'),
              backgroundColor: const Color(0xFF4F8DFD),
              elevation: 0,
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Gagal memuat data profil'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refresh,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F8DFD),
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        // Data tersedia
        final user = snapshot.data!;
        final profile = user['profile'] as Map<String, dynamic>? ?? {};
        final name = (user['name'] ?? '-').toString();
        final email = (user['email'] ?? '-').toString();
        final phone = (profile['phone_number'] ?? '-').toString();
        final nip = (profile['nip'] ?? '-').toString();
        final position = (profile['position'] ?? '-').toString();
        final photoPath = profile['profile_photo'];
        final photoUrl =
            photoPath != null ? '$baseUrl/storage/$photoPath' : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          appBar: AppBar(
            title: const Text('Profil Saya'),
            backgroundColor: const Color(0xFF4F8DFD),
            elevation: 0,
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Header: foto + nama
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F8DFD),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _pickAndUploadPhoto,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(
                                    photoUrl != null
                                        ? 'Ubah Foto'
                                        : 'Tambah Foto',
                                  ),
                                ),
                                if (photoUrl != null)
                                  TextButton(
                                    onPressed: _deletePhoto,
                                    child: const Text(
                                      'Hapus Foto',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 36,
                                backgroundImage:
                                    photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : const AssetImage('assets/logom.png')
                                            as ImageProvider,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Informasi Pribadi dengan tombol edit
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
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
                              'Informasi Pribadi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF4F8DFD),
                              ),
                              onPressed: () {
                                Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => EditProfileScreen(
                                          token: widget.token,
                                          initialName: name,
                                          initialEmail: email,
                                          initialPhone: phone,
                                          initialNip: nip,
                                          initialPosition: position,
                                        ),
                                  ),
                                ).then((updated) {
                                  if (updated == true) _refresh();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ProfileInfoRow(label: 'Nama', value: name),
                        _ProfileInfoRow(label: 'Email', value: email),
                        _ProfileInfoRow(label: 'No. Telepon', value: phone),
                        _ProfileInfoRow(label: 'NIP', value: nip),
                        _ProfileInfoRow(label: 'Jabatan', value: position),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _ProfileMenuItem(
                        icon: Icons.lock_outline,
                        label: 'Ubah Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ChangePasswordScreen(token: widget.token),
                            ),
                          );
                        },
                      ),
                      _ProfileMenuItem(
                        icon: Icons.logout,
                        label: 'Keluar',
                        color: Colors.red,
                        onTap: () async {
                          final confirmed =
                              await showDialog<bool>(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text(
                                        'Yakin ingin logout?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text('Ya'),
                                        ),
                                      ],
                                    ),
                              ) ??
                              false;
                          if (confirmed) {
                            await _logout();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: 3,
            selectedItemColor: const Color(0xFF4F8DFD),
            unselectedItemColor: Colors.black38,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fingerprint),
                label: 'Absensi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              if (index == 3) return;
              if (index == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DashboardScreen(
                          userName: name,
                          token: widget.token,
                        ),
                  ),
                  (route) => false,
                );
              }
              if (index == 2) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RiwayatScreen(token: widget.token),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        );
      },
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileInfoRow({required this.label, required this.value, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF4F8DFD)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }
}

// EditProfileScreen dengan name, email, phone_number, nip, position, dan optional foto
class EditProfileScreen extends StatefulWidget {
  final String token;
  final String initialName,
      initialEmail,
      initialPhone,
      initialNip,
      initialPosition;
  const EditProfileScreen({
    Key? key,
    required this.token,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialNip,
    required this.initialPosition,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController nipCtrl;
  late TextEditingController positionCtrl;
  XFile? selectedPhoto;
  bool loading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName);
    emailCtrl = TextEditingController(text: widget.initialEmail);
    phoneCtrl = TextEditingController(text: widget.initialPhone);
    nipCtrl = TextEditingController(text: widget.initialNip);
    positionCtrl = TextEditingController(text: widget.initialPosition);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedPhoto = picked;
      });
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    required String nip,
    required String position,
    XFile? newPhotoFile,
  }) async {
    final uri = Uri.parse('$baseUrl/api/employee/profile');
    if (newPhotoFile != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/employee/profile?_method=PUT'),
      );
      request.headers['Authorization'] = 'Bearer ${widget.token}';
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone_number'] = phoneNumber;
      request.fields['nip'] = nip;
      request.fields['position'] = position;
      if (kIsWeb) {
        final bytes = await newPhotoFile.readAsBytes();
        final filename = newPhotoFile.name;
        request.files.add(
          http.MultipartFile.fromBytes(
            'profile_photo',
            bytes,
            filename: filename,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', newPhotoFile.path),
        );
      }
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      return resp.statusCode == 200;
    } else {
      final resp = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'nip': nip,
          'position': position,
        }),
      );
      return resp.statusCode == 200;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      errorMsg = null;
    });
    try {
      final success = await updateProfile(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        nip: nipCtrl.text.trim(),
        position: positionCtrl.text.trim(),
        newPhotoFile: selectedPhoto,
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          errorMsg = 'Gagal memperbarui profil';
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: const Color(0xFF4F8DFD),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (errorMsg != null)
                Text(errorMsg!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      selectedPhoto != null
                          ? (kIsWeb
                              ? NetworkImage(selectedPhoto!.path)
                              : FileImage(File(selectedPhoto!.path))
                                  as ImageProvider)
                          : null,
                  child:
                      selectedPhoto == null
                          ? const Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Colors.white70,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!regex.hasMatch(v)) return 'Format email tidak valid';
                  return null;
                },
              ),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'No. Telepon'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: nipCtrl,
                decoration: const InputDecoration(labelText: 'NIP'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: positionCtrl,
                decoration: const InputDecoration(labelText: 'Jabatan'),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8DFD),
                ),
                child:
                    loading
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final String token;
  const ChangePasswordScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  String? errorMsg;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      loading = true;
      errorMsg = null;
    });
    final uri = Uri.parse('$baseUrl/api/employee/password');
    try {
      final resp = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentCtrl.text,
          'new_password': newCtrl.text,
          'new_password_confirmation': confirmCtrl.text,
        }),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah')),
        );
        Navigator.pop(context);
      } else {
        String msg = 'Gagal mengubah password';
        try {
          final b = jsonDecode(resp.body);
          msg = b['message'] ?? msg;
        } catch (_) {}
        setState(() {
          errorMsg = msg;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = 'Error: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Password'),
        backgroundColor: const Color(0xFF4F8DFD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (errorMsg != null)
                Text(errorMsg!, style: const TextStyle(color: Colors.red)),
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Saat Ini',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (v.length < 8) return 'Minimal 8 karakter';
                  return null;
                },
              ),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (v != newCtrl.text) return 'Tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F8DFD),
                ),
                child:
                    loading
                        ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text('Ubah Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
