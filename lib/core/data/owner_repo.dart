import '../../commons/models/dashboard_summary.dart';
import '../../commons/models/live_board.dart';
import '../../commons/models/owner_account.dart';
import '../enums/enums.dart';

/// [messageKey] is a translation key.
class OwnerRepoException implements Exception {
  final String messageKey;

  const OwnerRepoException(this.messageKey);
}

/// Everything the screens need from the backend. The mock version lives in
/// mock_owner_repo.dart; the API version implements this same interface on
/// `/api/v1/vendor/*`.
abstract class OwnerRepo {
  Future<OwnerAccount> signIn({required String identifier, required String password});

  Future<OwnerAccount> me();

  Future<void> signOut();

  Future<DashboardSummary> dashboard({required DashboardPeriod period, String branchId = 'all'});

  Future<LiveBoard> live({String branchId = 'all'});

  Future<LiveBoard> runAction({
    required String orderId,
    required LiveAction action,
    String branchId = 'all',
  });
}
