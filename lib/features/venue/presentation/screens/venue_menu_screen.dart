import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/errors/app_exceptions.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/app_error_widget.dart';
import 'package:wain_app/features/venue/presentation/providers/venue_providers.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_section.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_tab.dart';
import 'package:wain_app/l10n/app_localizations.dart';

class VenueMenuScreen extends ConsumerWidget {
  final String venueId;

  const VenueMenuScreen({super.key, required this.venueId});

  AppException _asAppException(Object error) {
    if (error is AppException) return error;
    return ServerException(message: error.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final venueAsync = ref.watch(venueByIdProvider(venueId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.popOrGo('/venue/$venueId'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.menuTitle),
      ),
      body: venueAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: VenueMenuLoadingSkeleton(),
        ),
        error: (error, stackTrace) => AppErrorWidget(
          exception: _asAppException(error),
          onRetry: () => ref.invalidate(venueByIdProvider(venueId)),
        ),
        data: (venue) {
          if (venue == null) {
            return AppEmptyState(
              icon: Icons.storefront_outlined,
              message: l10n.venueNotFound,
            );
          }
          return VenueMenuTab(venue: venue);
        },
      ),
    );
  }
}
