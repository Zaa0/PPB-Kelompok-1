import 'package:flutter/material.dart';

// Entry point aplikasi
void main() {
  runApp(const MyApp());
}

// Root widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true, // Banner debug
      title: 'PPB Kelompok 1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// Halaman utama
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Header aplikasi
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'PPB Kelompok 1 - Widget Sederhana',
          style: TextStyle(color: Colors.white),
        ),
      ),

      // Konten utama
      body: Center(
        child: Column( // Susun elemen vertikal
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            const Icon(
              Icons.flutter_dash,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20), // Jarak/Spasi

            // Judul
            const Text(
              'Selamat Datang di Aplikasi PPB Kelompok 1!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Container pembungkus
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Ini adalah contoh penggunaan Container untuk membungkus elemen teks.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol
            ElevatedButton(
              onPressed: () {},
              child: const Text('Klik Saya'),
            ),
          ],
        ),
      ),
    );
  }
}