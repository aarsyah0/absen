import 'dart:convert';

import 'package:absen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'dashboard_screen.dart';

class RiwayatScreen extends StatefulWidget {
  final String token;
  final String userName;
  const RiwayatScreen({Key? key, required this.token, required this.userName})
    : super(key: key);

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filtering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<List<Map<String, dynamic>>> fetchAbsensi() async {
    String urlStr =
        'http://localhost:8000/api/employee/attendance/history?length=20&start=0';
    if (_startDate != null) {
      urlStr += '&start_date=${DateFormat('yyyy-MM-dd').format(_startDate!)}';
    }
    if (_endDate != null) {
      urlStr += '&end_date=${DateFormat('yyyy-MM-dd').format(_endDate!)}';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Gagal mengambil riwayat absensi');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPermission() async {
    String urlStr =
        'http://localhost:8000/api/employee/permission/history?length=20&start=0';
    if (_startDate != null) {
      urlStr += '&start_date=${DateFormat('yyyy-MM-dd').format(_startDate!)}';
    }
    if (_endDate != null) {
      urlStr += '&end_date=${DateFormat('yyyy-MM-dd').format(_endDate!)}';
    }
    final url = Uri.parse(urlStr);
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        return <Map<String, dynamic>>[];
      }
    } else {
      throw Exception('Gagal mengambil riwayat izin');
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filtering = !_filtering;
    });
    // FutureBuilder akan rebuild karena setState
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _filtering = !_filtering;
    });
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: InkWell(
                onTap: () => _pickDate(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FB),
                    border: Border.all(color: const Color(0xFFE3EAF2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        size: 18,
                        color: Color(0xFF4F8DFD),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _startDate == null
                              ? 'Tanggal Mulai'
                              : DateFormat('dd/MM/yyyy').format(_startDate!),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                _startDate == null ? Colors.grey : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 150,
              child: InkWell(
                onTap: () => _pickDate(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FB),
                    border: Border.all(color: const Color(0xFFE3EAF2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range,
                        size: 18,
                        color: Color(0xFF4F8DFD),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _endDate == null
                              ? 'Tanggal Akhir'
                              : DateFormat('dd/MM/yyyy').format(_endDate!),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                _endDate == null ? Colors.grey : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _applyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F8DFD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Terapkan',
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
            if (_startDate != null || _endDate != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: _clearFilter,
                tooltip: 'Hapus Filter',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat - ${widget.userName}'),
        backgroundColor: const Color(0xFF4F8DFD),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF4F8DFD),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [Tab(text: 'Absensi'), Tab(text: 'Izin')],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FB),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Absensi
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchAbsensi(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat data absensi'),
                      );
                    }
                    final data = snapshot.data ?? [];
                    if (data.isEmpty) {
                      return const Center(
                        child: Text('Belum ada data absensi'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final item = data[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              item['type'] == 'in' ? Icons.login : Icons.logout,
                              color: const Color(0xFF4F8DFD),
                            ),
                            title: Text(
                              item['type'] == 'in' ? 'Check-in' : 'Check-out',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${item['date']} ${item['time']}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    item['status'] == 'accepted'
                                        ? const Color(
                                          0xFF1BCFB4,
                                        ).withOpacity(0.15)
                                        : (item['status'] == 'pending'
                                            ? const Color(
                                              0xFFFFC542,
                                            ).withOpacity(0.15)
                                            : const Color(
                                              0xFFE57373,
                                            ).withOpacity(0.15)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['status'] ?? '-',
                                style: TextStyle(
                                  color:
                                      item['status'] == 'accepted'
                                          ? const Color(0xFF1BCFB4)
                                          : (item['status'] == 'pending'
                                              ? const Color(0xFFFFC542)
                                              : const Color(0xFFE57373)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                // Tab Izin
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchPermission(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat data izin'),
                      );
                    }
                    final data = snapshot.data ?? [];
                    if (data.isEmpty) {
                      return const Center(child: Text('Belum ada data izin'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final item = data[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.assignment_turned_in_outlined,
                              color: Color(0xFF4F8DFD),
                            ),
                            title: Text(
                              item['category'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['start_date']} - ${item['end_date']}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    item['status'] == 'accepted'
                                        ? const Color(
                                          0xFF1BCFB4,
                                        ).withOpacity(0.15)
                                        : (item['status'] == 'pending'
                                            ? const Color(
                                              0xFFFFC542,
                                            ).withOpacity(0.15)
                                            : const Color(
                                              0xFFE57373,
                                            ).withOpacity(0.15)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['status'] ?? '-',
                                style: TextStyle(
                                  color:
                                      item['status'] == 'accepted'
                                          ? const Color(0xFF1BCFB4)
                                          : (item['status'] == 'pending'
                                              ? const Color(0xFFFFC542)
                                              : const Color(0xFFE57373)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF4F8DFD),
        unselectedItemColor: Colors.black38,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) return; // stay on Riwayat
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DashboardScreen(
                      userName: widget.userName,
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
                builder: (context) => ProfileScreen(token: widget.token),
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
