import 'package:app_usage/app_usage.dart';
import 'package:call_log/call_log.dart';
import 'package:background_location/background_location.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async'; // Import this for Timer and Stream

class UsageStatsManager {
  static Future<Map<String, int>> getDailyAppUsageStats() async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    try {
      List<AppUsageInfo> infoList =
          await AppUsage().getAppUsage(startDate, endDate);
      Map<String, int> appUsageStats = {};

      for (var info in infoList) {
        int totalUsageSeconds = info.usage.inSeconds;
        appUsageStats[info.appName] = totalUsageSeconds;
      }
      return appUsageStats;
    } catch (e) {
      print("Error fetching daily app usage stats: $e");
      return {};
    }
  }

  static Future<String> formatCallLogEntry() async {
    var today = DateTime.now();
    Iterable<CallLogEntry> entries = await CallLog.get();
    List<String> formattedEntries = [];
    for (var entry in entries) {
      if (entry.timestamp != null &&
          isSameDay(
              DateTime.fromMillisecondsSinceEpoch(entry.timestamp!), today)) {
        String durationString = entry.duration.toString();
        int? millisecondsSinceEpoch = entry.timestamp;
        DateTime? startTime;
        String formattedStartTime = '';
        if (millisecondsSinceEpoch != null) {
          startTime =
              DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
          formattedStartTime = startTime.toString();
        }
        String formattedEntry =
            "Duration: $durationString\nCall Time: $formattedStartTime\n";
        formattedEntries.add(formattedEntry);
      }
    }
    return Future.value(formattedEntries.join('\n'));
  }

  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static Future<String> getLocationUpdates() async {
    try {
      await BackgroundLocation.setAndroidNotification(
        title: "Notification title",
        message: "Notification message",
        icon: "@mipmap/ic_launcher",
      );

      await BackgroundLocation.setAndroidConfiguration(1000);

      await BackgroundLocation.startLocationService();

      String locationData = "";

      BackgroundLocation.getLocationUpdates((location) {
        locationData = location.toString();
      });

      return locationData;
    } catch (e) {
      print("Error getting location updates: $e");
      return "";
    }
  }

  static Future<void> stopLocationUpdates() async {
    try {
      await BackgroundLocation.stopLocationService();
    } catch (e) {
      print("Error stopping location updates: $e");
      // Handle errors, such as displaying an error message to the user
    }
  }
}

enum Activity { sitting, running, walking }

class ActivityTracker {
  static DateTime currentTime = DateTime.now();
  static Activity _currentActivity = Activity.sitting;
  static Duration? _activityStartTime;
  static Duration _sittingDuration = Duration.zero;
  static Duration _walkingDuration = Duration.zero;
  static Duration _runningDuration = Duration.zero;
  static Timer? _timer;

  static void startTracking() {
    accelerometerEventStream().listen((AccelerometerEvent event) {
      detectActivity(event);
    });
  }

  static void detectActivity(AccelerometerEvent event) {
    double accelerationMagnitude = calculateMagnitude(event);

    if (_currentActivity == Activity.sitting && accelerationMagnitude > 1.0) {
      // Start the timer only if it's not running
      if (_timer == null || !_timer!.isActive) {
        startTimer();
        _activityStartTime = Duration.zero;
      }
      _currentActivity = Activity.walking;
    } else if (_currentActivity == Activity.walking &&
        accelerationMagnitude > 9.0) {
      // Start the timer only if it's not running
      if (_timer == null || !_timer!.isActive) {
        startTimer();
        _activityStartTime = Duration.zero;
      }
      _currentActivity = Activity.running;
    } else if (_currentActivity != Activity.sitting &&
        accelerationMagnitude < 1.0) {
      // Stop the timer if it's running
      if (_timer == null || !_timer!.isActive) {
        startTimer();
        _activityStartTime = Duration.zero;
      }
      _currentActivity = Activity.sitting;
    } else {
      if (_timer == null || !_timer!.isActive) {
        startTimer();
      }
    }
  }

  static void startTimer() {
    _timer?.cancel(); // Cancel previous timer if any
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      updateDuration();
    });
  }

  static void stopTimer() {
    _timer?.cancel(); // Cancel the timer if it's running
  }

  static double calculateMagnitude(AccelerometerEvent event) {
    return event.x.abs() + event.y.abs() + event.z.abs();
  }

  static void updateDuration() {
    switch (_currentActivity) {
      case Activity.sitting:
        _sittingDuration += Duration(seconds: 1);
        break;
      case Activity.walking:
        _walkingDuration += Duration(seconds: 1);
        break;
      case Activity.running:
        _runningDuration += Duration(seconds: 1);
        break;
    }
    if (currentTime.hour == 0 &&
        currentTime.minute == 0 &&
        currentTime.second == 0) {
      reset();
    }
  }

  static void reset() {
    stopTimer();
    _sittingDuration = Duration.zero;
    _walkingDuration = Duration.zero;
    _runningDuration = Duration.zero;
    startTimer();
  }

  static Map<String, Duration> getActivityDurations() {
    return {
      'Sitting': _sittingDuration,
      'Walking': _walkingDuration,
      'Running': _runningDuration,
    };
  }
}
