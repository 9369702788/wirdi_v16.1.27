import 'package:flutter/material.dart';

import '../../core/models/progress_models.dart';
import '../../core/services/user_progress_service.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Visual month-style reading calendar built from the same real,
/// date-keyed daily activity log already used for the Home Dashboard's
/// week summary (UserProgressService.weekSummary) -- not a separate or
/// simulated data source. Shows the last 4 calendar weeks (Saturday to
/// Friday, matching the app's existing week-start convention) so the
/// user can see at a glance which days met their daily wird target.
class HijriConverter {
  static String convertToHijri(DateTime gregorian) {
    final jd = _gregorianToJD(gregorian);
    final hijri = _jdToHijri(jd);
    return "${hijri['day']}/${hijri['month']}/${hijri['year']} AH";
  }
  
  static DateTime convertToGregorian(int hijriDay, int hijriMonth, int hijriYear) {
    final jd = _hijriToJD(hijriDay, hijriMonth, hijriYear);
    return _jdToGregorian(jd);
  }
  
  static int _gregorianToJD(DateTime g) {
    final a = (14 - g.month) ~/ 12;
    final y = g.year + 4800 - a;
    final m = g.month + 12 * a - 3;
    return g.day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }
  
  static Map<String, int> _jdToHijri(int jd) {
    final n = jd + 1948440 - 385;
    final q = n ~/ 10631;
    final r = n % 10631;
    final a = (r ~/ 5265) + 1;
    final w = r - 5265 * a + 1;
    final q1 = w ~/ 354;
    final q2 = (w % 354) ~/ 30;
    return {'year': 30 * q + 30 * a + q1 + 1, 'month': q2 + 1, 'day': (w % 30) + 1};
  }
  
  static int _hijriToJD(int d, int m, int y) {
    return (d + 29 * (m - 1) + (m - 1) ~/ 11 + (y - 1) * 354 + (3 + 11 * y) ~/ 30 + 1948440 - 385).toInt();
  }
  
  static DateTime _jdToGregorian(int jd) {
    final a = jd + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    return DateTime(b * 100 + d - 4800 + m ~/ 10, m + 3 - 12 * (m ~/ 10), e - (153 * m + 2) ~/ 5 + 1);
  }
}

class KhatmaCalendarScreen extends StatefulWidget {
  const KhatmaCalendarScreen({super.key});

  @override
  State<KhatmaCalendarScreen> createState() => _KhatmaCalendarScreenState();
}

class _KhatmaCalendarScreenState extends State<KhatmaCalendarScreen> {
  static const int _weeksToShow = 4;
  List<List<DailyActivitySummary>> _weeks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weeks = <List<DailyActivitySummary>>[];
    for (var i = _weeksToShow - 1; i >= 0; i--) {
      weeks.add(await UserProgressService.weekSummary(weeksAgo: i));
    }
    if (!mounted) return;
    setState(() {
      _weeks = weeks;
      _loading = false;
    });
  }

  static const List<String> _monthNamesAr = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
  static const List<String> _monthNamesEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  String _monthYearLabel(DateTime date, bool isAr) {
    final names = isAr ? _monthNamesAr : _monthNamesEn;
    return '${names[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.khatmaCalendarTitle), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
                children: [
                  for (var i = 0; i < _weeks.length; i++) ...[
                    if (_weeks[i].isNotEmpty && (i == 0 || _weeks[i].first.date.month != _weeks[i - 1].first.date.month))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_monthYearLabel(_weeks[i].first.date, isAr), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    _WeekRow(week: _weeks[i], today: todayKey),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _LegendDot(color: AppColors.primaryEmerald, label: l10n.khatmaCalendarLegendMet),
                      _LegendDot(color: Colors.orange, label: l10n.khatmaCalendarLegendMissed),
                      _LegendDot(color: AppColors.mutedText.withValues(alpha: 0.3), label: l10n.khatmaCalendarLegendFuture),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DailyActivitySummary> week;
  final DateTime today;
  const _WeekRow({required this.week, required this.today});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in week)
          Expanded(child: _DayCell(day: day, isFuture: day.date.isAfter(today))),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DailyActivitySummary day;
  final bool isFuture;
  const _DayCell({required this.day, required this.isFuture});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (isFuture) {
      color = AppColors.mutedText.withValues(alpha: 0.12);
    } else if (day.wirdTargetMet) {
      color = AppColors.primaryEmerald.withValues(alpha: 0.85);
    } else if (day.wirdPages > 0) {
      color = Colors.orange.withValues(alpha: 0.55);
    } else {
      color = Colors.orange.withValues(alpha: 0.85);
    }
    return Padding(
      padding: const EdgeInsets.all(3),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isFuture ? AppColors.mutedText : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
      ],
    );
  }
}
