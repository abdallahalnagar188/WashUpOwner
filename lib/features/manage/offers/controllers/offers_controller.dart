import 'package:get/get.dart';

import '../../../../commons/models/offer.dart';
import '../../common/controllers/manage_controller.dart';

class OffersController extends LoadController<OfferList> {
  static const String allStatuses = 'all';

  final status = allStatuses.obs;
  final toggling = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  /// All offers at once, as the dashboard does; the chips filter them here.
  @override
  Future<OfferList> fetch() => api.offers(branchId: session.branchId.value);

  List<Offer> get visible {
    final items = data.value?.items ?? const <Offer>[];
    final shown = status.value == allStatuses
        ? [...items]
        : items.where((offer) => offer.status == status.value).toList();
    int rank(Offer offer) {
      final index = Offer.statuses.indexOf(offer.status);
      return index < 0 ? Offer.statuses.length : index;
    }

    shown.sort((a, b) => rank(a).compareTo(rank(b)));
    return shown;
  }

  Future<bool> save({String? id, required Map<String, dynamic> payload}) => write(
        () => api.saveOffer(id: id, payload: payload),
        reload: () => load(silent: true),
      );

  Future<void> setEnabled(Offer offer, bool enabled) async {
    if (!toggling.add(offer.id)) return;
    await write(
      () => api.setOfferEnabled(offer.id, enabled),
      reload: () => load(silent: true),
    );
    toggling.remove(offer.id);
  }
}
