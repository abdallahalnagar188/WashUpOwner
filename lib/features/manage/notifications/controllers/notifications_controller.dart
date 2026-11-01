import 'dart:math';

import 'package:get/get.dart';

import '../../../../commons/models/app_notification.dart';
import '../../../../commons/models/json_read.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/utils.dart';
import '../../common/controllers/manage_controller.dart';

class NotificationsController extends PagedController<AppNotification> {
  static const List<String> filters = ['all', 'unread'];

  final filter = filters.first.obs;
  final markingAll = false.obs;

  int get unread => readInt(meta['unread']);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<ApiPage<AppNotification>> fetchPage(int page) =>
      api.notifications(filter: filter.value, page: page);

  void selectFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    load();
  }

  /// Marks it read without waiting, then opens its order if it has one.
  Future<void> open(AppNotification item) async {
    if (!item.read) {
      final index = items.indexWhere((n) => n.id == item.id);
      if (index >= 0) items[index] = item.markedRead();
      meta['unread'] = max(0, unread - 1);
      api.markNotificationRead(item.id).catchError((_) {
        // Still unread on the server; the next load shows that.
      });
    }
    final orderId = item.orderId;
    if (orderId != null) await Get.toNamed(Routes.orderRoute, arguments: orderId);
  }

  Future<void> readAll() async {
    if (markingAll.value) return;
    markingAll.value = true;
    try {
      await api.markAllNotificationsRead();
      await load(silent: true);
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
    } finally {
      markingAll.value = false;
    }
  }
}
