import 'package:flutter/material.dart';
import 'package:wain_app/l10n/app_localizations.dart';

/// Consistent clear action used inside venue search fields.
class SearchClearButton extends StatelessWidget {
  const SearchClearButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.clearSearch,
      onPressed: onPressed,
      icon: const Icon(Icons.close_rounded),
    );
  }
}
