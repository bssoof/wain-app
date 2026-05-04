import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  final FutureOr<bool> Function()? onBeforeExit;

  const DoubleBackToExit({super.key, required this.child, this.onBeforeExit});

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPressAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final router = GoRouter.of(context);
        final messenger = ScaffoldMessenger.maybeOf(context);
        final l10n = AppLocalizations.of(context)!;
        final handledByChild = await widget.onBeforeExit?.call() ?? false;
        if (!mounted) return;
        if (handledByChild) return;

        if (router.canPop()) {
          router.pop();
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressAt != null &&
            now.difference(_lastBackPressAt!) <= const Duration(seconds: 2)) {
          messenger?.hideCurrentSnackBar();
          await SystemNavigator.pop();
          return;
        }

        _lastBackPressAt = now;
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.doubleBackToExitMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
      },
      child: widget.child,
    );
  }
}
