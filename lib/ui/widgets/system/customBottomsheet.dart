import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:eschool_saas_staff/utils/system/constants.dart';
import 'package:flutter/material.dart';

class CustomBottomsheet extends StatelessWidget {
  final Widget child;
  final String titleLabelKey;
  final Color? backgroundColor;

  const CustomBottomsheet(
      {super.key, required this.child, this.titleLabelKey = '', this.backgroundColor});

  Widget _buildContent({required BuildContext context}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 5,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.5)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
              vertical: 15, horizontal: appContentHorizontalPadding),
          child: CustomTextContainer(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textKey: titleLabelKey,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          width: double.maxFinite,
          height: 1,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        Flexible(child: SingleChildScrollView(child: child))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * (0.85)),
      padding:
          EdgeInsets.symmetric(vertical: appContentHorizontalPadding * (1.25)),
      decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(bottomsheetBorderRadius),
              topRight: Radius.circular(bottomsheetBorderRadius))),
      child: _buildContent(context: context),
    );
  }
}
