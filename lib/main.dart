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
      debugShowCheckedModeBanner: false, // Sembunyikan banner debug
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

      // Konten utama dengan layout responsive
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Tentukan breakpoint: mobile jika lebar < 600px
          final bool isMobile = constraints.maxWidth < 600;
          final bool isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
          // isDesktop: lebar >= 1024 (web)

          // Ukuran responsif berdasarkan platform/ukuran layar
          final double iconSize = isMobile ? 80 : (isTablet ? 100 : 120);
          final double titleFontSize = isMobile ? 18 : (isTablet ? 22 : 26);
          final double bodyFontSize = isMobile ? 14 : (isTablet ? 16 : 18);
          final double spacing = isMobile ? 20 : (isTablet ? 28 : 36);
          final double containerPadding =
              isMobile ? 12 : (isTablet ? 20 : 28);
          final double horizontalPadding =
              isMobile ? 24 : (isTablet ? 80 : 200);
          final double buttonPadding =
              isMobile ? 12 : (isTablet ? 16 : 20);
          final double buttonFontSize =
              isMobile ? 14 : (isTablet ? 16 : 18);

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: spacing,
              ),
              child: Column(
                // Susun elemen vertikal, rata tengah
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Flutter Dash
                  Icon(
                    Icons.flutter_dash,
                    size: iconSize,
                    color: Colors.blue,
                  ),
                  SizedBox(height: spacing), // Jarak/Spasi

                  // Judul
                  Text(
                    'Selamat Datang di Aplikasi PPB Kelompok 1!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacing * 0.8),

                  // Container pembungkus teks deskripsi
                  Container(
                    width: double.infinity, // Lebar penuh dalam padding
                    padding: EdgeInsets.all(containerPadding),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(
                        isMobile ? 8 : 12,
                      ),
                      border: Border.all(
                        color: Colors.blue.shade100,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Ini adalah contoh penggunaan Container untuk membungkus elemen teks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: bodyFontSize),
                    ),
                  ),
                  SizedBox(height: spacing),

                  // Label platform saat ini (informasi responsive)
                  Text(
                    isMobile
                        ? '📱 Tampilan Mobile'
                        : (isTablet
                            ? '📲 Tampilan Tablet'
                            : '🖥️ Tampilan Web/Desktop'),
                    style: TextStyle(
                      fontSize: bodyFontSize - 2,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: spacing * 0.6),

                  // Tombol aksi
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: buttonPadding * 2,
                        vertical: buttonPadding,
                      ),
                      textStyle: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isMobile ? 8 : 12,
                        ),
                      ),
                    ),
                    child: const Text('Klik Saya'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}