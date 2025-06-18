import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class IzinScreen extends StatefulWidget {
  final String token;
  const IzinScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<IzinScreen> createState() => _IzinScreenState();
}

class _IzinScreenState extends State<IzinScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _category;
  final TextEditingController _reasonController = TextEditingController();
  File? _photo;
  Uint8List? _webPhotoBytes;
  String? _webPhotoName;
  bool _isLoading = false;

  final List<String> _categories = [
    'Cuti Tahunan',
    'Izin Sakit',
    'Izin Setengah Hari',
  ];

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
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

  Future<void> _pickPhoto() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _webPhotoBytes = result.files.single.bytes;
            _webPhotoName = result.files.single.name;
          });
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (picked != null) {
          setState(() {
            _photo = File(picked.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
    }
  }

  Future<void> _submitIzin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final token = widget.token;
    final uri = Uri.parse('http://localhost:8000/api/employee/permission');
    final request =
        http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['start_date'] = _startDate!.toIso8601String().split('T')[0]
          ..fields['end_date'] = _endDate!.toIso8601String().split('T')[0]
          ..fields['category'] = _category!
          ..fields['reason'] = _reasonController.text;
    if (kIsWeb && _webPhotoBytes != null && _webPhotoName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'proof_photo',
          _webPhotoBytes!,
          filename: _webPhotoName,
        ),
      );
    } else if (_photo != null) {
      request.files.add(
        await http.MultipartFile.fromPath('proof_photo', _photo!.path),
      );
    }
    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Pengajuan izin berhasil!'),
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Pengajuan izin gagal!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan.')));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Izin'),
        backgroundColor: const Color(0xFF4F8DFD),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Container(
            width: 430, // max width for mobile look
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Mulai',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FB),
                        border: Border.all(color: Color(0xFFE3EAF2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate == null
                                ? 'mm/dd/yyyy'
                                : _startDate!.toIso8601String().split('T')[0],
                            style: TextStyle(
                              color:
                                  _startDate == null
                                      ? Colors.grey
                                      : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF4F8DFD),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tanggal Akhir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FB),
                        border: Border.all(color: Color(0xFFE3EAF2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endDate == null
                                ? 'mm/dd/yyyy'
                                : _endDate!.toIso8601String().split('T')[0],
                            style: TextStyle(
                              color:
                                  _endDate == null ? Colors.grey : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF4F8DFD),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF7F9FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE3EAF2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE3EAF2)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    hint: const Text('Pilih kategori'),
                    items:
                        _categories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _category = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pilih kategori';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Alasan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF7F9FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE3EAF2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE3EAF2)),
                      ),
                      hintText: 'Tuliskan alasan izin Anda',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alasan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Foto Bukti (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: DottedBorder(
                      color: const Color(0xFFB5C9F7),
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(12),
                      dashPattern: const [6, 3],
                      strokeWidth: 1.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Color(0xFFB5C9F7),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Unggah foto bukti',
                              style: TextStyle(
                                color: Color(0xFFB5C9F7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isPhotoReady() ? 'File terpilih' : 'Pilih File',
                              style: const TextStyle(
                                color: Color(0xFF4F8DFD),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isPhotoReady())
                              Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child:
                                    kIsWeb
                                        ? Image.memory(
                                          _webPhotoBytes!,
                                          height: 80,
                                        )
                                        : Image.file(_photo!, height: 80),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F8DFD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _submitIzin,
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Kirim',
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
          ),
        ),
      ),
    );
  }

  bool _isPhotoReady() {
    if (kIsWeb) {
      return _webPhotoBytes != null && _webPhotoName != null;
    } else {
      return _photo != null;
    }
  }
}
