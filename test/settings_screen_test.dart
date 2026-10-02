import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/pfm.dart';
import 'package:provider/provider.dart';

class _MemorySettings implements AppSettingsRepo {
  _MemorySettings({this.loggingEnabled = true});

  bool loggingEnabled;

  @override
  bool getFileLoggingEnabled() => loggingEnabled;

  @override
  Future<void> setFileLoggingEnabled(bool value) async =>
      loggingEnabled = value;
}

class _RecordingFileManager implements FileManagerRepo {
  final revealed = <String>[];

  @override
  Future<void> reveal(String path) async => revealed.add(path);
}

void main() {
  late Directory dir;
  late Directory logs;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pfm_settings_test_');
    logs = Directory('${dir.path}/logs');
  });

  tearDown(() {
    setFileLoggingEnabled(false);
    dir.deleteSync(recursive: true);
  });

  Future<
      ({
        _MemorySettings settings,
        _RecordingFileManager fileManager,
        ErrorLogRepo errorLog,
      })> pumpSettings(
    WidgetTester tester, {
    bool loggingEnabled = true,
  }) async {
    final settings = _MemorySettings(loggingEnabled: loggingEnabled);
    final fileManager = _RecordingFileManager();
    final errorLog = ErrorLogRepo(logsDirectory: logs);
    await tester.runAsync(
      () => errorLog.init(enabled: settings.getFileLoggingEnabled()),
    );

    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => AppSettingsUseCases(settings)),
          Provider(create: (_) => ErrorLogUseCases(errorLog)),
          Provider(create: (_) => FileManagerUseCases(fileManager)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (settings: settings, fileManager: fileManager, errorLog: errorLog);
  }

  File? sessionFile() =>
      logs.existsSync() ? logs.listSync().whereType<File>().firstOrNull : null;

  testWidgets('shows the Error Logs card, on by default', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Error Logs'), findsOneWidget);
    expect(
        find.textContaining('Nothing is ever sent anywhere'), findsOneWidget);
    expect(find.text('Open Logs Folder'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reflects a saved "off" preference', (tester) async {
    await pumpSettings(tester, loggingEnabled: false);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('the switch is 32px tall like the other header controls',
      (tester) async {
    await pumpSettings(tester);
    expect(
        tester.getSize(find.byType(AppSwitch)).height, AppSizes.controlHeight);
  });

  testWidgets('toggling saves the preference and takes effect immediately',
      (tester) async {
    final env = await pumpSettings(tester);

    logError('before', 'x');
    expect(sessionFile()!.readAsStringSync(), contains('before'));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(env.settings.loggingEnabled, isFalse, reason: 'persisted');
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    logError('while off', 'x');
    expect(sessionFile()!.readAsStringSync(), isNot(contains('while off')),
        reason: 'live flag flipped, no restart needed');

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(env.settings.loggingEnabled, isTrue);
    logError('after', 'x');
    expect(sessionFile()!.readAsStringSync(), contains('after'));
  });

  testWidgets('Open Logs Folder reveals the logs directory', (tester) async {
    final env = await pumpSettings(tester);

    await tester.tap(find.text('Open Logs Folder'));
    await tester.pumpAndSettle();

    expect(env.fileManager.revealed, [logs.path]);
  });
}
