import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import '../providers/merchant_dashboard_providers.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

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

  // Structure: { 'sunday': [{'open': '09:00', 'close': '22:00'}], ... }
  final Map<String, List<Map<String, String>>> _hours = {};

  final List<String> _days = [
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
    // Initialize empty structure
    for (var day in _days) {
      _hours[day] = [];
    }
  }

  void _initData(Map<String, dynamic> venue) {
    if (_initialized) return;

    _is24Hours = venue['is_24h'] ?? false;

    final hoursData = venue['hours'];
    if (hoursData != null && hoursData is Map) {
      for (var day in _days) {
        if (hoursData[day] != null) {
          final dayList = List<dynamic>.from(hoursData[day]);
          _hours[day] = dayList
              .map(
                (e) => {
                  'open': e['open'].toString(),
                  'close': e['close'].toString(),
                },
              )
              .toList();
        }
      }
    }

    // Add default shift if empty (optional UX choice)
    // if (!_is24Hours && _hours.values.every((l) => l.isEmpty)) {
    //   for (var d in _days) _hours[d] = [{'open': '09:00', 'close': '22:00'}];
    // }

    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) throw Exception(l10n.menuNoVenueLinked);

      // Prepare hours with spans_midnight logic
      final Map<String, dynamic> hoursToSave = {};

      if (!_is24Hours) {
        _hours.forEach((day, shifts) {
          if (shifts.isNotEmpty) {
            hoursToSave[day] = shifts.map((shift) {
              final open = shift['open']!;
              final close = shift['close']!;

              // Simple string compare works for HH:MM 24h format
              // If close < open (e.g. "02:00" < "22:00"), it spans midnight
              final spansMidnight = close.compareTo(open) < 0;

              return {
                'open': open,
                'close': close,
                'spans_midnight': spansMidnight,
              };
            }).toList();
          }
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.hoursSaved),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.hoursSaveError(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final oh = picked.hour.toString().padLeft(2, '0');
        final om = picked.minute.toString().padLeft(2, '0');
        _hours[day]![index][type] = '$oh:$om';
      });
    }
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
      for (var day in _days) {
        if (day == sourceDay) continue;
        // Deep copy
        _hours[day] = sourceShifts
            .map((e) => Map<String, String>.from(e))
            .toList();
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hoursCopiedAll)));
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
      appBar: AppBar(title: Text(l10n.hoursTitle)),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(child: Text(l10n.hoursLoadError(err.toString()))),
        data: (venue) {
          if (venue == null) return Center(child: Text(l10n.menuNoVenueLinked));
          _initData(venue);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. 24 Hours Toggle
              SwitchListTile(
                title: Text(
                  l10n.hours24hToggle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(l10n.hours24hSubtitle),
                value: _is24Hours,
                onChanged: (val) => setState(() => _is24Hours = val),
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.35),
              ),
              const Divider(height: 32),

              // 2. Weekly Schedule
              if (!_is24Hours) ...[
                Text(
                  l10n.hoursScheduleHint,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                ..._days.map((day) => _buildDayRow(day, l10n, dayLabels)),
              ],

              const SizedBox(height: 32),

              // 3. Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: WainLoadingIndicator(),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    l10n.hoursSaveBtn,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayRow(String day, AppLocalizations l10n, Map<String, String> dayLabels) {
    final shifts = _hours[day]!;
    final isClosed = shifts.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isClosed
            ? BorderSide.none
            : BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      elevation: isClosed ? 0 : 2,
      color: isClosed ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header: Day Name + Add Button + Copy Button
            Row(
              children: [
                Text(
                  dayLabels[day]!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isClosed ? Colors.grey : AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!isClosed)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                    tooltip: l10n.hoursCopyAll,
                    onPressed: () => _copyToAllDays(day),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _addShift(day),
                  tooltip: l10n.hoursAddShift,
                ),
              ],
            ),

            if (isClosed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.hoursClosed,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Shifts
            ...shifts.asMap().entries.map((entry) {
              final index = entry.key;
              final shift = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeChip(
                        shift['open']!,
                        () => _pickTime(day, index, 'open'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Expanded(
                      child: _buildTimeChip(
                        shift['close']!,
                        () => _pickTime(day, index, 'close'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _removeShift(day, index),
                    ),
                  ],
                ),
              );
            }), // Removed .toList() to fix potential iterable issue
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip(String time, VoidCallback onTap) {
    // Format to 12h for display
    final parts = time.split(':');
    final dt = DateTime(2022, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    final formatted = TimeOfDay.fromDateTime(dt).format(context); // Uses locale

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            formatted,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
