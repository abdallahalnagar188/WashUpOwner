import '../../../../commons/models/business_settings.dart';
import '../../common/controllers/manage_controller.dart';

class SettingsController extends LoadController<BusinessSettings> {
  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<BusinessSettings> fetch() => api.settings();

  Future<bool> saveBusiness({
    required String nameAr,
    required String nameEn,
    required String phone,
    required String email,
    required String reason,
  }) =>
      write(
        () => api.saveBusinessDetails(
          nameAr: nameAr,
          nameEn: nameEn,
          phone: phone,
          email: email,
          reason: reason,
        ),
        reload: () => load(silent: true),
      );

  Future<bool> saveManagerEdits(bool value, String reason) => write(
        () => api.saveManagerCanEditServices(value, reason: reason),
        reload: () => load(silent: true),
      );

  Future<bool> savePrefs(Map<String, bool> prefs, String reason) => write(
        () => api.saveNotificationPrefs(prefs, reason: reason),
        reload: () => load(silent: true),
      );
}
