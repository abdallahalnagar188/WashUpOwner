import 'package:get/get.dart';

import '../../../../commons/models/review.dart';
import '../../../../core/network/api_client.dart';
import '../../common/controllers/manage_controller.dart';

class ReviewsController extends PagedController<Review> {
  ReviewStats get stats => ReviewStats.fromMeta(meta);

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<ApiPage<Review>> fetchPage(int page) =>
      api.reviews(branchId: session.branchId.value, page: page);

  Future<bool> reply(Review review, String text) => write(
        () => api.replyToReview(review.id, text),
        reload: () => load(silent: true),
      );

  Future<bool> report(Review review, String reason) => write(
        () => api.reportReview(review.id, reason),
        reload: () => load(silent: true),
      );
}
