import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/providers/offline_providers.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/core/widgets/offline_widgets.dart';
import 'package:wain_app/features/venue/presentation/widgets/venue_menu_item_image.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';

import '../providers/merchant_dashboard_providers.dart';
import '../providers/merchant_invalidation.dart';
import '../providers/merchant_providers.dart';

class MerchantPhotosScreen extends ConsumerStatefulWidget {
  const MerchantPhotosScreen({super.key});

  @override
  ConsumerState<MerchantPhotosScreen> createState() =>
      _MerchantPhotosScreenState();
}

class _MerchantPhotosScreenState extends ConsumerState<MerchantPhotosScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
    );

    if (pickedFiles.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isUploading = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        throw Exception(l10n.merchantPhotosNoVenue);
      }

      final newUrls = await ref
          .read(merchantPhotosRepositoryProvider)
          .uploadPhotos(venueId: venueId, files: pickedFiles);

      ref.invalidateMerchantContentData();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantPhotosUploadSuccess(newUrls.length)),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantPhotosUploadFailed(error.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deletePhoto(String photoUrl) async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.merchantPhotosDeleteTitle),
        content: Text(l10n.merchantPhotosDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.merchantPhotosNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.merchantPhotosYes,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        return;
      }

      await ref
          .read(merchantPhotosRepositoryProvider)
          .deletePhoto(venueId: venueId, photoUrl: photoUrl);
      ref.invalidateMerchantContentData();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantPhotosErrorGeneric(error.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _setAsPrimary(
    List<dynamic> currentPhotos,
    String targetUrl,
  ) async {
    if (!ref.read(isOnlineProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.offlineActionRequiresConnection,
          ),
        ),
      );
      return;
    }
    final l10n = AppLocalizations.of(context)!;

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) {
        return;
      }

      await ref
          .read(merchantPhotosRepositoryProvider)
          .setPrimaryPhoto(
            venueId: venueId,
            currentPhotos: List<String>.from(currentPhotos),
            targetUrl: targetUrl,
          );

      ref.invalidateMerchantContentData();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantPhotosCoverSet),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantPhotosErrorInline(error.toString())),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final venueAsync = ref.watch(merchantVenueProvider);
    final venueSnapshotAsync = ref.watch(merchantVenueSnapshotProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.popOrGo('/merchant/dashboard'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.merchantPhotosTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading
            ? null
            : ref.watch(isOnlineProvider)
            ? _pickAndUpload
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.offlineActionRequiresConnection,
                  ),
                ),
              ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: _isUploading
            ? const SizedBox.square(
                dimension: 20,
                child: WainLoadingIndicator(size: 20),
              )
            : const Icon(Icons.add_a_photo_outlined),
        label: Text(
          _isUploading
              ? l10n.merchantPhotosUploading
              : l10n.merchantPhotosAddBtn,
        ),
      ),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.merchantErrorGeneric(error.toString()),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (venue) {
          final venueSnapshot = venueSnapshotAsync.asData?.value;
          final showOfflineEmpty =
              venue == null &&
              venueSnapshot != null &&
              !venueSnapshot.hasData &&
              venueSnapshot.isFromCache &&
              venueSnapshot.fetchedAt == null &&
              !ref.read(isOnlineProvider);
          if (showOfflineEmpty) {
            return const OfflineEmptyState(
              title: 'لا توجد نسخة محفوظة لصور المنشأة',
              subtitle:
                  'افتح شاشة الصور مرة واحدة أثناء الاتصال لحفظ نسخة محلية.',
            );
          }

          if (venue == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: AppEmptyState(
                  icon: Icons.photo_library_outlined,
                  message: l10n.merchantPhotosNoVenue,
                  actionLabel: l10n.merchantEnterInviteBtn,
                  onAction: () => context.push('/merchant/invite'),
                ),
              ),
            );
          }

          final photos = venue.photos;

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              OfflineBanner(
                isVisible: venueSnapshot?.isFromCache ?? false,
                fetchedAt: venueSnapshot?.fetchedAt,
              ),
              if (venueSnapshot?.isFromCache ?? false)
                const SizedBox(height: AppSpacing.md),
              _PhotosCardShell(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppSpacing.radiusMd,
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.merchantPhotosTitle,
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            photos.isEmpty
                                ? l10n.merchantPhotosEmpty
                                : l10n.merchantPhotosUploadSuccess(
                                    photos.length,
                                  ),
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (photos.isEmpty)
                AppEmptyState(
                  icon: Icons.photo_camera_back_outlined,
                  message: l10n.merchantPhotosAddPrompt,
                  actionLabel: l10n.merchantPhotosAddBtn,
                  onAction: _isUploading ? null : _pickAndUpload,
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final photoUrl = photos[index];
                    final isPrimary = index == 0;
                    return _PhotoTile(
                      photoUrl: photoUrl,
                      isPrimary: isPrimary,
                      coverLabel: l10n.merchantPhotosCoverLabel,
                      setCoverLabel: l10n.merchantPhotosSetCover,
                      deleteLabel: l10n.merchantPhotosDelete,
                      onDelete: () => _deletePhoto(photoUrl),
                      onSetCover: isPrimary
                          ? null
                          : () => _setAsPrimary(photos, photoUrl),
                    );
                  },
                ),
              const SizedBox(height: AppSpacing.xxxl * 2),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String photoUrl;
  final bool isPrimary;
  final String coverLabel;
  final String setCoverLabel;
  final String deleteLabel;
  final VoidCallback onDelete;
  final VoidCallback? onSetCover;

  const _PhotoTile({
    required this.photoUrl,
    required this.isPrimary,
    required this.coverLabel,
    required this.setCoverLabel,
    required this.deleteLabel,
    required this.onDelete,
    this.onSetCover,
  });

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
      child: ClipRRect(
        borderRadius: AppSpacing.radiusLg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: venueImageProvider(photoUrl),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(70),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                  ],
                ),
              ),
            ),
            if (isPrimary)
              PositionedDirectional(
                top: AppSpacing.sm,
                start: AppSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          coverLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              top: AppSpacing.xs,
              end: AppSpacing.xs,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                onSelected: (action) {
                  if (action == 'cover') {
                    onSetCover?.call();
                  } else if (action == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (!isPrimary)
                    PopupMenuItem<String>(
                      value: 'cover',
                      child: Row(
                        children: [
                          const Icon(Icons.photo_outlined, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text(setCoverLabel),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          deleteLabel,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotosCardShell extends StatelessWidget {
  final Widget child;

  const _PhotosCardShell({required this.child});

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
