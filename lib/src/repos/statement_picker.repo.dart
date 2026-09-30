import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedStatement {
  const PickedStatement({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Asks the user for a statement file. Bytes are read by the picker itself
/// (rather than handing back a path to open afterwards), which is what
/// makes this work inside the macOS sandbox, where only the picker holds
/// access to the chosen file.
class StatementPickerRepo {
  const StatementPickerRepo();

  /// Null when the user cancels.
  Future<PickedStatement?> pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return PickedStatement(name: file.name, bytes: bytes);
  }
}
