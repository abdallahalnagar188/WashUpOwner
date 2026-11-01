import 'json_read.dart';
import 'localized_text.dart';

/// A service row of `/vendor/services` with what the edit form sends back.
class ManagedService {
  static const List<String> categories = ['exterior', 'interior', 'full', 'deep'];

  final String id;
  final String branchId;
  final LocalizedText branchName;
  final LocalizedText name;
  final LocalizedText description;
  final String category;
  final String type;
  final num price;
  final num durationMin;
  final bool active;
  final int ordersCount;
  final num revenue30d;

  const ManagedService({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    required this.price,
    required this.durationMin,
    required this.active,
    required this.ordersCount,
    required this.revenue30d,
  });

  bool get isAddon => type == 'addon';

  factory ManagedService.fromJson(Map<String, dynamic> json) => ManagedService(
        id: readStr(json['id']),
        branchId: readStr(json['branchId']),
        branchName: LocalizedText.fromJson(json['branchName']),
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        category: readStr(json['category']),
        type: readStr(json['type']).isEmpty ? 'primary' : readStr(json['type']),
        price: readNum(json['price']),
        durationMin: readNum(json['durationMin']),
        active: readBool(json['active']),
        ordersCount: readInt(json['ordersCount']),
        revenue30d: readNum(json['revenue30d']),
      );

  /// The full body the dashboard sends when only the switch moves.
  Map<String, dynamic> payload({required bool active}) => {
        'branchId': branchId,
        'name': {'ar': name.ar, 'en': name.en},
        'description': {'ar': description.ar, 'en': description.en},
        'category': category,
        'type': type,
        'price': price,
        'durationMin': durationMin,
        'active': active,
      };
}

class ServiceList {
  final List<ManagedService> items;
  final bool canEdit;

  const ServiceList({required this.items, required this.canEdit});

  factory ServiceList.fromReply(Map<String, dynamic> reply) => ServiceList(
        items: readMaps(reply['data']).map(ManagedService.fromJson).toList(),
        canEdit: readBool(readMap(reply['meta'])['canEdit']),
      );
}
