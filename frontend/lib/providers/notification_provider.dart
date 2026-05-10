import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'last_visited_provider.dart';

final localNotificationsProvider = Provider<LocalNotificationsService>((ref) {
  return LocalNotificationsService();
});

class LocalNotificationsService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _inactivityChannel =
      AndroidNotificationChannel(
        'inactivity_reminder_channel_v2',
        'Inactivity Reminders',
        description: 'Reminds you if you haven\'t used the app for a day',
        importance: Importance.max,
      );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String localTimeZone = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(localTimeZone));
    print('🌍 Local timezone set to: $localTimeZone');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_inactivityChannel);
      print('📣 Created notification channel: ${_inactivityChannel.id}');

      final areEnabled = await androidPlugin.areNotificationsEnabled();
      print('📟 Android notifications enabled: $areEnabled');

      final channels = await androidPlugin.getNotificationChannels();
      for (final channel in channels ?? <AndroidNotificationChannel>[]) {
        if (channel.id == _inactivityChannel.id) {
          print('📬 Channel state -> id=${channel.id}, importance=${channel.importance.value}, playSound=${channel.playSound}, showBadge=${channel.showBadge}, enableVibration=${channel.enableVibration}');
        }
      }

      final notificationsGranted = await androidPlugin.requestNotificationsPermission();
      print('🔔 Notifications permission granted: $notificationsGranted');

      final exactGranted = await androidPlugin.requestExactAlarmsPermission();
      print('⏱️ Exact alarms permission granted: $exactGranted');
    }

    _initialized = true;
  }

  /// Shows an inactivity reminder notification with dynamic content
  /// based on the last visited timeline event. Called by the Dart Timer
  /// in main.dart after the delay has elapsed.
  Future<void> showInactivityReminder(LastVisitedEvent? lastVisited) async {
    if (!_initialized) await init();

    // Build dynamic body
    final List<String> bodies = [];
    if (lastVisited != null && lastVisited.title.isNotEmpty) {
      bodies.add('Continue where you left off. Explore "${lastVisited.title}" from the Prophet\'s (PBUH) life.');
    }
    bodies.add('Continue where you left. Explore the Seerah Timeline to discover more events.');
    bodies.add('Remember consistency is the key to wisdom. Continue your journey.');
    
    final random = Random();
    final randomBody = bodies[random.nextInt(bodies.length)];

    try {
      print('🔔 Showing inactivity reminder notification');
      print('🔔 Body: $randomBody');
      await _flutterLocalNotificationsPlugin.show(
        id: 1001,
        title: 'We miss you!',
        body: randomBody,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'inactivity_reminder_channel_v2',
            'Inactivity Reminders',
            channelDescription: 'Reminds you if you haven\'t used the app for a day',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print('✅ Inactivity reminder shown successfully!');
    } catch (e) {
      print('❌ Failed to show inactivity reminder: $e');
    }
  }

  /// Old immediate test method (kept for reference)
  Future<void> showImmediateInactivityReminder() async {
    if (!_initialized) await init();

    try {
      print('🚨 Showing immediate inactivity reminder test notification');
      await _flutterLocalNotificationsPlugin.show(
        id: 2001,
        title: 'We miss you!',
        body: 'Continue where you left. Explore the Seerah Timeline to discover more events from the Prophet\'s (PBUH) life.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'inactivity_reminder_channel_v2',
            'Inactivity Reminders',
            channelDescription: 'Reminds you if you haven\'t used the app for a day',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print('✅ Immediate inactivity reminder shown');
    } catch (e) {
      print('Failed to show immediate inactivity reminder: $e');
    }
  }

  Future<void> scheduleInactivityReminder(LastVisitedEvent? lastVisited) async {
    if (!_initialized) await init();

    const int notificationId = 1001; // Specific ID for inactivity reminder
    
    // First cancel the previous one
    print('🧽 Canceling any existing inactivity reminder before rescheduling');
    await _flutterLocalNotificationsPlugin.cancel(id: notificationId);

    // Generate message body
    final List<String> bodies = [];
    if (lastVisited != null && lastVisited.title.isNotEmpty) {
      bodies.add('Continue where you left off. Explore "${lastVisited.title}" from the Prophet\'s (PBUH) life.');
    }
    bodies.add('Continue where you left. Explore the Seerah Timeline to discover more events.');
    bodies.add('Remember consistency is the key to wisdom. Continue your Seerah journey when you are ready.');
    
    final random = Random();
    final randomBody = bodies[random.nextInt(bodies.length)];

    // Schedule new one 10s from now for testing (Change back to 24 hours later for production)
    try {
      final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(seconds: 10));
      print('✅ Scheduling inactivity reminder for: $scheduledDate');
      print('✅ Title: We miss you!');
      print('✅ Body: $randomBody');
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'We miss you!',
          body: randomBody,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'inactivity_reminder_channel_v2',
              'Inactivity Reminders',
              channelDescription: 'Reminds you if you haven\'t used the app for a day',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
        );
        print('✅ Scheduled with alarmClock');
      } catch (exactError) {
        print('⚠️ alarmClock scheduling failed, falling back to exact: $exactError');
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId,
          title: 'We miss you!',
          body: randomBody,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'inactivity_reminder_channel_v2',
              'Inactivity Reminders',
              channelDescription: 'Reminds you if you haven\'t used the app for a day',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        print('✅ Scheduled with exactAllowWhileIdle');
      }

      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('📌 Pending notifications: ${pending.length}');
      for (final request in pending) {
        print('   - id=${request.id}, title=${request.title}, body=${request.body}');
      }
    } catch (e) {
      // Ignore if scheduling fails (e.g. no exact alarm permission on Android 12+)
      print('Failed to schedule inactivity notification: $e');
    }
  }

  Future<void> cancelInactivityReminder() async {
    if (!_initialized) return;
    print('🗑️ Canceling inactivity reminder notification');
    await _flutterLocalNotificationsPlugin.cancel(id: 1001);
  }
}