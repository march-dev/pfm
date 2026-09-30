import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class XlsxFormatException implements Exception {
  const XlsxFormatException(this.message);

  final String message;

  @override
  String toString() => 'XlsxFormatException: $message';
}

/// Reads the cell text of an .xlsx workbook's first sheet.
///
/// An .xlsx is just a zip of XML parts, and a bank statement needs nothing
/// beyond "give me the rows as text" — so this reads those parts directly
/// instead of pulling in a full spreadsheet library (whose strictness with
/// non-Excel producers, like the Java exporter behind Santander's files, is
/// a known source of load failures).
class XlsxReader {
  const XlsxReader();

  /// Rows of the first sheet, each a dense list of cell text (empty string
  /// for a blank cell), padded to that row's last non-blank column.
  List<List<String>> readFirstSheet(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const XlsxFormatException('Not a valid .xlsx (zip) file.');
    }

    final sheetFile = archive.findFile(_firstSheetPath(archive));
    if (sheetFile == null) {
      throw const XlsxFormatException('The workbook has no worksheet.');
    }

    final sharedStrings = _readSharedStrings(archive);
    final XmlDocument sheet;
    try {
      sheet = XmlDocument.parse(_text(sheetFile));
    } on XmlException {
      throw const XlsxFormatException('The worksheet XML is malformed.');
    }

    final rows = <int, Map<int, String>>{};
    for (final row in sheet.findAllElements('row')) {
      final rowIndex = int.tryParse(row.getAttribute('r') ?? '');
      if (rowIndex == null) continue;
      for (final cell in row.findElements('c')) {
        final column = _columnIndex(cell.getAttribute('r') ?? '');
        final text = _cellText(cell, sharedStrings);
        if (column == null || text.isEmpty) continue;
        (rows[rowIndex] ??= {})[column] = text;
      }
    }

    final ordered = rows.keys.toList()..sort();
    // Row numbers are kept as positions (blank rows stay blank) so callers
    // can talk about "row 8" the way the spreadsheet itself does.
    final maxRow = ordered.isEmpty ? 0 : ordered.last;
    return [
      for (var r = 1; r <= maxRow; r++) _dense(rows[r] ?? const {}),
    ];
  }

  static String _text(ArchiveFile file) => utf8.decode(file.content);

  static List<String> _dense(Map<int, String> cells) {
    if (cells.isEmpty) return const [];
    final width = cells.keys.reduce((a, b) => a > b ? a : b) + 1;
    return [for (var c = 0; c < width; c++) cells[c] ?? ''];
  }

  // workbook.xml -> first <sheet r:id> -> workbook.xml.rels target. Falls
  // back to the conventional sheet1.xml if any link in that chain is
  // missing, which is what most exporters produce anyway.
  static String _firstSheetPath(Archive archive) {
    const fallback = 'xl/worksheets/sheet1.xml';
    try {
      final workbookFile = archive.findFile('xl/workbook.xml');
      final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      if (workbookFile == null || relsFile == null) return fallback;

      final workbook = XmlDocument.parse(_text(workbookFile));
      final sheet = workbook.findAllElements('sheet').first;
      final relId = sheet.attributes
          .firstWhere((a) => a.name.local == 'id')
          .value;

      final rels = XmlDocument.parse(_text(relsFile));
      final target = rels
          .findAllElements('Relationship')
          .firstWhere((r) => r.getAttribute('Id') == relId)
          .getAttribute('Target')!;
      return target.startsWith('/')
          ? target.substring(1)
          : 'xl/${target.replaceFirst(RegExp(r'^\./'), '')}';
    } catch (_) {
      return fallback;
    }
  }

  static List<String> _readSharedStrings(Archive archive) {
    final file = archive.findFile('xl/sharedStrings.xml');
    if (file == null) return const [];
    final document = XmlDocument.parse(_text(file));
    // A shared string is either a single <t> or several rich-text <r><t>
    // runs; concatenating every <t> under the <si> covers both.
    return [
      for (final si in document.findAllElements('si'))
        si.findAllElements('t').map((t) => t.innerText).join(),
    ];
  }

  static String _cellText(XmlElement cell, List<String> sharedStrings) {
    final type = cell.getAttribute('t');
    if (type == 'inlineStr') {
      return cell.findAllElements('t').map((t) => t.innerText).join().trim();
    }
    final value = cell.getElement('v')?.innerText.trim() ?? '';
    if (type == 's') {
      final index = int.tryParse(value);
      return index != null && index < sharedStrings.length
          ? sharedStrings[index].trim()
          : '';
    }
    return value;
  }

  // "AB12" -> 27 (zero-based).
  static int? _columnIndex(String ref) {
    final letters = RegExp('^[A-Z]+').stringMatch(ref.toUpperCase());
    if (letters == null) return null;
    var index = 0;
    for (final unit in letters.codeUnits) {
      index = index * 26 + (unit - 64);
    }
    return index - 1;
  }
}
