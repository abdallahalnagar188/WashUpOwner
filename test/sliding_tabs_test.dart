import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/widgets/tabs/sliding_tabs.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String selected = 'a';

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(
          body: SlidingTabs<String>(
            items: const ['a', 'b', 'c'],
            selected: selected,
            label: (item) => 'tab $item',
            onSelect: (item) => setState(() => selected = item),
          ),
        ),
      ),
    );
  }
}

double pillLeft(WidgetTester tester) => tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left!;

void main() {
  testWidgets('the pill sits under the selected tab and slides to the next', (tester) async {
    await tester.pumpWidget(const _Host());
    await tester.pump();
    await tester.pump();

    expect(pillLeft(tester), 0);

    await tester.tap(find.text('tab b'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(pillLeft(tester), greaterThan(0));
  });
}
