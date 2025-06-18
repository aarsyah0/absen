import 'package:flutter/material.dart';

class IzinScreen extends StatelessWidget {
  const IzinScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izin')),
      body: const Center(child: Text('Halaman Izin')), 
    );
  }
} 