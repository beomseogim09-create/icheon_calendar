import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(initializationSettings);

    // 안드로이드 13 이상 권한 요청
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // 🔥 [캘린더 화면 에러 해결]: 지워졌던 즉시 테스트 알림 함수를 다시 복구했습니다!
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      '테스트 알림',
      channelDescription: '알림 기능 테스트용입니다.',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _localNotificationsPlugin.show(
      0,
      '🔔 이천고 학사일정',
      '상단바 알림 기능이 정상 작동 중입니다!',
      const NotificationDetails(android: androidDetails),
    );
  }

  // 특정 날짜(학사일정)에 맞춰 알림을 예약하는 함수
  static Future<void> scheduleEventNotification({
    required int id,
    required String title,
    required String body,
    required DateTime eventDate, // 일정이 있는 날짜
    required bool isDayBefore, // true면 하루 전, false면 당일 알림
  }) async {
    // 알림을 보낼 날짜 계산
    DateTime targetDate =
        isDayBefore ? eventDate.subtract(const Duration(days: 1)) : eventDate;

    // 알림을 보낼 시간 설정 (예: 아침 8시 30분)
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      targetDate.year,
      targetDate.month,
      targetDate.day,
      8, // 시 (Hour)
      30, // 분 (Minute)
    );

    // 이미 지난 시간이라면 예약하지 않음
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'schedule_channel',
      '일정 알림',
      channelDescription: '이천고 학사일정 예약 알림입니다.',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // 폰이 자고 있어도 깨움
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // 모든 예약된 알림 취소 (알림 끌 때 사용)
  static Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }
}
