import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer.dart';
import 'package:wain_app/features/merchant/domain/entities/merchant_offer_upsert_input.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_dashboard_providers.dart';
import 'package:wain_app/features/merchant/presentation/providers/merchant_providers.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

class MerchantOfferFormSheet extends ConsumerStatefulWidget {
  final MerchantOffer? existingOffer;

  const MerchantOfferFormSheet({super.key, this.existingOffer});

  @override
  ConsumerState<MerchantOfferFormSheet> createState() =>
      _MerchantOfferFormSheetState();
}

class _MerchantOfferFormSheetState
    extends ConsumerState<MerchantOfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleArController = TextEditingController();
  final _descArController = TextEditingController();
  final _discountController = TextEditingController();
  final _termsController = TextEditingController();

  String _discountType = 'percent';
  bool _isLoading = false;
  bool _singleUsePerCustomer = true;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _originalIsActive = true;
  DateTime? _originalStartAt;
  DateTime? _originalEndAt;

  @override
  void initState() {
    super.initState();
    final existingOffer = widget.existingOffer;
    if (existingOffer == null) {
      return;
    }

    _titleArController.text = existingOffer.titleAr;
    _descArController.text = existingOffer.descriptionAr;
    _discountController.text = existingOffer.discountValue % 1 == 0
        ? existingOffer.discountValue.toStringAsFixed(0)
        : existingOffer.discountValue.toString();
    _termsController.text = existingOffer.termsAr;
    _discountType = existingOffer.discountType;
    _singleUsePerCustomer = existingOffer.singleUsePerCustomer;
    _originalIsActive = existingOffer.isActive;
    _originalStartAt = existingOffer.startAt;
    _originalEndAt = existingOffer.endAt;
    if (_originalStartAt != null) {
      _startDate = _originalStartAt;
    }
    if (_originalEndAt != null) {
      _endDate = _originalEndAt;
    }
  }

  @override
  void dispose() {
    _titleArController.dispose();
    _descArController.dispose();
    _discountController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) {
        _endDate = picked.add(const Duration(days: 7));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _endDate ??
          (_startDate ?? DateTime.now()).add(const Duration(days: 7)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  String? _validateDiscountValue(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (_discountType == 'free_item') {
      return null;
    }

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.merchantOffersValueRequired;
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return l10n.merchantOffersValueInvalid;
    }
    if (parsed <= 0) {
      return l10n.merchantOffersValuePositive;
    }
    if (_discountType == 'percent' && parsed > 100) {
      return l10n.merchantOffersValuePercentRange;
    }
    return null;
  }

  String? _validateDateRange() {
    final l10n = AppLocalizations.of(context)!;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      return l10n.merchantOffersDateRangeInvalid;
    }
    return null;
  }

  void _showPreview() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final dateError = _validateDateRange();
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final title = _titleArController.text.trim();
    final description = _descArController.text.trim();
    final discountValue = _discountType == 'free_item'
        ? 0.0
        : double.tryParse(_discountController.text.trim()) ?? 0.0;
    final terms = _termsController.text.trim();

    String discountText;
    switch (_discountType) {
      case 'amount':
        discountText = l10n.merchantOffersDiscountAmount(
          discountValue.toStringAsFixed(0),
        );
        break;
      case 'free_item':
        discountText = l10n.merchantOffersDiscountFree;
        break;
      default:
        discountText = l10n.merchantOffersDiscountPercent(
          discountValue.toStringAsFixed(0),
        );
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.preview, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(l10n.merchantOffersPreviewTitle),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.15),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  discountText,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 12),
              if (_startDate != null || _endDate != null)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateRange(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              if (terms.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '📋',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  terms,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.merchantOffersPreviewClose),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.merchantOffersPreviewPublish),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    var text = '';
    if (_startDate != null) {
      text += '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
    }
    if (_endDate != null) {
      text += ' → ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
    }
    return text;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final dateError = _validateDateRange();
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        throw Exception(l10n.merchantOffersNoVenueLinked);
      }

      final discountValue = _discountType == 'free_item'
          ? 0.0
          : double.parse(_discountController.text.trim());

      final input = MerchantOfferUpsertInput(
        offerId: widget.existingOffer?.id,
        venueId: venueId,
        titleAr: _titleArController.text.trim(),
        descriptionAr: _descArController.text.trim(),
        discountType: _discountType,
        discountValue: discountValue,
        singleUsePerCustomer: _singleUsePerCustomer,
        termsAr: _termsController.text.trim(),
        isActive: widget.existingOffer == null ? true : _originalIsActive,
        startAt: _startDate,
        endAt: _endDate,
        applyServerStartAtWhenMissing:
            widget.existingOffer == null && _startDate == null,
        clearStartAt:
            widget.existingOffer != null &&
            _startDate == null &&
            _originalStartAt != null,
        clearEndAt:
            widget.existingOffer != null &&
            _endDate == null &&
            _originalEndAt != null,
      );

      await ref.read(merchantOffersRepositoryProvider).saveOffer(input);
      ref.invalidate(merchantOffersProvider);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingOffer != null
                ? l10n.merchantOffersEditUpdated
                : l10n.merchantOffersCreated,
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantOffersSubmitError(error.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingOffer != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEditing
                    ? l10n.merchantOffersFormEditTitle
                    : l10n.merchantOffersFormNewTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleArController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.merchantOffersFieldRequired
                    : null,
                decoration: InputDecoration(
                  labelText: l10n.merchantOffersFieldOfferTitle,
                  hintText: l10n.merchantOffersFieldOfferTitleHint,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descArController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.merchantOffersFieldDescription,
                  hintText: l10n.merchantOffersFieldDescHint,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.merchantOffersFieldDiscountType,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _discountType,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'percent',
                              child: Text(l10n.merchantOffersTypePercent),
                            ),
                            DropdownMenuItem(
                              value: 'amount',
                              child: Text(l10n.merchantOffersTypeAmount),
                            ),
                            DropdownMenuItem(
                              value: 'free_item',
                              child: Text(l10n.merchantOffersTypeFree),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _discountType = value ?? 'percent');
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      validator: _validateDiscountValue,
                      decoration: InputDecoration(
                        labelText: l10n.merchantOffersFieldValue,
                        hintText: _discountType == 'percent' ? '20' : '10',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.merchantOffersDurationLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: l10n.merchantOffersStartDate,
                      date: _startDate,
                      onTap: _pickStartDate,
                      onClear: () => setState(() => _startDate = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateTile(
                      label: l10n.merchantOffersEndDate,
                      date: _endDate,
                      onTap: _pickEndDate,
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.merchantOffersUsageLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                l10n.merchantOffersUsageHint,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.merchantOffersUsageSingle),
                    selected: _singleUsePerCustomer,
                    onSelected: (_) {
                      setState(() => _singleUsePerCustomer = true);
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.merchantOffersUsageRepeatable),
                    selected: !_singleUsePerCustomer,
                    onSelected: (_) {
                      setState(() => _singleUsePerCustomer = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _termsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.merchantOffersFieldTerms,
                  hintText: l10n.merchantOffersFieldTermsHint,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPreview,
                      icon: const Icon(Icons.preview),
                      label: Text(l10n.merchantOffersPreviewBtn),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: WainLoadingIndicator(),
                            )
                          : Text(
                              isEditing
                                  ? l10n.merchantOffersSaveChanges
                                  : l10n.merchantOffersPublish,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null
                    ? '${date!.day}/${date!.month}/${date!.year}'
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null ? Colors.black87 : AppTheme.textSecondary,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.clear, size: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
