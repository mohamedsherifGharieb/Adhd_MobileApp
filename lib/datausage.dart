import 'package:app_usage/app_usage.dart';
import 'package:call_log/call_log.dart';
import 'package:background_location/background_location.dart';

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
      // Stop listening to location changes
      await BackgroundLocation.stopLocationService();
    } catch (e) {
      print("Error stopping location updates: $e");
      // Handle errors, such as displaying an error message to the user
    }
  }
}
