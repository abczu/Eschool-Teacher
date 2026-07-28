import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionTile.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class FilterSelectionBottomsheet<T> extends StatelessWidget {
  final List<T> values;
  final Function(T? value) onSelection;
  final T? selectedValue;
  final String titleKey;
  final bool showFilterByLabel;
  final String Function(T)? displayFunction;
  const FilterSelectionBottomsheet(
      {super.key,
      required this.onSelection,
      required this.selectedValue,
      required this.titleKey,
      required this.values,
      this.showFilterByLabel = true,
      this.displayFunction});

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey:
          "${showFilterByLabel ? '${Utils.getTranslatedLabel(filterByKey)} : ' : ''}${Utils.getTranslatedLabel(titleKey)}",
      child: Column(
        children: [
          // Create list with Divider between each item
          ...values.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;

            return Column(
              children: [
                FilterSelectionTile(
                  onTap: () {
                    if (value != null) {
                      onSelection.call(value);
                    }
                  },
                  isSelected: selectedValue != null && value == selectedValue,
                  title: displayFunction != null
                      ? Utils().cleanClassName(displayFunction!(value))
                      : Utils().cleanClassName(value.toString()),
                ),
                // Add Divider if not the last item
                if (index < values.length - 1)
                  Divider(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    thickness: 1,
                    height: 1,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
