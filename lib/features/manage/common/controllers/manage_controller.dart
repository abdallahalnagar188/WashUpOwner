import 'package:get/get.dart';

import '../../../../core/data/vendor_api.dart';
import '../../../../core/data/vendor_manage_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

/// What every management screen shares: the API, the session and writes that
/// report their outcome.
abstract class ManageController extends GetxController {
  final api = VendorManageApi(Get.find<VendorApi>().client);
  final session = Get.find<SessionService>();

  /// The dashboard keeps these screens' edits to the owner, and no permission
  /// key covers them. The server refuses other roles anyway.
  bool get isOwner => session.account.value?.role == 'owner';

  /// Runs [call] and says how it went. True means the server accepted it, so a
  /// form can close; a refusal leaves it open with the text intact.
  Future<bool> write(
    Future<void> Function() call, {
    Future<void> Function()? reload,
    String? doneText,
  }) async {
    try {
      await call();
      Utils.getSnakBar(message: doneText ?? 'manage.saved'.tr, type: TosterTypes.sucsses);
      await reload?.call();
      return true;
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
      return false;
    }
  }
}

/// One reply shown as a whole page.
abstract class LoadController<T> extends ManageController {
  final data = Rxn<T>();
  final loading = true.obs;
  final error = RxnString();

  int _requestId = 0;

  Future<T> fetch();

  Future<void> load({bool silent = false}) async {
    final id = ++_requestId;
    error.value = null;
    if (!silent) {
      loading.value = true;
      data.value = null;
    }
    try {
      final result = await fetch();
      if (id == _requestId) data.value = result;
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    } finally {
      if (id == _requestId) loading.value = false;
    }
  }
}

/// A paged list, with the same reload and scroll rules as the orders list.
abstract class PagedController<T> extends ManageController {
  final items = <T>[].obs;
  final loading = true.obs;
  final loadingMore = false.obs;
  final error = RxnString();
  final meta = <String, dynamic>{}.obs;

  int _page = 1;
  bool _hasNext = false;
  int _requestId = 0;

  Future<ApiPage<T>> fetchPage(int page);

  Future<void> load({bool silent = false}) async {
    final id = ++_requestId;
    error.value = null;
    if (!silent) {
      loading.value = true;
      items.clear();
    }
    try {
      final page = await fetchPage(1);
      if (id != _requestId) return;
      _page = 1;
      _hasNext = page.hasNext;
      items.assignAll(page.items);
      meta.assignAll(page.meta);
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    } finally {
      if (id == _requestId) loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasNext || loadingMore.value) return;
    final id = _requestId;
    loadingMore.value = true;
    try {
      final page = await fetchPage(_page + 1);
      if (id != _requestId) return;
      _page++;
      _hasNext = page.hasNext;
      items.addAll(page.items);
    } catch (_) {
      // The list stays as it is; scrolling again retries.
    } finally {
      loadingMore.value = false;
    }
  }
}
