import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfm/pfm.dart';

void main() {
  late Directory dir;
  late Directory logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('pfm_log_test_');
    logs = Directory('${dir.path}/logs');
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {}; // silence console
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
    setFileLoggingEnabled(false);
    dir.deleteSync(recursive: true);
  });

  String readSession(File file) => file.readAsStringSync();

  test('writes action, error and stack trace to this session\'s file',
      () async {
    final file = await initSessionLogFile(logs, DateTime(2026, 10, 2, 9, 30),
        enabled: true);

    logError('Import statement', StateError('boom'), StackTrace.current);

    final text = readSession(file);
    expect(text, contains('Import statement'));
    expect(text, contains('Bad state: boom'));
    expect(text, contains('error_logging_test.dart'), reason: 'stack trace');
    expect(RegExp(r'^\[\d{4}-\d\d-\d\dT').hasMatch(text), isTrue,
        reason: 'each entry is timestamped');
  });

  test('one file per launch, named from the launch time', () async {
    final a = await initSessionLogFile(logs, DateTime(2026, 10, 2, 9, 30),
        enabled: true);
    final b = await initSessionLogFile(logs, DateTime(2026, 10, 2, 9, 31),
        enabled: true);
    expect(a.path, isNot(b.path));
    expect(a.path, contains('session_2026-10-02T09-30'));
    expect(a.path, endsWith('.log'));
  });

  test('appends entries and honours the live toggle', () async {
    final file =
        await initSessionLogFile(logs, DateTime(2026, 10, 2), enabled: false);

    logError('while off', 'x');
    expect(file.existsSync(), isFalse,
        reason: 'nothing written while disabled');

    setFileLoggingEnabled(true);
    logError('first', 'x');
    logError('second', 'y');
    setFileLoggingEnabled(false);
    logError('off again', 'z');

    final text = readSession(file);
    expect(text, contains('first'));
    expect(text, contains('second'));
    expect(text, isNot(contains('while off')));
    expect(text, isNot(contains('off again')));
  });

  test('a session that logs nonstop stops at the size cap', () async {
    final file =
        await initSessionLogFile(logs, DateTime(2026, 10, 2), enabled: true);
    file.writeAsBytesSync(List.filled(maxLogBytes, 65));

    logError('too late', 'x');

    expect(file.lengthSync(), maxLogBytes);
  });

  test('old sessions are pruned oldest-first down to the cap', () async {
    logs.createSync(recursive: true);
    final sixMb = List.filled(6 * 1024 * 1024, 65);
    final now = DateTime.now();
    final files = [
      for (var i = 0; i < 3; i++)
        File('${logs.path}/session_old_$i.log')
          ..writeAsBytesSync(sixMb)
          ..setLastModifiedSync(now.subtract(Duration(days: 3 - i))),
    ];

    final current = await initSessionLogFile(logs, now, enabled: true);

    expect(files[0].existsSync(), isFalse, reason: 'oldest');
    expect(files[1].existsSync(), isFalse,
        reason: 'next oldest, still over 10MB');
    expect(files[2].existsSync(), isTrue, reason: '6MB is back under the cap');
    expect(current.parent.path, logs.path);
  });

  test('a bad logs directory means "no file logging", never a crash', () async {
    final blocker = File('${dir.path}/not_a_dir')..writeAsStringSync('x');
    final repo = ErrorLogRepo(logsDirectory: Directory('${blocker.path}/logs'));

    await repo.init(enabled: true); // must not throw
    expect(() => logError('still fine', 'x'), returnsNormally);
  });

  test('ErrorLogRepo toggles the live flag', () async {
    final repo = ErrorLogRepo(logsDirectory: logs);
    await repo.init(enabled: false);
    logError('off', 'x');
    expect(logs.listSync().whereType<File>().every((f) => f.lengthSync() == 0),
        isTrue);

    repo.setEnabled(true);
    logError('on', 'x');
    final written = logs.listSync().whereType<File>().single;
    expect(written.readAsStringSync(), contains('on'));
  });
}
