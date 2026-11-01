import '../../../../commons/models/owner_account.dart';
import '../../../../commons/models/shift.dart';
import '../../common/controllers/manage_controller.dart';

class ShiftDetailsController extends LoadController<ShiftDetails> {
  final String shiftId;

  ShiftDetailsController(this.shiftId);

  bool get canReview => session.can(OwnerPermission.closeShift);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<ShiftDetails> fetch() => api.shift(shiftId);

  Future<bool> review({required String status, required String note}) => write(
        () => api.reviewShift(shiftId, status: status, note: note),
        reload: () => load(silent: true),
      );
}
