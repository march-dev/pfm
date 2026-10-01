import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/pfm.dart';

void main() {
  paintedOutlineTests();

  testWidgets('every input control renders at AppSizes.controlHeight',
      (tester) async {
    // macOS defaults to VisualDensity.compact, which shrinks Material buttons
    // by 8px unless they opt out; tests otherwise run with the Android
    // default and would never notice.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
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
                    child:
                        AppTextField(controller: controller, hintText: 'Name'),
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
      expect(height(monthKey), AppSizes.controlHeight,
          reason: 'month selector');
      expect(tester.takeException(), isNull);

      // With a minWidth wider than its label, the arrow stays on the right edge.
      final dropdownRect = tester.getRect(find.byKey(dropdownKey));
      final arrowRect = tester.getRect(
        find.descendant(
          of: find.byKey(dropdownKey),
          matching: find.byIcon(CupertinoIcons.chevron_down),
        ),
      );
      expect(
        dropdownRect.right - arrowRect.right,
        AppSizes.spacing10,
        reason: 'arrow is flush with the right padding',
      );

      // And the dropdown opens its menu in the split button's style.
      await tester.tap(find.byKey(dropdownKey));
      // Not pumpAndSettle: the loading button's spinner animates forever.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.checkmark_alt), findsOneWidget,
          reason: 'the current selection is ticked');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

/// Height in logical pixels of the vertical run of [color] found in the
/// column at [x] of a rendered image — i.e. how tall an outlined control
/// really paints, which is not necessarily the size of its widget box.
Future<int> paintedOutlineHeight(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Finder control,
  Color outline,
) async {
  final center = tester.getCenter(control);
  final topLeft = tester.getTopLeft(control);
  final x = (topLeft.dx + 40).round(); // inside the control, clear of corners
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late ByteData data;
  late int width;
  late int imageHeight;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    width = image.width;
    imageHeight = image.height;
    data = (await image.toByteData())!;
  });
  bool isOutline(int y) {
    final i = (y * width + x) * 4;
    return (data.getUint8(i) - (outline.r * 255).round()).abs() < 3 &&
        (data.getUint8(i + 1) - (outline.g * 255).round()).abs() < 3 &&
        (data.getUint8(i + 2) - (outline.b * 255).round()).abs() < 3;
  }

  final from = (center.dy - 40).round().clamp(0, imageHeight - 1);
  final to = (center.dy + 40).round().clamp(0, imageHeight - 1);
  int? first;
  int? last;
  for (var y = from; y <= to; y++) {
    if (isOutline(y)) {
      first ??= y;
      last = y;
    }
  }
  return first == null ? 0 : last! - first + 1;
}

void paintedOutlineTests() {
  testWidgets('outlined fields paint a full-height outline on macOS',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final boundary = GlobalKey();
      final search = GlobalKey();
      final field = GlobalKey();
      final dropdown = GlobalKey();
      final controller = TextEditingController();
      tester.view.physicalSize = const Size(900, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchField(
                      key: search,
                      value: '',
                      onChanged: (_) {},
                      hintText: 'Search',
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      key: field,
                      width: 200,
                      child: AppTextField(
                          controller: controller, hintText: 'Name'),
                    ),
                    const SizedBox(width: 20),
                    AppDropdown<String>(
                      key: dropdown,
                      selected: 'a',
                      onChanged: (_) {},
                      items: const [
                        AppDropdownItem(value: 'a', label: 'All categories'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      const outline = AppColors.neutralContainer;
      for (final entry in {
        'search field': search,
        'text field': field,
        'dropdown': dropdown,
      }.entries) {
        expect(
          await paintedOutlineHeight(
              tester, boundary, find.byKey(entry.value), outline),
          AppSizes.controlHeight.round(),
          reason: '${entry.key} outline',
        );
      }
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
