import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'prayer_service.dart';
import '../../theme/liquid_glass_theme.dart';

class PrayerTimesSection extends StatefulWidget {
  const PrayerTimesSection({super.key});

  @override
  State<PrayerTimesSection> createState() => _PrayerTimesSectionState();
}

class _PrayerTimesSectionState extends State<PrayerTimesSection> {
  late Future<Map<String, dynamic>> _prayerTimes;

  @override
  void initState() {
    super.initState();
    _prayerTimes = PrayerService.fetchPrayerTimes();
  }

  /// دالة لتحويل الوقت من 24 ساعة إلى 12 ساعة بالعربي
  String formatTo12Hour(String time24) {
    try {
      final date = DateFormat("HH:mm").parse(time24);
      return DateFormat("h:mm a", "en")
          .format(date)
          .replaceAll("AM", "ص")
          .replaceAll("PM", "م");
    } catch (e) {
      return time24; // fallback لو حصل خطأ
    }
  }

  /// دالة لمعرفة التوقيت القادم
  String? getNextPrayer(Map<String, dynamic> timings) {
    final now = DateTime.now();
    final today = DateFormat("yyyy-MM-dd").format(now);

    for (var entry in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]) {
      try {
        final date = DateFormat("yyyy-MM-dd HH:mm")
            .parse("$today ${timings[entry]}");
        if (date.isAfter(now)) {
          return entry; // أول صلاة بعد الوقت الحالي
        }
      } catch (_) {}
    }
    return null; // لو مفيش (مثلاً بعد العشاء)
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _prayerTimes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text(
            "❌ فشل تحميل مواعيد الصلاة",
            style: TextStyle(color: Colors.red),
          );
        } else if (!snapshot.hasData) {
          return const Text("لا توجد بيانات");
        }

        final timings = snapshot.data!;
        final prayerNames = {
          "Fajr": "الفجر",
          "Dhuhr": "الظهر",
          "Asr": "العصر",
          "Maghrib": "المغرب",
          "Isha": "العشاء",
        };

        final nextPrayer = getNextPrayer(timings);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(239, 238, 238, 238),
                LiquidGlassTheme.primaryGlass.withAlpha((255 * 0.8).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: LiquidGlassTheme.borderSecondary,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🕌 مواعيد الصلاة",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 37, 37, 37),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: prayerNames.entries.map((entry) {
                    final isNext = entry.key == nextPrayer;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timings[entry.key] != null
                                ? formatTo12Hour(timings[entry.key]!)
                                : "--:--",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isNext ? FontWeight.bold : FontWeight.normal,
                              color: isNext
                                  ? Colors.green
                                  : Colors.black, // أخضر للصلاة القادمة
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}