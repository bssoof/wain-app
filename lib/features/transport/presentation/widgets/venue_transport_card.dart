import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wain_app/core/providers/location_provider.dart';
import 'package:wain_app/core/services/analytics_service.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/transport/data/repositories/transport_repository.dart';
import 'package:wain_app/features/transport/presentation/providers/transport_providers.dart';
import 'package:wain_app/features/venue/domain/entities/venue.dart';
import 'package:wain_app/l10n/app_localizations.dart';

const Set<String> _rejectedTransportHandoffSchemes = {
  'javascript',
  'file',
  'intent',
  'data',
  'ftp',
  'about',
  'vbscript',
};

const Set<String> _knownTransportPartnerSchemes = {
  'uber',
  'lyft',
  'careem',
  'bolt',
};

bool _isSafeTransportHandoffUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isEmpty || _rejectedTransportHandoffSchemes.contains(scheme)) {
    return false;
  }
  return scheme == 'https' || _knownTransportPartnerSchemes.contains(scheme);
}

class VenueTransportCard extends ConsumerWidget {
  const VenueTransportCard({
    super.key,
    required this.venue,
    required this.onOpenNavigation,
  });

  final Venue venue;
  final VoidCallback onOpenNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!venue.transportEnabled) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final locationAsync = ref.watch(userLocationProvider);
    final hasPartners = venue.transportPartnerIds.isNotEmpty;
    final transportNote = locale.languageCode == 'ar'
        ? venue.transportNotesAr
        : venue.transportNotesEn;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: AppTheme.primaryColor.withAlpha(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySurfaceColor,
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.transportTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transportNote.isNotEmpty
                            ? transportNote
                            : l10n.transportSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasPartners)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Text(
                      l10n.transportComingSoon,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            locationAsync.when(
              data: (location) => _OriginHint(
                title: location.isRealLocation
                    ? l10n.transportCurrentLocation
                    : l10n.transportCityFallback,
                isFallback: !location.isRealLocation,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _OriginHint(
                title: l10n.transportCityFallback,
                isFallback: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasPartners
                    ? () => _openTransportSheet(context, ref)
                    : null,
                icon: const Icon(Icons.local_taxi_rounded),
                label: Text(l10n.transportShowOptions),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSpacing.radiusMd,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTransportSheet(BuildContext context, WidgetRef ref) async {
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.logEvent(
      name: 'transport_quotes_opened',
      parameters: {
        'venue_id': venue.id,
        'city': venue.city,
        'source': 'venue_details',
      },
    );

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TransportQuotesSheet(
        venue: venue,
        onOpenNavigation: onOpenNavigation,
      ),
    );
  }
}

class _OriginHint extends StatelessWidget {
  const _OriginHint({required this.title, required this.isFallback});

  final String title;
  final bool isFallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          isFallback ? Icons.location_city_rounded : Icons.my_location_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransportQuotesSheet extends ConsumerStatefulWidget {
  const _TransportQuotesSheet({
    required this.venue,
    required this.onOpenNavigation,
  });

  final Venue venue;
  final VoidCallback onOpenNavigation;

  @override
  ConsumerState<_TransportQuotesSheet> createState() =>
      _TransportQuotesSheetState();
}

class _TransportQuotesSheetState extends ConsumerState<_TransportQuotesSheet> {
  late Future<TransportQuotesResult> _quotesFuture;
  String? _loadingQuoteId;

  @override
  void initState() {
    super.initState();
    _quotesFuture = _loadQuotes();
  }

  Future<TransportQuotesResult> _loadQuotes() async {
    final analytics = ref.read(analyticsServiceProvider);
    final location = _effectiveLocation(readOnly: true);

    try {
      final result = await ref
          .read(transportRepositoryProvider)
          .getQuotes(
            venueId: widget.venue.id,
            city: widget.venue.city,
            userLocation: location,
            source: 'venue_details',
          );

      await analytics.logEvent(
        name: 'transport_quotes_loaded',
        parameters: {
          'venue_id': widget.venue.id,
          'city': widget.venue.city,
          'quotes_count': result.quotes.length,
          'has_real_location': location.isRealLocation,
        },
      );

      return result;
    } catch (e) {
      await analytics.logEvent(
        name: 'transport_quotes_failed',
        parameters: {'venue_id': widget.venue.id, 'city': widget.venue.city},
      );
      rethrow;
    }
  }

  Future<void> _refreshQuotes() async {
    setState(() {
      _quotesFuture = _loadQuotes();
    });
  }

  Future<void> _startHandoff(TransportQuote quote) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final analytics = ref.read(analyticsServiceProvider);

    setState(() {
      _loadingQuoteId = quote.quoteId;
    });

    try {
      final result = await ref
          .read(transportRepositoryProvider)
          .createHandoff(
            venueId: widget.venue.id,
            quoteId: quote.quoteId,
            source: 'venue_details',
          );

      await analytics.logEvent(
        name: 'transport_handoff_started',
        parameters: {
          'venue_id': widget.venue.id,
          'partner_id': quote.partnerId,
          'service_type': quote.serviceType,
        },
      );

      final uri = Uri.tryParse(result.handoffUrl);
      if (uri == null || !_isSafeTransportHandoffUri(uri)) {
        await analytics.logEvent(
          name: 'transport_handoff_failed',
          parameters: {
            'venue_id': widget.venue.id,
            'partner_id': quote.partnerId,
            'error_code': 'unsafe_handoff_url',
          },
        );
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.transportHandoffFailed)),
        );
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } on FirebaseFunctionsException catch (e) {
      await analytics.logEvent(
        name: 'transport_handoff_failed',
        parameters: {
          'venue_id': widget.venue.id,
          'partner_id': quote.partnerId,
          'error_code': e.code,
        },
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_transportErrorMessage(l10n, e))),
      );
    } catch (e) {
      await analytics.logEvent(
        name: 'transport_handoff_failed',
        parameters: {
          'venue_id': widget.venue.id,
          'partner_id': quote.partnerId,
          'error_code': 'unknown',
        },
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.transportHandoffFailed)),
      );
      if (kDebugMode) {
        debugPrint('Transport handoff failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingQuoteId = null;
        });
      }
    }
  }

  String _transportErrorMessage(
    AppLocalizations l10n,
    FirebaseFunctionsException exception,
  ) {
    final code = exception.code;
    final message = (exception.message ?? '').toLowerCase();

    if (message.contains('transport_disabled') ||
        message.contains('venue_inactive') ||
        message.contains('partner_contact_missing') ||
        message.contains('api_handoff_not_supported')) {
      return l10n.transportUnavailable;
    }

    if (message.contains('quote_expired')) {
      return l10n.transportQuoteExpired;
    }

    if (message.contains('quote_not_found')) {
      return l10n.transportNoCoverage;
    }

    switch (code) {
      case 'failed-precondition':
        return l10n.transportUnavailable;
      case 'resource-exhausted':
        return l10n.transportRateLimited;
      case 'out-of-range':
        return l10n.transportTooFar;
      case 'not-found':
        return l10n.transportNoCoverage;
      default:
        return l10n.transportLoadFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final location = _effectiveLocation();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.transportTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.venue.nameAr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!location.isRealLocation) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withAlpha(24),
                    borderRadius: AppSpacing.radiusMd,
                  ),
                  child: Text(
                    l10n.transportLocationWarning,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              FutureBuilder<TransportQuotesResult>(
                future: _quotesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    final errorMessage =
                        snapshot.error is FirebaseFunctionsException
                        ? _transportErrorMessage(
                            l10n,
                            snapshot.error! as FirebaseFunctionsException,
                          )
                        : l10n.transportLoadFailed;
                    return Expanded(
                      child: _QuotesErrorState(
                        message: errorMessage,
                        onRetry: _refreshQuotes,
                        onOpenNavigation: widget.onOpenNavigation,
                      ),
                    );
                  }

                  final result = snapshot.data;
                  if (result == null || result.quotes.isEmpty) {
                    return Expanded(
                      child: _QuotesEmptyState(
                        title: l10n.transportNoCoverage,
                        onOpenNavigation: widget.onOpenNavigation,
                      ),
                    );
                  }

                  final cheapestPrice = result.quotes
                      .map((quote) => quote.estimatedPrice)
                      .reduce((a, b) => a < b ? a : b);
                  final fastestEta = result.quotes
                      .map((quote) => quote.etaMinutes)
                      .reduce((a, b) => a < b ? a : b);

                  return Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              result.originMode == 'city_fallback'
                                  ? l10n.transportCityFallback
                                  : l10n.transportCurrentLocation,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _refreshQuotes,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(l10n.transportRefreshQuotes),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: ListView.separated(
                            itemCount: result.quotes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final quote = result.quotes[index];
                              final isCheapest =
                                  quote.estimatedPrice == cheapestPrice;
                              final isFastest = quote.etaMinutes == fastestEta;

                              return _QuoteCard(
                                quote: quote,
                                isCheapest: isCheapest,
                                isFastest: isFastest,
                                isBusy: _loadingQuoteId == quote.quoteId,
                                onTap: quote.isExpired
                                    ? null
                                    : () => _startHandoff(quote),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onOpenNavigation();
                            },
                            icon: const Icon(Icons.navigation_rounded),
                            label: Text(l10n.transportOpenNavigation),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  UserLocation _effectiveLocation({bool readOnly = false}) {
    final asyncLocation = readOnly
        ? ref.read(userLocationProvider)
        : ref.watch(userLocationProvider);

    return asyncLocation.when(
      data: (location) => location,
      loading: () => ref.read(selectedCityFallbackLocationProvider),
      error: (_, _) => ref.read(selectedCityFallbackLocationProvider),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.isCheapest,
    required this.isFastest,
    required this.isBusy,
    required this.onTap,
  });

  final TransportQuote quote;
  final bool isCheapest;
  final bool isFastest;
  final bool isBusy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String priceText() {
      if ((quote.priceMax - quote.priceMin).abs() > 0.01) {
        return '${quote.priceMin.toStringAsFixed(0)} - '
            '${quote.priceMax.toStringAsFixed(0)} ${quote.currency}';
      }
      return '${quote.estimatedPrice.toStringAsFixed(0)} ${quote.currency}';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    quote.partnerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (isCheapest) _Badge(text: l10n.transportCheapest),
                if (isFastest) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _Badge(text: l10n.transportFastest),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              quote.serviceType,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: l10n.transportPriceLabel,
                    value: priceText(),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: l10n.transportEtaLabel,
                    value: '${quote.etaMinutes} ${l10n.transportMinuteShort}',
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: l10n.transportTripLabel,
                    value: '${quote.tripMinutes} ${l10n.transportMinuteShort}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (quote.isEstimate)
              Text(
                l10n.transportPriceEstimate,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (quote.isExpired)
              Text(
                l10n.transportQuoteExpired,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : onTap,
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.transportStartHandoff),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primarySurfaceColor,
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuotesErrorState extends StatelessWidget {
  const _QuotesErrorState({
    required this.message,
    required this.onRetry,
    required this.onOpenNavigation,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(onPressed: onRetry, child: Text(l10n.retryButton)),
              OutlinedButton(
                onPressed: onOpenNavigation,
                child: Text(l10n.transportOpenNavigation),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotesEmptyState extends StatelessWidget {
  const _QuotesEmptyState({
    required this.title,
    required this.onOpenNavigation,
  });

  final String title;
  final VoidCallback onOpenNavigation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onOpenNavigation,
            icon: const Icon(Icons.navigation_rounded),
            label: Text(l10n.transportOpenNavigation),
          ),
        ],
      ),
    );
  }
}
