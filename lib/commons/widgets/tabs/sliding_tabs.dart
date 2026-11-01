import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import 'pill_label_shader.dart';

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

class _SlidingTabsState<T> extends State<SlidingTabs<T>> with SingleTickerProviderStateMixin {
  final Map<T, GlobalKey> _keys = {};
  final GlobalKey _stackKey = GlobalKey();
  final RectTween _pill = RectTween();
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _progress = CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic);
  bool _scrollToSelected = false;

  GlobalKey _keyFor(T item) => _keys.putIfAbsent(item, GlobalKey.new);

  @override
  void didUpdateWidget(SlidingTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _scrollToSelected = true;
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _movePill(Rect rect) {
    if (rect == _pill.end) return;
    _pill
      ..begin = _pill.evaluate(_progress) ?? rect
      ..end = rect;
    _slide.forward(from: 0);
  }

  /// Runs after every build, because any build can change a label's width and
  /// with it where the tabs sit.
  void _measureAfterLayout(Duration _) {
    if (!mounted) return;
    final tabContext = _keyFor(widget.selected).currentContext;
    final tab = tabContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (tabContext == null || tab == null || stack == null) return;
    _movePill(tab.localToGlobal(Offset.zero, ancestor: stack) & tab.size);
    if (_scrollToSelected) {
      _scrollToSelected = false;
      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium ?? const TextStyle();
    WidgetsBinding.instance.addPostFrameCallback(_measureAfterLayout);
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
        child: AnimatedBuilder(
          animation: _progress,
          child: Row(
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
                    child: Text(widget.label(item), style: style.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          builder: (context, labels) {
            final pill = _pill.evaluate(_progress);
            return Stack(
              key: _stackKey,
              children: [
                if (pill != null)
                  Positioned.fromRect(
                    rect: pill,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => pillLabelShader(
                    bounds,
                    left: pill?.left ?? 0,
                    right: pill?.right ?? 0,
                    inside: Colors.white,
                    outside: AppColors.primary,
                  ),
                  child: labels,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
