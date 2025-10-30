
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String portName = 'alarm_send_port';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  IsolateNameServer.registerPortWithName(
    ReceivePort().sendPort,
    portName,
  );
  await AndroidAlarmManager.initialize();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class TimeProvider with ChangeNotifier {
  List<TimeOfDay?> startTimes = List.filled(5, null);
  List<TimeOfDay?> endTimes = List.filled(5, null);

  TimeProvider() {
    loadTimes();
  }

  Future<void> loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 5; i++) {
      final startTimeString = prefs.getString('startTime_$i');
      if (startTimeString != null) {
        startTimes[i] = TimeOfDay(
          hour: int.parse(startTimeString.split(':')[0]),
          minute: int.parse(startTimeString.split(':')[1]),
        );
      }
      final endTimeString = prefs.getString('endTime_$i');
      if (endTimeString != null) {
        endTimes[i] = TimeOfDay(
          hour: int.parse(endTimeString.split(':')[0]),
          minute: int.parse(endTimeString.split(':')[1]),
        );
      }
    }
    notifyListeners();
  }

  void setTime(int index, TimeOfDay startTime, TimeOfDay endTime) {
    startTimes[index] = startTime;
    endTimes[index] = endTime;
    saveTimes();
    notifyListeners();
  }

  Future<void> saveTimes() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < 5; i++) {
      if (startTimes[i] != null) {
        await prefs.setString(
            'startTime_$i', '${startTimes[i]!.hour}:${startTimes[i]!.minute}');
      }
      if (endTimes[i] != null) {
        await prefs.setString(
            'endTime_$i', '${endTimes[i]!.hour}:${endTimes[i]!.minute}');
      }
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Time Silencer',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.accessNotificationPolicy.isDenied) {
      await Permission.accessNotificationPolicy.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);
    final prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Time Silencer'),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerNames[index],
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimePicker(
                        context: context,
                        title: 'Start Time',
                        time: timeProvider.startTimes[index],
                        onTimeChanged: (newTime) {
                          final endTime = timeProvider.endTimes[index] ??
                              const TimeOfDay(hour: 0, minute: 0);
                          timeProvider.setTime(index, newTime, endTime);
                        },
                      ),
                      _buildTimePicker(
                        context: context,
                        title: 'End Time',
                        time: timeProvider.endTimes[index],
                        onTimeChanged: (newTime) {
                          final startTime = timeProvider.startTimes[index] ??
                              const TimeOfDay(hour: 0, minute: 0);
                          timeProvider.setTime(index, startTime, newTime);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _saveAndSchedule(context);
        },
        label: const Text('Save'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  Widget _buildTimePicker({
    required BuildContext context,
    required String title,
    required TimeOfDay? time,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Column(
      children: [
        Text(title),
        const SizedBox(height: 5),
        ElevatedButton(
          onPressed: () async {
            final newTime = await showTimePicker(
              context: context,
              initialTime: time ?? TimeOfDay.now(),
            );
            if (newTime != null) {
              onTimeChanged(newTime);
            }
          },
          child: Text(
            time?.format(context) ?? 'Select Time',
          ),
        ),
      ],
    );
  }

  void _saveAndSchedule(BuildContext context) async {
    final timeProvider = Provider.of<TimeProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await timeProvider.saveTimes();

    for (int i = 0; i < 5; i++) {
      if (timeProvider.startTimes[i] != null &&
          timeProvider.endTimes[i] != null) {
        final now = DateTime.now();
        final startDateTime = DateTime(now.year, now.month, now.day,
            timeProvider.startTimes[i]!.hour, timeProvider.startTimes[i]!.minute);
        final endDateTime = DateTime(now.year, now.month, now.day,
            timeProvider.endTimes[i]!.hour, timeProvider.endTimes[i]!.minute);

        // Schedule silent alarm
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          i * 2,
          _setSilentMode,
          startAt: startDateTime,
          exact: true,
          wakeup: true,
        );

        // Schedule normal alarm
        await AndroidAlarmManager.periodic(
          const Duration(days: 1),
          i * 2 + 1,
          _setNormalMode,
          startAt: endDateTime,
          exact: true,
          wakeup: true,
        );
      }
    }
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Prayer times saved and scheduled!')),
    );
    _showPersistentNotification();
  }

  static Future<void> _setSilentMode() async {
    try {
      await SoundMode.setSoundMode(RingerModeStatus.silent);
    } catch (e) {
      //
    }
  }

  static Future<void> _setNormalMode() async {
    try {
      await SoundMode.setSoundMode(RingerModeStatus.normal);
    } catch (e) {
      //
    }
  }

  Future<void> _showPersistentNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'prayer_time_silencer_channel',
      'Prayer Time Silencer',
      channelDescription: 'Notification channel for Prayer Time Silencer',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Prayer Time Silencer is active',
      'Running in the background to manage your ringer mode.',
      platformChannelSpecifics,
    );
  }
}
