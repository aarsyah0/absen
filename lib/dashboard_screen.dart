import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'checkin_screen.dart';
import 'checkout_screen.dart';
import 'izin_screen.dart';
import 'riwayat_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userName;
  final String token;
  const DashboardScreen({Key? key, required this.userName, required this.token})
    : super(key: key);

  Future<Map<String, dynamic>> fetchTodayStatus(String token) async {
    final url = Uri.parse(
      'http://localhost:8000/api/employee/attendance/today-status',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] ?? {};
    } else {
      throw Exception('Gagal mengambil status absensi');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLastActivities(String token) async {
    final url = Uri.parse('http://localhost:8000/api/employee/attendance/history?length=3&start=0');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal mengambil aktivitas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    final timeStr = DateFormat('HH:mm').format(now);
    String greeting() {
      final hour = now.hour;
      if (hour >= 4 && hour < 10) return 'Selamat Pagi,';
      if (hour >= 10 && hour < 15) return 'Selamat Siang,';
      if (hour >= 15 && hour < 18) return 'Selamat Sore,';
      return 'Selamat Malam,';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F8DFD), Color(0xFF6FC8FB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (userName.isNotEmpty ? userName : 'Budi Santoso'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$dateStr • $timeStr WIB',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage('assets/logom.png'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tombol Aksi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckinScreen(token: token),
                          ),
                        );
                      },
                      child: _ActionButton(
                        icon: Icons.login,
                        label: 'Check-in',
                        color: const Color(0xFF4F8DFD),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(token: token),
                          ),
                        );
                      },
                      child: _ActionButton(
                        icon: Icons.logout,
                        label: 'Check-out',
                        color: const Color.fromARGB(255, 140, 150, 254),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IzinScreen(token: token),
                          ),
                        );
                      },
                      child: _ActionButton(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Izin',
                        color: const Color.fromARGB(255, 16, 171, 148),
                        iconColor: const Color.fromARGB(255, 16, 171, 148),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Jam Kerja Hari Ini
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: fetchTodayStatus(token),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Gagal memuat data absensi hari ini',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    final data = snapshot.data ?? {};
                    final clockIn = data['clock_in']?['time'] ?? null;
                    final clockOut = data['clock_out']?['time'] ?? null;
                    // Jam kerja tetap 08:30 - 17:30
                    final startTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      8,
                      30,
                    );
                    final endTime = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      17,
                      30,
                    );
                    DateTime? checkInTime;
                    DateTime? checkOutTime;
                    if (clockIn != null) {
                      checkInTime = DateFormat('HH:mm:ss').parse(clockIn);
                      checkInTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        checkInTime.hour,
                        checkInTime.minute,
                        checkInTime.second,
                      );
                    }
                    if (clockOut != null) {
                      checkOutTime = DateFormat('HH:mm:ss').parse(clockOut);
                      checkOutTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        checkOutTime.hour,
                        checkOutTime.minute,
                        checkOutTime.second,
                      );
                    }
                    // Progress
                    double progress = 0;
                    String progressText = '0j 0m / 8j';
                    if (checkInTime != null) {
                      final end = checkOutTime ?? now;
                      final dur = end.difference(checkInTime);
                      final jam = dur.inHours;
                      final menit = dur.inMinutes % 60;
                      progress = dur.inMinutes / 480.0;
                      if (progress > 1) progress = 1;
                      progressText = '${jam}j ${menit}m / 8j';
                    }
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jam Kerja Hari Ini',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Progress',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                progressText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE3EAF2),
                            color: const Color(0xFF4F8DFD),
                            minHeight: 6,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Check-in: ${checkInTime != null ? DateFormat('HH:mm').format(checkInTime) : '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Check-out: ${checkOutTime != null ? DateFormat('HH:mm').format(checkOutTime) : '-'}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Kehadiran Minggu Ini',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              _DayCircle('S', false),
                              _DayCircle('S', false),
                              _DayCircle('R', false),
                              _DayCircle('K', true),
                              _DayCircle('J', false),
                              _DayCircle('S', false),
                              _DayCircle('M', false),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Aktivitas Terakhir
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Terakhir',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RiwayatScreen(token: token),
                          ),
                        );
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(color: Color(0xFF4F8DFD), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchLastActivities(token),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Text('Gagal memuat aktivitas');
                    }
                    final activities = snapshot.data ?? [];
                    if (activities.isEmpty) {
                      return const Text('Belum ada aktivitas');
                    }
                    return Column(
                      children: activities.map((item) {
                        final type = item['type'];
                        final icon = type == 'in' ? Icons.login : Icons.logout;
                        final title = type == 'in' ? 'Check-in' : 'Check-out';
                        final date = item['date'] ?? '';
                        final time = item['time'] ?? '';
                        final status = item['status'] ?? '-';
                        final statusColor = status == 'accepted'
                            ? const Color(0xFF1BCFB4)
                            : (status == 'pending'
                                ? const Color(0xFFFFC542)
                                : const Color(0xFFE57373));
                        return _ActivityTile(
                          icon: icon,
                          title: title,
                          subtitle: '$date, $time WIB',
                          status: status[0].toUpperCase() + status.substring(1),
                          statusColor: statusColor,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Izin Mendatang
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Izin Mendatang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: const [
                    SizedBox(
                      width: 220,
                      child: _IzinCard(
                        title: 'Cuti Tahunan',
                        date: '15 - 17 Juni 2025',
                        status: 'Menunggu',
                        statusColor: Color(0xFFFFC542),
                        description: 'Liburan keluarga ke Bali',
                      ),
                    ),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: _IzinCard(
                        title: 'Izin Setengah Hari',
                        date: '20 Juni 2025',
                        status: 'Disetujui',
                        statusColor: Color(0xFF1BCFB4),
                        description: 'Urusan administrasi',
                      ),
                    ),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 220,
                      child: _IzinCard(
                        title: 'Izin Sakit',
                        date: '25 Juni 2025',
                        status: 'Ditolak',
                        statusColor: Color(0xFFE57373),
                        description: 'Demam tinggi',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) return; // stay on Dashboard
          if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => RiwayatScreen(token: token),
              ),
              (route) => false,
            );
          }
          // Tambahkan navigasi ke halaman lain jika ada (Absensi, Profil)
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String label;
  final bool isActive;
  const _DayCircle(this.label, this.isActive, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSunday = label == 'M';
    final Color bgColor =
        isSunday
            ? const Color(0xFFFF6B6B)
            : (isActive ? const Color(0xFF4F8DFD) : const Color(0xFFE3EAF2));
    final Color textColor =
        isSunday ? Colors.white : (isActive ? Colors.white : Colors.black54);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4F8DFD), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IzinCard extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final Color statusColor;
  final String description;
  const _IzinCard({
    required this.title,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
