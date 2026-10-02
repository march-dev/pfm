import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../pfm.dart';

/// App preferences, one card per topic — currently just Error Logs.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        children: const [
          _LogsCard(),
        ],
      ),
    );
  }
}

// Whether to persist every logError call (see error_logging.util.dart) to
// a plain-text file, one per app session, under ErrorLogUseCases' own
// logsDirectory — on by default but still a disableable preference, with
// its own "open the folder" button right here since there's otherwise no
// way to actually find/read one of these files from inside the app. A
// StatefulWidget with its own local [_enabled] (read once at startup)
// rather than routed through a shared store — nothing else on this page
// needs to react to this toggle, so a shared observable would only add
// indirection for no benefit.
class _LogsCard extends StatefulWidget {
  const _LogsCard();

  @override
  State<_LogsCard> createState() => _LogsCardState();
}

class _LogsCardState extends State<_LogsCard> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = context.read<AppSettingsUseCases>().getFileLoggingEnabled();
  }

  void _setEnabled(bool value) {
    setState(() => _enabled = value);
    // Flips the live in-memory flag logError itself checks immediately,
    // rather than only taking effect on the next launch once the
    // persisted preference below is read back.
    context.read<ErrorLogUseCases>().setFileLoggingEnabled(value);
    context.read<AppSettingsUseCases>().setFileLoggingEnabled(value);
  }

  Future<void> _openLogsFolder(BuildContext context) async {
    final path = context.read<ErrorLogUseCases>().logsDirectory.path;
    await context.read<FileManagerUseCases>().reveal(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return HeaderCard(
      title: l10n.settingsLogsTitle,
      margin: EdgeInsets.zero,
      actions: [AppSwitch(value: _enabled, onChanged: _setEnabled)],
      child: _LogsCardBody(
        description: l10n.settingsLogsDescription,
        buttonLabel: l10n.settingsOpenLogsFolderButton,
        onOpenFolder: () => _openLogsFolder(context),
        mutedColor: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

// Split out purely to keep _LogsCardState.build within this file's own
// widget-nesting budget (PrimaryButton's own icon/label would otherwise
// land one level too deep).
class _LogsCardBody extends StatelessWidget {
  const _LogsCardBody({
    required this.description,
    required this.buttonLabel,
    required this.onOpenFolder,
    required this.mutedColor,
  });

  final String description;
  final String buttonLabel;
  final VoidCallback onOpenFolder;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: mutedColor),
        ),
        const SizedBox(height: AppSizes.spacing12),
        PrimaryButton(
          onPressed: onOpenFolder,
          icon: const Icon(CupertinoIcons.folder, size: AppSizes.iconMedium),
          label: Text(buttonLabel),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
      ],
    );
  }
}
