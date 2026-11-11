import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_pertama/main.dart';
import 'package:project_pertama/screens/home_screen.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Widget child, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('Welcome tetap rapi di HP dan desktop', (tester) async {
    await pumpAt(tester, const UniTalkApp(), const Size(360, 740));
    expect(find.text('Masuk sebagai Guest'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAt(tester, const UniTalkApp(), const Size(1440, 900));
    expect(find.text('Masuk dengan Akun'), findsOneWidget);
    expect(find.text('Masuk sebagai Guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home guest di HP hanya satu kolom', (tester) async {
    await pumpAt(
      tester,
      const HomeScreen(isGuest: true, userName: 'Guest'),
      const Size(360, 740),
    );
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Pilih room untuk mulai diskusi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home lebar menampilkan dua panel', (tester) async {
    await pumpAt(
      tester,
      const HomeScreen(isGuest: false, userName: 'Yuza'),
      const Size(1400, 900),
    );
    // Sidebar room + panel kanan kosong.
    expect(find.text('Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Pilih room untuk mulai diskusi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pilih room di layar lebar membuka chat di panel kanan', (
    tester,
  ) async {
    await pumpAt(
      tester,
      const HomeScreen(isGuest: false, userName: 'Yuza'),
      const Size(1400, 900),
    );
    await tester.tap(find.text('Pemrograman Mobile'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih room untuk mulai diskusi'), findsNothing);
    expect(find.text('48 anggota • Mata Kuliah'), findsOneWidget);
    expect(find.text('Tulis pesan...'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Layar sangat sempit tidak overflow', (tester) async {
    await pumpAt(
      tester,
      const HomeScreen(isGuest: true, userName: 'Guest'),
      const Size(320, 600),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab profil tampil di layar lebar', (tester) async {
    await pumpAt(
      tester,
      const HomeScreen(isGuest: false, userName: 'Yuza'),
      const Size(1400, 900),
    );
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Room Saya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
