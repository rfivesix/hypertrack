import 'package:flutter/material.dart';
import '../../util/design_constants.dart';

/// A reusable global Chip-based horizontal filter for selecting timeframes.
class TimeRangeFilter extends StatelessWidget {
  const TimeRangeFilter({
    super.key,
    required this.ranges,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> ranges;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.cardPaddingInternal,
        ),
        child: Row(
          children: List.generate(ranges.length, (index) {
            final range = ranges[index];
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(range),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onSelected(index);
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
