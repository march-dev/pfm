import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/pfm.dart';

void main() {
  testWidgets('every input control renders at AppSizes.controlHeight',
      (tester) async {
    final searchKey = GlobalKey();
    final fieldKey = GlobalKey();
    final buttonKey = GlobalKey();
    final iconlessKey = GlobalKey();
    final segmentedKey = GlobalKey();
    final splitKey = GlobalKey();
    final dropdownKey = GlobalKey();
    final monthKey = GlobalKey();
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                SearchField(
                    key: searchKey,
                    value: 'abc',
                    onChanged: (_) {},
                    hintText: 'Search'),
                SizedBox(
                  key: fieldKey,
                  width: 200,
                  child: AppTextField(controller: controller, hintText: 'Name'),
                ),
                PrimaryButton(
                  key: buttonKey,
                  onPressed: () {},
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                  backgroundColor: Colors.teal,
                ),
                PrimaryButton(
                  key: iconlessKey,
                  onPressed: () {},
                  loading: true,
                  icon: const Icon(Icons.check),
                  label: const Text('Saving'),
                  backgroundColor: Colors.teal,
                ),
                AppSegmentedButton<bool>(
                  key: segmentedKey,
                  selected: true,
                  onChanged: (_) {},
                  segments: const [
                    ButtonSegment(value: true, label: Text('This month')),
                    ButtonSegment(value: false, label: Text('All time')),
                  ],
                ),
                SplitButton<int>(
                  key: splitKey,
                  icon: Icons.add,
                  label: 'Add',
                  onPressed: () {},
                  menuItems: const [
                    SplitButtonMenuItem(value: 1, label: 'One')
                  ],
                  onMenuItemSelected: (_) {},
                ),
                AppDropdown<String>(
                  key: dropdownKey,
                  selected: 'a',
                  onChanged: (_) {},
                  items: const [
                    AppDropdownItem(value: 'a', label: 'All categories'),
                    AppDropdownItem(value: 'b', label: 'Groceries'),
                  ],
                ),
                MonthSelector(
                  key: monthKey,
                  month: const YearMonth(2026, 9),
                  months: const [YearMonth(2026, 9)],
                  onSelected: (_) {},
                  onPrevious: () {},
                  onNext: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    double height(GlobalKey key) => tester.getSize(find.byKey(key)).height;

    expect(height(searchKey), AppSizes.controlHeight,
        reason: 'search field (with clear button)');
    expect(height(fieldKey), AppSizes.controlHeight, reason: 'text field');
    expect(height(buttonKey), AppSizes.controlHeight, reason: 'button');
    expect(height(iconlessKey), AppSizes.controlHeight,
        reason: 'loading button');
    expect(height(segmentedKey), AppSizes.controlHeight,
        reason: 'segmented button');
    expect(height(splitKey), AppSizes.controlHeight, reason: 'split button');
    expect(height(dropdownKey), AppSizes.controlHeight, reason: 'dropdown');
    expect(height(monthKey), AppSizes.controlHeight, reason: 'month selector');
    expect(tester.takeException(), isNull);

    // And the dropdown opens its menu in the split button's style.
    await tester.tap(find.byKey(dropdownKey));
    // Not pumpAndSettle: the loading button's spinner animates forever.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget,
        reason: 'the current selection is ticked');
  });
}
