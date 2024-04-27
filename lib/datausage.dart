import 'package:app_usage/app_usage.dart';

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
}
