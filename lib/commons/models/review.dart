import 'json_read.dart';
import 'localized_text.dart';

class Review {
  final String id;
  final int stars;
  final LocalizedText comment;
  final List<String> tags;
  final String customerId;
  final String customerName;
  final String orderId;
  final String orderNumber;
  final LocalizedText serviceName;
  final LocalizedText branchName;
  final String? reply;
  final DateTime? replyAt;
  final bool reportedByWash;
  final String? reportReason;
  final String status;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.stars,
    required this.comment,
    required this.tags,
    required this.customerId,
    required this.customerName,
    required this.orderId,
    required this.orderNumber,
    required this.serviceName,
    required this.branchName,
    required this.reply,
    required this.replyAt,
    required this.reportedByWash,
    required this.reportReason,
    required this.status,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: readStr(json['id']),
        stars: readInt(json['stars']),
        comment: LocalizedText.fromJson(json['comment']),
        tags: readStrings(json['tags']),
        customerId: readStr(json['customerId']),
        customerName: readStr(json['customerName']),
        orderId: readStr(json['orderId']),
        orderNumber: readStr(json['orderNumber']),
        serviceName: LocalizedText.fromJson(json['serviceName']),
        branchName: LocalizedText.fromJson(json['branchName']),
        reply: readStrOrNull(json['reply']),
        replyAt: readDate(json['replyAt']),
        reportedByWash: readBool(json['reportedByWash']),
        reportReason: readStrOrNull(json['reportReason']),
        status: readStr(json['status']),
        createdAt: readDate(json['createdAt']),
      );
}

class ReviewStats {
  final num average;
  final int count;
  final int unreplied;
  final int reported;
  final Map<int, int> distribution;

  const ReviewStats({
    required this.average,
    required this.count,
    required this.unreplied,
    required this.reported,
    required this.distribution,
  });

  factory ReviewStats.fromMeta(Map<String, dynamic> meta) {
    final distribution = readMap(meta['distribution']);
    return ReviewStats(
      average: readNum(meta['average']),
      count: readInt(meta['count']),
      unreplied: readInt(meta['unreplied']),
      reported: readInt(meta['reported']),
      distribution: {for (var star = 5; star >= 1; star--) star: readInt(distribution['$star'])},
    );
  }
}
