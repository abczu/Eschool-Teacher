import 'package:eschool_saas_staff/ui/widgets/system/customTextContainer.dart';
import 'package:flutter/material.dart';

class FilterSelectionTile extends StatelessWidget {
  final bool isSelected;
  final String title;
  final VoidCallback onTap;

  const FilterSelectionTile({
    super.key,
    required this.onTap,
    required this.isSelected,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: CustomTextContainer(
                textKey: title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(width: 15),
            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 1.5,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              child: isSelected
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
