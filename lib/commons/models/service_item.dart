import 'localized_text.dart';

class ServiceItem {
  final String id;
  final String branchId;
  final LocalizedText name;
  final LocalizedText description;
  final String category;
  final num price;
  final int durationMin;
  final bool isAddon;
  final bool active;
  final int ordersCount;
  final num revenue30d;

  const ServiceItem({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.durationMin,
    required this.isAddon,
    required this.active,
    required this.ordersCount,
    required this.revenue30d,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id'] as String,
        branchId: json['branchId']?.toString() ?? '',
        name: LocalizedText.fromJson(json['name']),
        description: LocalizedText.fromJson(json['description']),
        category: json['category']?.toString() ?? '',
        price: json['price'] as num? ?? 0,
        durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
        isAddon: json['type'] == 'addon',
        active: json['active'] == true,
        ordersCount: (json['ordersCount'] as num?)?.toInt() ?? 0,
        revenue30d: json['revenue30d'] as num? ?? 0,
      );
}
