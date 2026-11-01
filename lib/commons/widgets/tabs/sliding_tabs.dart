import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';

/// Scrollable tabs on a soft track, with one pill that slides to the selected
/// tab. The selected tab scrolls to the middle when it was partly hidden.
class SlidingTabs<T> extends StatefulWidget {
  final List<T> items;
  final T selected;
  final String Function(T item) label;
  final ValueChanged<T> onSelect;
  final EdgeInsetsGeometry? padding;

  const SlidingTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.padding,
  });

  @override
  State<SlidingTabs<T>> createState() => _SlidingTabsState<T>();
}

class _SlidingTabsState<T> extends State<SlidingTabs<T>> {
  final Map<T, GlobalKey> _keys = {};
  final GlobalKey _stackKey = GlobalKey();
  Rect? _pill;

  GlobalKey _keyFor(T item) => _keys.putIfAbsent(item, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _measureAfterLayout(scroll: false);
  }

  @override
  void didUpdateWidget(SlidingTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Counts change the labels' width, so the pill is measured on every update.
    _measureAfterLayout(scroll: oldWidget.selected != widget.selected);
  }

  void _measureAfterLayout({required bool scroll}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _keyFor(widget.selected).currentContext;
      final tab = tabContext?.findRenderObject() as RenderBox?;
      final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (tabContext == null || tab == null || stack == null) return;
      final rect = tab.localToGlobal(Offset.zero, ancestor: stack) & tab.size;
      if (rect != _pill) setState(() => _pill = rect);
      if (scroll) {
        Scrollable.ensureVisible(
          tabContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium ?? const TextStyle();
    final pill = _pill;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Stack(
          key: _stackKey,
          children: [
            if (pill != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: pill.left,
                top: pill.top,
                width: pill.width,
                height: pill.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in widget.items)
                  GestureDetector(
                    key: _keyFor(item),
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (item == widget.selected) return;
                      HapticFeedback.selectionClick();
                      widget.onSelect(item);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: style.copyWith(
                          color: item == widget.selected ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        child: Text(widget.label(item)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
