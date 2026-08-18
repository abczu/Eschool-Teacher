import 'package:eschool_saas_staff/ui/widgets/system/customBottomsheet.dart';
import 'package:eschool_saas_staff/ui/widgets/system/filterSelectionTile.dart';
import 'package:eschool_saas_staff/utils/system/labelKeys.dart';
import 'package:eschool_saas_staff/utils/system/utils.dart';
import 'package:flutter/material.dart';

class FilterSelectionBottomsheet<T> extends StatefulWidget {
  final List<T> values;
  final Function(T? value) onSelection;
  final T? selectedValue;
  final String titleKey;
  final bool showFilterByLabel;
  final String Function(T)? displayFunction;

  const FilterSelectionBottomsheet({
    super.key,
    required this.onSelection,
    required this.selectedValue,
    required this.titleKey,
    required this.values,
    this.showFilterByLabel = true,
    this.displayFunction,
  });

  @override
  State<FilterSelectionBottomsheet<T>> createState() =>
      _FilterSelectionBottomsheetState<T>();
}

class _FilterSelectionBottomsheetState<T>
    extends State<FilterSelectionBottomsheet<T>> {
  T? _localSelectedValue;

  @override
  void initState() {
    super.initState();
    _localSelectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomsheet(
      titleLabelKey:
          "${widget.showFilterByLabel ? '${Utils.getTranslatedLabel(filterByKey)} : ' : ''}${Utils.getTranslatedLabel(widget.titleKey)}",
      child: Column(
        children: [
          // Create list with Divider between each item
          ...widget.values.asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value;

            return Column(
              children: [
                FilterSelectionTile(
                  onTap: () {
                    if (value != null) {
                      setState(() {
                        _localSelectedValue = value;
                      });
                      widget.onSelection.call(value);
                    }
                  },
                  isSelected: _localSelectedValue != null && value == _localSelectedValue,
                  title: widget.displayFunction != null
                      ? Utils().cleanClassName(widget.displayFunction!(value))
                      : Utils().cleanClassName(value.toString()),
                ),
                // Add Divider if not the last item
                if (index < widget.values.length - 1)
                  Divider(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.08),
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
