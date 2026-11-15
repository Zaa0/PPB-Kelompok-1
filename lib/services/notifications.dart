// Layanan notifikasi lokal (Android + Windows).
// Pemicunya polling di AppState saat ada pesan baru di room lain.
// Suara notifikasi tidak diatur di sini -> otomatis mengikuti
// pengaturan bawaan perangkat (sesuai permintaan tim).
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final notifPlugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

// Callback yang diisi main(): meneruskan balasan dari notifikasi ke AppState.
void Function(String roomId, String isiBalasan)? onQuickReply;

@pragma('vm:entry-point')
void notificationResponseHandler(NotificationResponse response) {
  final actionId = response.actionId ?? '';
  if (actionId.startsWith('reply-') && response.input?.isNotEmpty == true) {
    onQuickReply?.call(actionId.substring('reply-'.length), response.input!);
  }
}

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/launcher_icon');
  const windows = WindowsInitializationSettings(
    appName: 'UniTalk',
    appUserModelId: 'com.umrah.kelompok1.unitalk',
    guid: 'b2f1d8a4-3c7e-4f09-9a5d-68e21c04b7aa',
  );
  const settings = InitializationSettings(android: android, windows: windows);
  await notifPlugin.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: notificationResponseHandler,
    onDidReceiveBackgroundNotificationResponse: notificationResponseHandler,
  );

  // Izin notifikasi untuk Android 13 ke atas.
  final androidImpl = notifPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.requestNotificationsPermission();

  _ready = true;
}

// Tampilkan notifikasi pesan baru. Notifikasi bisa dibuka lebar
// (isi chat panjang tampil penuh) dan punya tombol balas cepat di Android.
Future<void> showMessageNotification({
  required String roomId,
  required String roomName,
  required String sender,
  required String text,
}) async {
  if (!_ready) return;
  final androidDetails = AndroidNotificationDetails(
    'unitalk_chat',
    'Pesan UniTalk',
    channelDescription: 'Notifikasi pesan baru di room UniTalk',
    importance: Importance.high,
    priority: Priority.high,
    styleInformation: BigTextStyleInformation(
      '$sender: $text',
      contentTitle: roomName,
      summaryText: sender,
    ),
    actions: [
      AndroidNotificationAction(
        'reply-$roomId',
        'Balas',
        inputs: [
          AndroidNotificationActionInput(
            allowFreeFormInput: true,
            label: 'Tulis balasan...',
          ),
        ],
      ),
    ],
  );
  const windowsDetails = WindowsNotificationDetails();
  final details = NotificationDetails(
    android: androidDetails,
    windows: windowsDetails,
  );
  await notifPlugin.show(
    id: roomId.hashCode,
    title: 'UniTalk - $roomName',
    body: '$sender: $text',
    notificationDetails: details,
    payload: roomId,
  );
}

@visibleForTesting
bool get notificationsReady => _ready;
