import 'json_read.dart';
import 'localized_text.dart';

class ScheduleBlock {
  final String id;

  /// As the server sent them, so a block is posted back unchanged.
  final String start;
  final String end;
  final String reason;

  const ScheduleBlock({required this.id, required this.start, required this.end, required this.reason});

  DateTime? get startAt => DateTime.tryParse(start);

  DateTime? get endAt => DateTime.tryParse(end);

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) => ScheduleBlock(
        id: readStr(json['id']),
        start: readStr(json['start']),
        end: readStr(json['end']),
        reason: readStr(json['reason']),
      );
}

class SlotOrder {
  final String id;
  final String number;
  final String plate;
  final String status;
  final LocalizedText serviceName;

  const SlotOrder({
    required this.id,
    required this.number,
    required this.plate,
    required this.status,
    required this.serviceName,
  });

  factory SlotOrder.fromJson(Map<String, dynamic> json) => SlotOrder(
        id: readStr(json['id']),
        number: readStr(json['number']),
        plate: readStr(json['plate']),
        status: readStr(json['status']),
        serviceName: LocalizedText.fromJson(json['serviceName']),
      );
}

class ScheduleSlot {
  final String start;
  final int capacity;
  final int occupied;
  final bool past;
  final ScheduleBlock? blocked;
  final List<SlotOrder> orders;

  const ScheduleSlot({
    required this.start,
    required this.capacity,
    required this.occupied,
    required this.past,
    required this.blocked,
    required this.orders,
  });

  DateTime? get startAt => DateTime.tryParse(start);

  double get fill => capacity <= 0 ? 0 : occupied / capacity;

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        start: readStr(json['start']),
        capacity: readInt(json['capacity']),
        occupied: readInt(json['occupied']),
        past: readBool(json['past']),
        blocked: json['blocked'] is Map ? ScheduleBlock.fromJson(readMap(json['blocked'])) : null,
        orders: readMaps(json['orders']).map(SlotOrder.fromJson).toList(),
      );
}

class ScheduleDay {
  final String branchId;
  final String date;
  final int slotIntervalMin;
  final int capacity;
  final String open;
  final String close;
  final bool closed;
  final List<ScheduleSlot> slots;
  final List<ScheduleBlock> blocks;

  const ScheduleDay({
    required this.branchId,
    required this.date,
    required this.slotIntervalMin,
    required this.capacity,
    required this.open,
    required this.close,
    required this.closed,
    required this.slots,
    required this.blocks,
  });

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    final hours = readMap(json['hours']);
    return ScheduleDay(
      branchId: readStr(json['branchId']),
      date: readStr(json['date']),
      slotIntervalMin: readInt(json['slotIntervalMin'], 30),
      capacity: readInt(json['capacity']),
      open: readStr(hours['open']),
      close: readStr(hours['close']),
      closed: readBool(hours['closed']),
      slots: readMaps(json['slots']).map(ScheduleSlot.fromJson).toList(),
      blocks: readMaps(json['blocks']).map(ScheduleBlock.fromJson).toList(),
    );
  }

  /// [start] plus one slot, in the ISO form the dashboard posts.
  String slotEnd(String start) {
    final at = DateTime.tryParse(start);
    if (at == null) return start;
    return at.add(Duration(minutes: slotIntervalMin)).toUtc().toIso8601String();
  }

  /// Where a block may start: slots that have not passed and are not blocked.
  List<String> get blockableStarts =>
      slots.where((s) => !s.past && s.blocked == null).map((s) => s.start).toList();

  /// Where a block may end: the next slots, then the end of the last one.
  List<String> endsAfter(String start) {
    final at = DateTime.tryParse(start);
    if (at == null || slots.isEmpty) return const [];
    return [
      ...slots.skip(1).map((s) => s.start),
      slotEnd(slots.last.start),
    ].where((end) {
      final value = DateTime.tryParse(end);
      return value != null && value.isAfter(at);
    }).toList();
  }
}
