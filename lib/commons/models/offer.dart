import 'json_read.dart';
import 'localized_text.dart';

class Offer {
  static const List<String> statuses = ['active', 'scheduled', 'draft', 'disabled', 'expired'];

  final String id;
  final String scope;
  final LocalizedText title;
  final LocalizedText description;
  final String discountType;
  final num discountValue;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<String> branchIds;
  final List<String> serviceCategories;
  final int redemptions;
  final String status;
  final bool editable;

  const Offer({
    required this.id,
    required this.scope,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startAt,
    required this.endAt,
    required this.branchIds,
    required this.serviceCategories,
    required this.redemptions,
    required this.status,
    required this.editable,
  });

  bool get isPlatform => scope == 'platform';

  bool get isDraft => status == 'draft';

  bool get enabled => status != 'disabled';

  /// Drafts are published through the form and expired offers stay as they are.
  bool get canToggle => editable && status != 'draft' && status != 'expired';

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
        id: readStr(json['id']),
        scope: readStr(json['scope']),
        title: LocalizedText.fromJson(json['title']),
        description: LocalizedText.fromJson(json['description']),
        discountType: readStr(json['discountType']).isEmpty ? 'percent' : readStr(json['discountType']),
        discountValue: readNum(json['discountValue']),
        startAt: readDate(json['startAt']),
        endAt: readDate(json['endAt']),
        branchIds: readStrings(json['branchIds']),
        serviceCategories: readStrings(json['serviceCategories']),
        redemptions: readInt(json['redemptions']),
        status: readStr(json['status']),
        editable: readBool(json['editable']),
      );
}

class OfferList {
  final List<Offer> items;
  final Map<String, int> counts;

  const OfferList({required this.items, required this.counts});

  factory OfferList.fromReply(Map<String, dynamic> reply) => OfferList(
        items: readMaps(reply['data']).map(Offer.fromJson).toList(),
        counts: readCounts(readMap(reply['meta'])['counts']),
      );
}
