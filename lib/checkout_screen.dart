import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final String token;
  const CheckoutScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Position? _position;
  File? _photo;
  Uint8List? _webPhotoBytes;
  String? _webPhotoName;
  bool _isLoading = false;
  GoogleMapController? _mapController;
  bool _canCheckout = false;
  bool _checkedStatus = false;

  LatLng? get _latLng =>
      _position != null ? LatLng(_position!.latitude, _position!.longitude) : null;

  @override
  void initState() {
    super.initState();
    _checkTodayStatus();
  }

  Future<void> _checkTodayStatus() async {
    setState(() { _checkedStatus = false; });
    final url = Uri.parse('http://localhost:8000/api/employee/attendance/today-status');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.token}',
      'Accept': 'application/json',
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      setState(() {
        _canCheckout = data['clock_in'] != null && data['clock_out'] == null;
        _checkedStatus = true;
      });
    } else {
      setState(() {
        _canCheckout = false;
        _checkedStatus = true;
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktifkan layanan lokasi!')),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak!')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi permanen ditolak!')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _position = pos;
      });
      if (!kIsWeb && _mapController != null && _latLng != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_latLng!));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil lokasi: $e')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _webPhotoBytes = result.files.single.bytes;
            _webPhotoName = result.files.single.name;
          });
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
        if (picked != null) {
          setState(() {
            _photo = File(picked.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  Future<void> _submitCheckout() async {
    if (!_canCheckout) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum check-in hari ini!')),
      );
      return;
    }
    if (_position == null || (!_isPhotoReady())) return;
    setState(() { _isLoading = true; });
    final token = widget.token;
    final uri = Uri.parse('http://localhost:8000/api/employee/attendance');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['type'] = 'out'
      ..fields['latitude'] = _position!.latitude.toString()
      ..fields['longitude'] = _position!.longitude.toString();
    if (kIsWeb && _webPhotoBytes != null && _webPhotoName != null) {
      request.files.add(http.MultipartFile.fromBytes('photo', _webPhotoBytes!, filename: _webPhotoName));
    } else if (_photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', _photo!.path));
    }
    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Check-out berhasil!')),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Check-out gagal!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan.')),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  bool _isPhotoReady() {
    if (kIsWeb) {
      return _webPhotoBytes != null && _webPhotoName != null;
    } else {
      return _photo != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-out')),
      body: !_checkedStatus
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!kIsWeb)
                  SizedBox(
                    height: 300,
                    child: _latLng == null
                        ? const Center(child: Text('Lokasi belum diambil'))
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _latLng!,
                              zoom: 17,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('me'),
                                position: _latLng!,
                                infoWindow: const InfoWindow(title: 'Lokasi Anda'),
                              ),
                            },
                            onMapCreated: (controller) => _mapController = controller,
                            myLocationEnabled: true,
                          ),
                  ),
                if (kIsWeb)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _getLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Ambil Lokasi'),
                        ),
                        const SizedBox(height: 8),
                        _position == null
                            ? const Text('Lokasi: belum diambil')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Lat: ${_position!.latitude}, Lng: ${_position!.longitude}'),
                                  if (_position!.latitude == 0.0 && _position!.longitude == 0.0)
                                    const Text(
                                      'Lokasi belum didapatkan, silakan klik tombol GPS dan pastikan GPS aktif.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                      ],
                    ),
                  ),
                if (!kIsWeb)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _getLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('GPS'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _position == null
                              ? const Text('Lokasi: belum diambil')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Lat: ${_position!.latitude}, Lng: ${_position!.longitude}'),
                                    if (_position!.latitude == 0.0 && _position!.longitude == 0.0)
                                      const Text(
                                        'Lokasi belum didapatkan, silakan klik tombol GPS dan pastikan GPS aktif.',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(!_isPhotoReady() ? 'Ambil Foto' : 'Foto Diambil'),
                ),
                if (_isPhotoReady())
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: kIsWeb
                        ? Image.memory(_webPhotoBytes!, height: 120)
                        : Image.file(_photo!, height: 120),
                  ),
                const Spacer(),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_canCheckout && _position != null && _isPhotoReady() && !_isLoading)
                        ? _submitCheckout
                        : null,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Check-out'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
} 