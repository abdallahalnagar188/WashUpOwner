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

double pillLeft(WidgetTester tester) => tester
    .widget<Positioned>(find.descendant(of: find.byType(SlidingTabs<String>), matching: find.byType(Positioned)))
    .left!;

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
  testWidgets('the pill stays under its tab when a label grows without a new widget', (tester) async {
    var name = 'a';
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SlidingTabs<String>(
                items: const ['a', 'b'],
                selected: 'a',
                label: (item) => item == 'a' ? name : 'b',
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    name = 'a much longer label (4)';
    tester.element(find.byType(SlidingTabs<String>)).markNeedsBuild();
    await tester.pumpAndSettle();

    final tab = tester.getRect(
      find.ancestor(of: find.text(name), matching: find.byType(GestureDetector)).first,
    );
    final pill = tester.getRect(
      find.descendant(of: find.byType(SlidingTabs<String>), matching: find.byType(Positioned)),
    );
    expect(pill, tab);
  });
}
