import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_dashboard_providers.dart';

class MerchantHoursScreen extends ConsumerStatefulWidget {
  const MerchantHoursScreen({super.key});

  @override
  ConsumerState<MerchantHoursScreen> createState() =>
      _MerchantHoursScreenState();
}

class _MerchantHoursScreenState extends ConsumerState<MerchantHoursScreen> {
  bool _isLoading = false;
  bool _is24Hours = false;
  bool _initialized = false;

  final Map<String, List<Map<String, String>>> _hours = {};
  final List<String> _days = const [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    for (final day in _days) {
      _hours[day] = [];
    }
  }

  void _initData(Map<String, dynamic> venue) {
    if (_initialized) {
      return;
    }

    _is24Hours = venue['is_24h'] ?? false;
    final hoursData = venue['hours'];
    if (hoursData is Map) {
      for (final day in _days) {
        final rawDay = hoursData[day];
        if (rawDay is List) {
          _hours[day] = rawDay
              .map(
                (entry) => {
                  'open': entry['open'].toString(),
                  'close': entry['close'].toString(),
                },
              )
              .toList();
        }
      }
    }

    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        throw Exception(l10n.merchantNoVenueLinked);
      }

      final hoursToSave = <String, dynamic>{};
      if (!_is24Hours) {
        _hours.forEach((day, shifts) {
          if (shifts.isEmpty) {
            return;
          }
          hoursToSave[day] = shifts.map((shift) {
            final open = shift['open']!;
            final close = shift['close']!;
            return {
              'open': open,
              'close': close,
              'spans_midnight': close.compareTo(open) < 0,
            };
          }).toList();
        });
      }

      await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .update({
            'is_24h': _is24Hours,
            'hours': _is24Hours ? null : hoursToSave,
            'updated_at': FieldValue.serverTimestamp(),
          });

      ref.invalidate(merchantVenueProvider);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.hoursSaved),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.hoursSaveError(error.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickTime(String day, int index, String type) async {
    final current = _hours[day]![index][type]!;
    final parts = current.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) {
      return;
    }

    setState(() {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      _hours[day]![index][type] = '$hour:$minute';
    });
  }

  void _addShift(String day) {
    setState(() {
      _hours[day]!.add({'open': '09:00', 'close': '17:00'});
    });
  }

  void _removeShift(String day, int shiftIndex) {
    setState(() {
      _hours[day]!.removeAt(shiftIndex);
    });
  }

  void _copyToAllDays(String sourceDay) {
    final sourceShifts = _hours[sourceDay]!;
    setState(() {
      for (final day in _days) {
        if (day == sourceDay) {
          continue;
        }
        _hours[day] = sourceShifts
            .map((shift) => Map<String, String>.from(shift))
            .toList();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.hoursCopiedAll)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = {
      'monday': l10n.hoursMonday,
      'tuesday': l10n.hoursTuesday,
      'wednesday': l10n.hoursWednesday,
      'thursday': l10n.hoursThursday,
      'friday': l10n.hoursFriday,
      'saturday': l10n.hoursSaturday,
      'sunday': l10n.hoursSunday,
    };
    final venueAsync = ref.watch(merchantVenueProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/merchant/edit-venue');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.hoursTitle),
      ),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.hoursLoadError(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (venue) {
          if (venue == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppEmptyState(
                  icon: Icons.schedule_outlined,
                  message: l10n.merchantNoVenueLinked,
                  actionLabel: l10n.merchantEnterInviteBtn,
                  onAction: () => context.push('/merchant/invite'),
                ),
              ),
            );
          }

          _initData(venue);
          final textTheme = Theme.of(context).textTheme;
          final colorScheme = Theme.of(context).colorScheme;

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              _HoursCardShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: AppSpacing.radiusMd,
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.hoursTitle,
                                style: textTheme.headlineSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.hoursScheduleHint,
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _HoursCardShell(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.hours24hToggle, style: textTheme.titleLarge),
                  subtitle: Text(l10n.hours24hSubtitle),
                  value: _is24Hours,
                  onChanged: (value) => setState(() => _is24Hours = value),
                ),
              ),
              if (!_is24Hours) ...[
                const SizedBox(height: AppSpacing.xl),
                ..._days.map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _buildDayCard(day, dayLabels[day]!, l10n),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: l10n.hoursSaveBtn,
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
                icon: const Icon(Icons.save_outlined, size: 18),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayCard(String day, String label, AppLocalizations l10n) {
    final shifts = _hours[day]!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isClosed = shifts.isEmpty;

    return _HoursCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isClosed ? l10n.hoursClosed : '${shifts.length} shift(s)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isClosed
                            ? AppTheme.errorColor
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isClosed)
                IconButton(
                  onPressed: () => _copyToAllDays(day),
                  icon: const Icon(Icons.copy_all_outlined),
                  tooltip: l10n.hoursCopyAll,
                ),
              IconButton(
                onPressed: () => _addShift(day),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: colorScheme.primary,
                tooltip: l10n.hoursAddShift,
              ),
            ],
          ),
          if (isClosed)
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withAlpha(18),
                borderRadius: AppSpacing.radiusMd,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  l10n.hoursClosed,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            )
          else
            ...shifts.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: _TimeChip(
                        value: entry.value['open']!,
                        onTap: () => _pickTime(day, entry.key, 'open'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Icon(Icons.arrow_forward_rounded),
                    ),
                    Expanded(
                      child: _TimeChip(
                        value: entry.value['close']!,
                        onTap: () => _pickTime(day, entry.key, 'close'),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeShift(day, entry.key),
                      icon: const Icon(Icons.close_rounded),
                      color: AppTheme.errorColor,
                      tooltip: l10n.merchantReviewsDelete,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const _TimeChip({required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = value.split(':');
    final dateTime = DateTime(
      2024,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final formatted = TimeOfDay.fromDateTime(dateTime).format(context);
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.radiusMd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.radiusMd,
          border: Border.all(color: colorScheme.outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Center(
            child: Text(
              formatted,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoursCardShell extends StatelessWidget {
  final Widget child;

  const _HoursCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colorScheme.outline),
        boxShadow: AppShadows.elevated,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: child,
      ),
    );
  }
}
