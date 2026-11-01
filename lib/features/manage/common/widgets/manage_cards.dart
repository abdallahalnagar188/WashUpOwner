import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/localized_text.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_number.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

/// Falls back to the other language: the server often has only the Arabic of a
/// comment, an address or a name.
extension LocalizedShown on LocalizedText {
  String get shown {
    if (value.isNotEmpty) return value;
    return ar.isNotEmpty ? ar : en;
  }
}

/// [key] when it is translated, otherwise what the server sent.
String labelOr(String key, String fallback) {
  final text = key.tr;
  return text == key ? fallback : text;
}

/// A day as the API writes it, in local time.
String apiDate(DateTime at) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${at.year}-${two(at.month)}-${two(at.day)}';
}

/// One number with its label.
class StatTile extends StatelessWidget {
  final String label;
  final num value;
  final String Function(num)? format;
  final IconData? icon;
  final Color? color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.format,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RoundedContainer(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20.r, color: color ?? AppColors.primary),
            8.height,
          ],
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          4.height,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedNumber(
              value: value,
              format: format ?? FormatHelper.number,
              style: text.titleLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiles in rows of [perRow], each row as tall as its tallest tile.
class TileGrid extends StatelessWidget {
  final List<Widget> tiles;
  final int perRow;

  const TileGrid({super.key, required this.tiles, this.perRow = 2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var start = 0; start < tiles.length; start += perRow) ...[
          if (start > 0) 10.height,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < start + perRow; i++) ...[
                  if (i > start) 10.width,
                  Expanded(child: i < tiles.length ? tiles[i] : const SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const InfoRow(this.label, this.value, {super.key, this.strong = false});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: strong ? text.titleSmall : text.bodySmall),
          12.width,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: strong ? text.titleSmall : text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled card, for the blocks of a details screen.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget? action;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, this.action, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: RoundedContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
                if (action != null) action!,
              ],
            ),
            10.height,
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A plain note on a screen, such as why it is read-only.
class NoticeCard extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;

  const NoticeCard({super.key, required this.text, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final tone = color ?? AppColors.info;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: RoundedContainer(
        color: AppColors.tint(tone),
        borderColor: Colors.transparent,
        shadow: false,
        padding: EdgeInsets.all(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18.r, color: tone),
            8.width,
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tone)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text that stays left to right inside Arabic, for phones and times.
class LtrText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LtrText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Text(text, textDirection: TextDirection.ltr, style: style);
}
