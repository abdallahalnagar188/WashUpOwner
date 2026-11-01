import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/review.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../common/widgets/manage_sheets.dart';

/// One reply per review, public and final, as the dashboard warns.
class ReviewReplySheet extends StatefulWidget {
  final Review review;
  final Future<bool> Function(String text) onSubmit;

  const ReviewReplySheet({super.key, required this.review, required this.onSubmit});

  @override
  State<ReviewReplySheet> createState() => _ReviewReplySheetState();
}

class _ReviewReplySheetState extends State<ReviewReplySheet> {
  static const int _min = 5;
  static const int _max = 400;

  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String get _text => _input.text.trim();

  @override
  Widget build(BuildContext context) {
    final length = _text.length;
    return SheetBody(
      title: 'reviews.replyTo'.trParams({'name': widget.review.customerName}),
      subtitle: 'reviews.replyBody'.tr,
      children: [
        AppTextField(
          controller: _input,
          maxLines: 4,
          maxLength: _max,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        6.height,
        Text('$length / $_max', style: Theme.of(context).textTheme.labelSmall),
        16.height,
        SubmitButton(
          title: 'reviews.reply'.tr,
          onSubmit: length >= _min && length <= _max ? () => widget.onSubmit(_text) : null,
        ),
      ],
    );
  }
}
