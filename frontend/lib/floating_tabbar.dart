import 'package:flutter/material.dart';

/// Accessible, controlled section navigation used inside detail and calendar
/// pages. A wrapping chip group keeps every label visible at large text sizes
/// instead of hiding tabs in a horizontal scroller.
class FloatingTabBar extends StatelessWidget {
  final List<String> titles;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FloatingTabBar({
    super.key,
    required this.titles,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(selectedIndex >= 0 && selectedIndex < titles.length);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(titles.length, (index) {
            return ChoiceChip(
              key: ValueKey<String>('section-tab-$index'),
              selected: selectedIndex == index,
              showCheckmark: false,
              label: Text(titles[index]),
              onSelected: (_) => onSelected(index),
            );
          }),
        ),
      ),
    );
  }
}
