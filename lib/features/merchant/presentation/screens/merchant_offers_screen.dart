import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import '../providers/merchant_dashboard_providers.dart';

/// Merchant Offers Management Screen — إدارة العروض
class MerchantOffersScreen extends ConsumerWidget {
  const MerchantOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(merchantOffersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('إدارة العروض 🎁'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOfferForm(context, ref),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('عرض جديد'),
      ),
      body: offersAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(child: Text('خطأ: $err')),
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ما في عروض بعد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أنشئ أول عرض لمحلك!',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isActive = offer['is_active'] ?? true;
              final endAt = offer['end_at'] as Timestamp?;
              final now = DateTime.now();
              final isExpired = endAt != null && endAt.toDate().isBefore(now);
              final endingSoon =
                  endAt != null &&
                  !isExpired &&
                  endAt.toDate().isBefore(now.add(const Duration(hours: 48)));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpired
                        ? Colors.red.shade200
                        : isActive
                        ? Colors.green.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        Icons.local_offer,
                        color: isExpired
                            ? Colors.red
                            : isActive
                            ? Colors.green
                            : Colors.grey,
                        size: 32,
                      ),
                      title: Text(
                        offer['title_ar'] ?? offer['title'] ?? 'عرض',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (offer['description_ar'] != null)
                            Text(
                              offer['description_ar'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          // Dates row
                          _buildDateRow(offer),
                          const SizedBox(height: 8),
                          // Stats row
                          _buildStatsRow(offer),
                          if (endingSoon) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.deepOrange.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 13,
                                    color: Colors.deepOrange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ينتهي قريبًا',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) =>
                            _handleOfferAction(context, ref, offer, action),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Inline toggle switch
                    if (!isExpired)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'فعّال' : 'متوقف',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              isActive ? 'فعّال' : 'متوقف',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: isActive,
                              thumbColor: WidgetStateProperty.all(Colors.green),
                              onChanged: (value) async {
                                final offerId = offer['id'] as String;
                                await FirebaseFirestore.instance
                                    .collection('offers')
                                    .doc(offerId)
                                    .update({'is_active': value});
                                ref.invalidate(merchantOffersProvider);
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'منتهي',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateRow(Map<String, dynamic> offer) {
    final startAt = offer['start_at'] as Timestamp?;
    final endAt = offer['end_at'] as Timestamp?;

    String dateText = '';
    if (startAt != null) {
      final s = startAt.toDate();
      dateText += '${s.day}/${s.month}/${s.year}';
    }
    if (endAt != null) {
      final e = endAt.toDate();
      dateText += ' → ${e.day}/${e.month}/${e.year}';
    }
    if (dateText.isEmpty) dateText = 'بدون تاريخ محدد';

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          dateText,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> offer) {
    final claims = (offer['claims_count'] as num?)?.toInt() ?? 0;
    final redeemed = (offer['redeemed_count'] as num?)?.toInt() ?? 0;
    final conversionFromDb = (offer['conversion_rate'] as num?)?.toDouble();
    final conversion = conversionFromDb != null
        ? conversionFromDb * 100
        : (claims > 0 ? (redeemed / claims) * 100 : 0.0);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Claims
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_alt, size: 12, color: Colors.orange.shade800),
              const SizedBox(width: 4),
              Text(
                '$claims مهتم',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Redeemed
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 12, color: Colors.green.shade800),
              const SizedBox(width: 4),
              Text(
                '$redeemed تم الاستفادة',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Conversion rate
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.indigo.shade100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.percent, size: 12, color: Colors.indigo.shade700),
              const SizedBox(width: 4),
              Text(
                '${conversion.toStringAsFixed(0)}% تحويل',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.indigo.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleOfferAction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> offer,
    String action,
  ) async {
    final offerId = offer['id'] as String;

    switch (action) {
      case 'edit':
        _showOfferForm(context, ref, existingOffer: offer);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('حذف العرض'),
            content: const Text('هل أنت متأكد من حذف هذا العرض؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لا'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'نعم، احذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await FirebaseFirestore.instance
              .collection('offers')
              .doc(offerId)
              .delete();
          ref.invalidate(merchantOffersProvider);
        }
        break;
    }
  }

  void _showOfferForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? existingOffer,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OfferFormSheet(ref: ref, existingOffer: existingOffer),
    );
  }
}

/// Bottom sheet for creating/editing offers with start/end date + preview
class _OfferFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final Map<String, dynamic>? existingOffer;

  const _OfferFormSheet({required this.ref, this.existingOffer});

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleArController = TextEditingController();
  final _descArController = TextEditingController();
  final _discountController = TextEditingController();
  final _termsController = TextEditingController();
  String _discountType = 'percent';
  bool _isLoading = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingOffer != null) {
      final o = widget.existingOffer!;
      _titleArController.text = o['title_ar'] ?? '';
      _descArController.text = o['description_ar'] ?? '';
      _discountController.text =
          (o['discount_value'] as num?)?.toString() ?? '';
      _termsController.text = o['terms_ar'] ?? '';
      _discountType = o['discount_type'] ?? 'percent';
      final startAt = o['start_at'] as Timestamp?;
      if (startAt != null) _startDate = startAt.toDate();
      final endAt = o['end_at'] as Timestamp?;
      if (endAt != null) _endDate = endAt.toDate();
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
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end is after start
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 7));
        }
      });
    }
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
    if (picked != null) setState(() => _endDate = picked);
  }

  void _showPreview() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleArController.text.trim();
    final desc = _descArController.text.trim();
    final discountVal = double.tryParse(_discountController.text) ?? 0;
    final terms = _termsController.text.trim();

    String discountText;
    switch (_discountType) {
      case 'amount':
        discountText = 'خصم ${discountVal.toStringAsFixed(0)} ₪';
        break;
      case 'free_item':
        discountText = 'عرض مجاني';
        break;
      default:
        discountText = 'خصم ${discountVal.toStringAsFixed(0)}%';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.preview, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('معاينة العرض'),
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
              ], // Updated withValues
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ), // Updated withValues
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount badge
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
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              // Description
              if (desc.isNotEmpty)
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 12),
              // Dates
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
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              // Terms
              if (terms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '📋 $terms',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
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
            child: const Text('نشر العرض ✅'),
          ),
        ],
      ),
    );
  }

  String _formatDateRange() {
    String text = '';
    if (_startDate != null) {
      text += '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
    }
    if (_endDate != null) {
      text += ' → ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
    }
    return text;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final venueId = await widget.ref.read(merchantVenueIdProvider.future);
      if (venueId == null) throw Exception('No venue linked');

      final data = {
        'venue_id': venueId,
        'title_ar': _titleArController.text.trim(),
        'description_ar': _descArController.text.trim(),
        'discount_type': _discountType,
        'discount_value': double.tryParse(_discountController.text) ?? 0,
        'terms_ar': _termsController.text.trim(),
        'is_active': true,
        if (_startDate != null)
          'start_at': Timestamp.fromDate(_startDate!)
        else if (widget.existingOffer == null)
          'start_at': FieldValue.serverTimestamp(),
        if (_endDate != null) 'end_at': Timestamp.fromDate(_endDate!),
      };

      if (widget.existingOffer != null) {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.existingOffer!['id'])
            .update(data);
      } else {
        await FirebaseFirestore.instance.collection('offers').add(data);
      }

      widget.ref.invalidate(merchantOffersProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingOffer != null
                ? '✅ تم تعديل العرض'
                : '✅ تم إنشاء العرض',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                isEditing ? 'تعديل العرض' : 'عرض جديد 🎁',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleArController,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'مطلوب' : null,
                decoration: InputDecoration(
                  labelText: 'عنوان العرض',
                  hintText: 'مثال: خصم 20% على كل الطلبات',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descArController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'وصف العرض',
                  hintText: 'تفاصيل العرض...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Discount Type + Value
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'نوع الخصم',
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
                          items: const [
                            DropdownMenuItem(
                              value: 'percent',
                              child: Text('نسبة %'),
                            ),
                            DropdownMenuItem(
                              value: 'amount',
                              child: Text('مبلغ ₪'),
                            ),
                            DropdownMenuItem(
                              value: 'free_item',
                              child: Text('مجاني'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _discountType = v ?? 'percent'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'القيمة',
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

              // ── Date Pickers ──
              const Text(
                '📅 مدة العرض',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Start date
                  Expanded(
                    child: _dateTile(
                      label: 'بداية',
                      date: _startDate,
                      onTap: _pickStartDate,
                      onClear: () => setState(() => _startDate = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  // End date
                  Expanded(
                    child: _dateTile(
                      label: 'نهاية',
                      date: _endDate,
                      onTap: _pickEndDate,
                      onClear: () => setState(() => _endDate = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Terms
              TextFormField(
                controller: _termsController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'الشروط (اختياري)',
                  hintText: 'مثال: العرض لا يشمل التوصيل',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons — Preview + Submit
              Row(
                children: [
                  // Preview
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showPreview,
                      icon: const Icon(Icons.preview),
                      label: const Text('معاينة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Submit
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEditing ? 'حفظ التعديلات' : 'نشر العرض',
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

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
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
            Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null ? '${date.day}/${date.month}/${date.year}' : label,
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
