import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:washup_owner/core/utils/poller.dart';
import 'package:washup_owner/core/utils/workers.dart';

class _Counter extends GetxController with DisposesWorkers {
  final value = 0.obs;
  int seen = 0;

  @override
  void onInit() {
    super.onInit();
    keep(ever(value, (_) => seen++));
  }
}

void main() {
  testWidgets('polls every period only while started and in the foreground (GAP-099)', (tester) async {
    var ticks = 0;
    final poller = Poller(const Duration(seconds: 30), () => ticks++);

    poller.start();
    // Whatever state the test binding starts in, the app is in front now.
    poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 61));
    expect(ticks, 2);

    poller.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(poller.isTicking, isFalse);
    await tester.pump(const Duration(seconds: 90));
    expect(ticks, 2, reason: 'no calls in the background');

    poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(poller.isTicking, isTrue);
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 3);

    poller.stop();
    await tester.pump(const Duration(seconds: 60));
    expect(ticks, 3);
    poller.dispose();
  });

  testWidgets('a poller that asks for it ticks once on resume', (tester) async {
    var ticks = 0;
    final poller = Poller(const Duration(seconds: 30), () => ticks++, tickOnResume: true);
    poller.start();
    poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    ticks = 0;
    poller.didChangeAppLifecycleState(AppLifecycleState.paused);
    poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(ticks, 1);
    poller.dispose();
  });

  test('workers end with their controller (GAP-098)', () async {
    final controller = Get.put(_Counter());
    controller.value.value = 1;
    await Future<void>.delayed(Duration.zero);
    expect(controller.seen, 1);
    Get.delete<_Counter>();
    controller.value.value = 2;
    await Future<void>.delayed(Duration.zero);
    expect(controller.seen, 1);
  });
}
