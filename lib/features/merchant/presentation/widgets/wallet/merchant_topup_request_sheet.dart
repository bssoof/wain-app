import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/l10n/app_localizations.dart';

import 'package:wain_app/core/theme/app_colors.dart';
import 'package:wain_app/core/widgets/app_button.dart';
import '../../providers/merchant_wallet_providers.dart';
import '../../../data/repositories/merchant_wallet_repository.dart';

class MerchantTopUpRequestSheet extends ConsumerStatefulWidget {
  final XFile? initialProofImage;
  final Widget? proofPreviewOverride;

  const MerchantTopUpRequestSheet({
    super.key,
    this.initialProofImage,
    this.proofPreviewOverride,
  });

  @override
  ConsumerState<MerchantTopUpRequestSheet> createState() =>
      _MerchantTopUpRequestSheetState();
}

class _MerchantTopUpRequestSheetState
    extends ConsumerState<MerchantTopUpRequestSheet> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final String _requestId;
  XFile? _proofImage;
  String? _proofError;

  @override
  void initState() {
    super.initState();
    _requestId = createTopUpRequestId();
    _proofImage = widget.initialProofImage;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    try {
      final venueId = await ref.read(merchantWalletVenueIdProvider.future);
      if (venueId == null) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.merchantStoriesNoVenue),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      String? proofImageUrl;
      if (_proofImage != null) {
        final file = File(_proofImage!.path);
        final byteLength = await file.length();
        if (byteLength > 5 * 1024 * 1024) {
          if (!mounted) return;
          setState(() {
            _proofError = l10n.merchantWalletProofTooLarge;
          });
          return;
        }
        final ext = _proofImage!.path.toLowerCase();
        final isValid =
            ext.endsWith('.jpg') ||
            ext.endsWith('.jpeg') ||
            ext.endsWith('.png') ||
            ext.endsWith('.webp');
        if (!isValid) {
          if (!mounted) return;
          setState(() {
            _proofError = l10n.merchantWalletProofInvalidType;
          });
          return;
        }
        final fileName =
            'topup_${DateTime.now().millisecondsSinceEpoch}_${_proofImage!.name}';
        proofImageUrl = await ref
            .read(merchantWalletRepositoryProvider)
            .uploadTopUpProof(venueId: venueId, file: file, fileName: fileName);
      }

      await ref
          .read(topUpRequestControllerProvider.notifier)
          .submitRequest(
            amount: amount,
            requestId: _requestId,
            proofImageUrl: proofImageUrl,
            transferReference: _refController.text.isNotEmpty
                ? _refController.text
                : null,
            note: _noteController.text.isNotEmpty ? _noteController.text : null,
          );

      if (!mounted) return;
      final state = ref.read(topUpRequestControllerProvider);
      if (state.hasError) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.merchantWalletTopUpError}: ${state.error}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.merchantWalletTopUpSuccess),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.merchantWalletTopUpError}: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickProofImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _proofImage = picked;
      _proofError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final requestState = ref.watch(topUpRequestControllerProvider);
    final isLoading = requestState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.merchantWalletTopUp,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.merchantWalletTopUpAmount,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return l10n.merchantWalletTopUpAmountRequired;
                }
                final n = double.tryParse(val);
                if (n == null || n <= 0) {
                  return l10n.merchantWalletTopUpAmountInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _refController,
              decoration: InputDecoration(
                labelText: l10n.merchantWalletTopUpRef,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.merchantWalletTopUpProof, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _pickProofImage,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.merchantWalletProofPickImage),
            ),
            if (_proofImage != null || widget.proofPreviewOverride != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child:
                    widget.proofPreviewOverride ??
                    Image.file(
                      File(_proofImage!.path),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
              ),
            ],
            if (_proofError != null) ...[
              const SizedBox(height: 6),
              Text(
                _proofError!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.merchantWalletTopUpNote,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: l10n.merchantWalletTopUpSubmit,
              isLoading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
