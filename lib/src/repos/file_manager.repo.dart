import 'dart:io';

/// Talks to the OS's native file manager.
class FileManagerRepo {
  const FileManagerRepo();

  /// Opens [path] in Finder, Explorer, or whichever handles `xdg-open` on
  /// Linux.
  Future<void> reveal(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer.exe', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  }
}
