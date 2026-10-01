import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pfm/pfm.dart';

void main() {
  testWidgets('debug sizes', (tester) async {
    final dir = Directory.systemTemp.createTempSync('pfm_dbg_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (c) async => dir.path);
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundaryKey = GlobalKey();
    await tester.runAsync(() async => runApp(RepaintBoundary(key: boundaryKey, child: App(dependencies: await DependencyResolver.create()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions').first);
    await tester.pumpAndSettle();

    void show(String name, Finder f) {
      final e = f.evaluate().first;
      final box = e.renderObject as RenderBox;
      // ignore: avoid_print
      print('$name: ${box.size} @ ${box.localToGlobal(Offset.zero)}');
    }
    show('SearchField', find.byType(SearchField));
    show('TextField', find.byType(TextField).first);
    show('AppDropdown', find.byType(AppDropdown<String>));
    show('dropdown Material', find.descendant(of: find.byType(AppDropdown<String>), matching: find.byType(Material)).first);
    show('dropdown InkWell', find.descendant(of: find.byType(AppDropdown<String>), matching: find.byType(InkWell)).first);
    show('Segmented', find.byType(SegmentedButton<bool>));
    show('dropdown Text', find.descendant(of: find.byType(AppDropdown<String>), matching: find.text('All categories')));
    final mat = tester.widget<Material>(find.descendant(of: find.byType(AppDropdown<String>), matching: find.byType(Material)).first);
    // ignore: avoid_print
    print('material shape=${mat.shape} color=${mat.color} type=${mat.type}');
    await tester.runAsync(() async {
      final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('/private/tmp/claude-501/-Users-marchenko-o-brainrocket-com-Projects-other-pfm/75b5b27e-2a66-409e-8efb-8d605565cc1a/scratchpad/header.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.runAsync(() async { await Hive.close(); dir.deleteSync(recursive: true); });
  });
}
