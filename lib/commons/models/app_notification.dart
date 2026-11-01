import 'json_read.dart';
import 'localized_text.dart';

class AppNotification {
  final String id;
  final String type;
  final LocalizedText title;
  final LocalizedText body;
  final String href;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.href,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: readStr(json['id']),
        type: readStr(json['type']),
        title: LocalizedText.fromJson(json['title']),
        body: LocalizedText.fromJson(json['body']),
        href: readStr(json['href']),
        read: readBool(json['read']),
        createdAt: readDate(json['createdAt']),
      );

  /// The order this notification opens, when [href] is `/orders/<id>`.
  String? get orderId {
    const prefix = '/orders/';
    if (!href.startsWith(prefix)) return null;
    final id = href.substring(prefix.length).split(RegExp(r'[/?#]')).first;
    return id.isEmpty ? null : id;
  }

  AppNotification markedRead() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        href: href,
        read: true,
        createdAt: createdAt,
      );
}
