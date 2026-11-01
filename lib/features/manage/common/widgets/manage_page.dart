import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';

class ManageBackButton extends StatelessWidget {
  const ManageBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return HeaderButton(
      icon: Directionality.of(context) == TextDirection.rtl ? Iconsax.arrow_right_3 : Iconsax.arrow_left_2,
      onTap: Get.back,
    );
  }
}

/// Header with a back button over the screen's content.
class ManagePage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? headerChild;
  final Widget body;

  const ManagePage({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.headerChild,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BrandHeader(
            title: title,
            subtitle: subtitle,
            leading: const ManageBackButton(),
            trailing: trailing,
            child: headerChild,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Shows [content] once it exists, otherwise loading or the failure. A plain
/// function so everything [content] reads counts for the surrounding Obx.
Widget manageLoader({
  required bool ready,
  required String? error,
  required VoidCallback onRetry,
  required Widget Function() content,
}) {
  if (ready) return content();
  if (error != null) return AppErrorState(message: error, onRetry: onRetry);
  return const AppShimmerList();
}

/// Pull to refresh over a screen of sections. A plain column rather than a
/// list, so a form scrolled out of view keeps what was typed into it.
class ManageScroll extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ManageScroll({super.key, required this.onRefresh, required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: padding ?? EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 40 * i.clamp(0, 6)),
                child: children[i],
              ),
          ],
        ),
      ),
    );
  }
}

/// A list that asks for more as the end nears.
class ManageList extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final bool loadingMore;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IconData emptyIcon;
  final String emptyTitle;

  /// Scrolls with the list, and stays when the list is empty.
  final Widget? header;

  const ManageList({
    super.key,
    required this.onRefresh,
    this.onLoadMore,
    this.loadingMore = false,
    required this.itemCount,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final lead = header == null ? 0 : 1;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: itemCount == 0
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (header != null)
                  Padding(padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0), child: header),
                SizedBox(
                  height: 300.h,
                  child: CustomEmptyState(icon: emptyIcon, title: emptyTitle),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 300) onLoadMore?.call();
                return false;
              },
              child: ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                itemCount: lead + itemCount + (loadingMore ? 1 : 0),
                itemBuilder: (context, position) {
                  if (position < lead) return header!;
                  final index = position - lead;
                  if (index == itemCount) {
                    return Padding(
                      padding: EdgeInsets.all(12.r),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }
                  return FadeSlideIn(
                    key: ValueKey(index),
                    delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: itemBuilder(context, index),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/// Filter chips that scroll sideways under the header.
class ChipBar<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  const ChipBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) SizedBox(width: 8.w),
            AppChip(
              label: label(values[i]),
              selected: values[i] == selected,
              onTap: () => onSelect(values[i]),
            ),
          ],
        ],
      ),
    );
  }
}
