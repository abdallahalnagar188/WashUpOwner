import 'json_read.dart';
import 'localized_text.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String segment;
  final int visits;
  final num totalSpent;
  final List<String> plates;
  final LocalizedText favoriteService;
  final DateTime? firstVisitAt;
  final DateTime? lastVisitAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.segment,
    required this.visits,
    required this.totalSpent,
    required this.plates,
    required this.favoriteService,
    required this.firstVisitAt,
    required this.lastVisitAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: readStr(json['id']),
        name: readStr(json['name']),
        phone: readStr(json['phone']),
        segment: readStr(json['segment']),
        visits: readInt(json['visits']),
        totalSpent: readNum(json['totalSpent']),
        plates: readStrings(json['plates']),
        favoriteService: LocalizedText.fromJson(json['favoriteService']),
        firstVisitAt: readDate(json['firstVisitAt']),
        lastVisitAt: readDate(json['lastVisitAt']),
      );
}

class CustomerVehicle {
  final String id;
  final String plate;
  final String make;
  final String model;
  final int? year;
  final String color;

  const CustomerVehicle({
    required this.id,
    required this.plate,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
  });

  String get label => [make, model, if (year != null) '$year'].where((p) => p.isNotEmpty).join(' ');

  factory CustomerVehicle.fromJson(Map<String, dynamic> json) => CustomerVehicle(
        id: readStr(json['id']),
        plate: readStr(json['plate']),
        make: readStr(json['make']),
        model: readStr(json['model']),
        year: readNumOrNull(json['year'])?.toInt(),
        color: readStr(json['color']),
      );
}

class CustomerOrder {
  final String id;
  final String number;
  final String plate;
  final String status;
  final String paymentStatus;
  final num total;
  final LocalizedText serviceName;
  final LocalizedText branchName;
  final DateTime? scheduledAt;

  const CustomerOrder({
    required this.id,
    required this.number,
    required this.plate,
    required this.status,
    required this.paymentStatus,
    required this.total,
    required this.serviceName,
    required this.branchName,
    required this.scheduledAt,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
        id: readStr(json['id']),
        number: readStr(json['number']),
        plate: readStr(json['plate']),
        status: readStr(json['status']),
        paymentStatus: readStr(json['paymentStatus']),
        total: readNum(json['total']),
        serviceName: LocalizedText.fromJson(json['serviceName']),
        branchName: LocalizedText.fromJson(json['branchName']),
        scheduledAt: readDate(json['scheduledAt']),
      );
}

class CustomerReview {
  final String id;
  final int stars;
  final LocalizedText comment;
  final String? reply;
  final DateTime? createdAt;

  const CustomerReview({
    required this.id,
    required this.stars,
    required this.comment,
    required this.reply,
    required this.createdAt,
  });

  factory CustomerReview.fromJson(Map<String, dynamic> json) => CustomerReview(
        id: readStr(json['id']),
        stars: readInt(json['stars']),
        comment: LocalizedText.fromJson(json['comment']),
        reply: readStrOrNull(json['reply']),
        createdAt: readDate(json['createdAt']),
      );
}

class FavoriteService {
  final LocalizedText name;
  final int count;

  const FavoriteService({required this.name, required this.count});

  factory FavoriteService.fromJson(Map<String, dynamic> json) => FavoriteService(
        name: LocalizedText.fromJson(json['name']),
        count: readInt(json['count']),
      );
}

class CustomerDetails {
  final String id;
  final String name;
  final String phone;
  final String status;
  final String segment;
  final int visits;
  final num totalSpent;
  final num avgTicket;
  final int cancellations;
  final int noShows;
  final List<CustomerVehicle> vehicles;
  final List<CustomerOrder> orders;
  final List<CustomerReview> reviews;
  final List<FavoriteService> favoriteServices;

  const CustomerDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.segment,
    required this.visits,
    required this.totalSpent,
    required this.avgTicket,
    required this.cancellations,
    required this.noShows,
    required this.vehicles,
    required this.orders,
    required this.reviews,
    required this.favoriteServices,
  });

  factory CustomerDetails.fromJson(Map<String, dynamic> json) {
    final customer = readMap(json['customer']);
    final stats = readMap(json['stats']);
    return CustomerDetails(
      id: readStr(customer['id']),
      name: readStr(customer['name']),
      phone: readStr(customer['phone']),
      status: readStr(customer['status']),
      segment: readStr(stats['segment']),
      visits: readInt(stats['visits']),
      totalSpent: readNum(stats['totalSpent']),
      avgTicket: readNum(stats['avgTicket']),
      cancellations: readInt(stats['cancellations']),
      noShows: readInt(stats['noShows']),
      vehicles: readMaps(json['vehicles']).map(CustomerVehicle.fromJson).toList(),
      orders: readMaps(json['orders']).map(CustomerOrder.fromJson).toList(),
      reviews: readMaps(json['reviews']).map(CustomerReview.fromJson).toList(),
      favoriteServices: readMaps(json['favoriteServices']).map(FavoriteService.fromJson).toList(),
    );
  }
}
