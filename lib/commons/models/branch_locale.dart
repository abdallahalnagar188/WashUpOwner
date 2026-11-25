/// How a branch shows money and time: its country's currency and time zone.
/// Orders carry it as `branchLocale`; `auth/me` branches as flat fields.
class BranchLocale {
  final String symbol;
  final int decimals;
  final String timezone;

  const BranchLocale({required this.symbol, required this.decimals, required this.timezone});

  /// `{symbol, decimals, timezone}` on order rows; null when absent.
  static BranchLocale? fromJson(Object? json) {
    if (json is! Map) return null;
    final symbol = json['symbol']?.toString();
    if (symbol == null || symbol.isEmpty) return null;
    return BranchLocale(
      symbol: symbol,
      decimals: (json['decimals'] as num?)?.toInt() ?? 2,
      timezone: json['timezone']?.toString() ?? 'Africa/Cairo',
    );
  }

  /// `currencySymbol`, `currencyDecimals` and `timezone` on an `auth/me` branch.
  static BranchLocale? fromBranchJson(Map<String, dynamic> json) => fromJson({
        'symbol': json['currencySymbol'],
        'decimals': json['currencyDecimals'],
        'timezone': json['timezone'],
      });

  /// Standard UTC offsets of the Arab countries' time zones. Only Egypt,
  /// Lebanon and Palestine change their clocks; their rules are in [offsetAt].
  static const _fixedHours = {
    'Asia/Riyadh': 3, 'Asia/Kuwait': 3, 'Asia/Qatar': 3, 'Asia/Bahrain': 3, 'Asia/Baghdad': 3,
    'Asia/Amman': 3, 'Asia/Damascus': 3, 'Asia/Aden': 3, 'Africa/Mogadishu': 3, 'Africa/Djibouti': 3,
    'Indian/Comoro': 3, 'Asia/Dubai': 4, 'Asia/Muscat': 4, 'Africa/Tripoli': 2, 'Africa/Khartoum': 2,
    'Africa/Tunis': 1, 'Africa/Algiers': 1, 'Africa/Casablanca': 1, 'Africa/Nouakchott': 0,
  };

  /// The branch's UTC offset at [at]; Cairo's rules for an unknown zone.
  Duration offsetAt(DateTime at) {
    final fixed = _fixedHours[timezone];
    if (fixed != null) return Duration(hours: fixed);
    final d = at.toUtc();
    DateTime last(int weekday, int month, int lastDay) {
      var day = lastDay;
      while (DateTime.utc(d.year, month, day).weekday != weekday) {
        day--;
      }
      return DateTime.utc(d.year, month, day);
    }

    // The clocks change at local midnight, not UTC midnight (GAP-069): a switch
    // to summer time happens at 00:00 UTC+2, the switch back at 00:00 UTC+3.
    const winter = Duration(hours: 2);
    const summerOffset = Duration(hours: 3);
    final DateTime start;
    final DateTime end;
    if (timezone == 'Asia/Beirut' || timezone == 'Asia/Hebron' || timezone == 'Asia/Gaza') {
      // Last Sunday of March to the last Sunday of October.
      start = last(DateTime.sunday, 3, 31).subtract(winter);
      end = last(DateTime.sunday, 10, 31).subtract(summerOffset);
    } else {
      // Egypt: last Friday of April to the end of the last Thursday of October.
      start = last(DateTime.friday, 4, 30).subtract(winter);
      end = last(DateTime.thursday, 10, 31).add(const Duration(days: 1)).subtract(summerOffset);
    }
    final summer = !d.isBefore(start) && d.isBefore(end);
    return summer ? summerOffset : winter;
  }

  /// The branch's calendar day at [now] (date only), so "today" follows the
  /// branch and not the phone's time zone (GAP-069).
  DateTime today([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    final wall = utc.add(offsetAt(utc));
    return DateTime(wall.year, wall.month, wall.day);
  }

  /// [today] of [locale], or the phone's day when the branch is unknown.
  static DateTime todayOf(BranchLocale? locale, [DateTime? now]) {
    if (locale != null) return locale.today(now);
    final local = (now ?? DateTime.now()).toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// [at] as the branch's wall clock. Server times are UTC; a time picked on
  /// the device is already a wall clock and is returned as it is.
  DateTime wallClock(DateTime at) => at.isUtc ? at.add(offsetAt(at)) : at;
}
