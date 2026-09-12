import 'notification_service.dart';
import 'hijri_date.dart';

class _Occasion {
  final int hijriMonth;
  final int hijriDay;
  final String ar;
  final String en;
  final int idOffset;
  const _Occasion(this.hijriMonth, this.hijriDay, this.ar, this.en, this.idOffset);
}

const List<_Occasion> _occasions = [
  _Occasion(1, 1, '\u0631\u0623\u0633 \u0627\u0644\u0633\u0646\u0629 \u0627\u0644\u0647\u062c\u0631\u064a\u0629', 'Islamic New Year', 0),
  _Occasion(1, 10, '\u064a\u0648\u0645 \u0639\u0627\u0634\u0648\u0631\u0627\u0621', 'Day of Ashura', 1),
  _Occasion(7, 27, '\u0627\u0644\u0625\u0633\u0631\u0627\u0621 \u0648\u0627\u0644\u0645\u0639\u0631\u0627\u062c', 'Isra and Miraj', 2),
  _Occasion(9, 1, '\u0628\u062f\u0627\u064a\u0629 \u0634\u0647\u0631 \u0631\u0645\u0636\u0627\u0646', 'Start of Ramadan', 3),
  _Occasion(9, 21, '\u0628\u062f\u0627\u064a\u0629 \u0627\u0644\u0639\u0634\u0631 \u0627\u0644\u0623\u0648\u0627\u062e\u0631 \u0645\u0646 \u0631\u0645\u0636\u0627\u0646', 'Start of Ramadan last 10 nights', 4),
  _Occasion(10, 1, '\u0639\u064a\u062f \u0627\u0644\u0641\u0637\u0631', 'Eid al-Fitr', 5),
  _Occasion(12, 9, '\u064a\u0648\u0645 \u0639\u0631\u0641\u0629', 'Day of Arafah', 6),
  _Occasion(12, 10, '\u0639\u064a\u062f \u0627\u0644\u0623\u0636\u062d\u0649', 'Eid al-Adha', 7),
];

class IslamicOccasionsService {
  IslamicOccasionsService._();
  static const _idBase = 900000300;

  static Future<void> scheduleReminders() async {
    final today = DateTime.now();
    for (final occasion in _occasions) {
      final nextDate = _findNextOccurrence(today, occasion.hijriMonth, occasion.hijriDay);
      if (nextDate == null) continue;
      final reminderTime = DateTime(nextDate.year, nextDate.month, nextDate.day - 1, 9, 0);
      if (reminderTime.isBefore(today)) continue;
      await NotificationService.scheduleOneTime(
        id: _idBase + occasion.idOffset,
        title: 'Wirdi',
        body: '${occasion.ar} \u063a\u062f\u064b\u0627 \u0625\u0646 \u0634\u0627\u0621 \u0627\u0644\u0644\u0647 / ${occasion.en} is tomorrow, God willing',
        fireAt: reminderTime,
      );
    }
  }

  static DateTime? _findNextOccurrence(DateTime from, int hijriMonth, int hijriDay) {
    for (var offset = 0; offset < 380; offset++) {
      final candidate = DateTime(from.year, from.month, from.day + offset);
      final hijri = HijriDate.fromGregorian(candidate);
      if (hijri.month == hijriMonth && hijri.day == hijriDay) return candidate;
    }
    return null;
  }
}
