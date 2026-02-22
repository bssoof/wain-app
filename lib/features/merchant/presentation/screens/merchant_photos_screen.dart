import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import '../providers/merchant_dashboard_providers.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';
/// Merchant Photos Management Screen -- إدارة صور المحل
class MerchantPhotosScreen extends ConsumerStatefulWidget {
  const MerchantPhotosScreen({super.key});

  @override
  ConsumerState<MerchantPhotosScreen> createState() =>
      _MerchantPhotosScreenState();
}

class _MerchantPhotosScreenState extends ConsumerState<MerchantPhotosScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    // Allow selecting multiple images
    final pickedList = await picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (pickedList.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) throw Exception('No venue');

      final List<String> newUrls = [];

      // Upload loop
      for (final picked in pickedList) {
        final file = File(picked.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final storageRef = FirebaseStorage.instance.ref().child(
          'venues/$venueId/photos/$fileName',
        );

        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await storageRef.putFile(file, metadata);
        final downloadUrl = await storageRef.getDownloadURL();
        newUrls.add(downloadUrl);
      }

      // Add all new URLs to array
      await FirebaseFirestore.instance.collection('venues').doc(venueId).update(
        {'photos': FieldValue.arrayUnion(newUrls)},
      );

      ref.invalidate(merchantVenueProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.merchantPhotosUploadSuccess(newUrls.length)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.merchantPhotosUploadFailed(e.toString())), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(String photoUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.merchantPhotosDeleteTitle),
        content: Text(AppLocalizations.of(context)!.merchantPhotosDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.merchantPhotosNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.merchantPhotosYes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) return;

      // Remove from Firestore
      await FirebaseFirestore.instance.collection('venues').doc(venueId).update(
        {
          'photos': FieldValue.arrayRemove([photoUrl]),
        },
      );

      // Try to delete from Storage (might fail if URL format differs)
      try {
        await FirebaseStorage.instance.refFromURL(photoUrl).delete();
      } catch (_) {}

      ref.invalidate(merchantVenueProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.merchantPhotosErrorGeneric(e.toString())), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setAsPrimary(
    List<dynamic> currentPhotos,
    String targetUrl,
  ) async {
    try {
      final venueId = await ref.read(merchantVenueIdProvider.future);
      if (venueId == null) return;

      // Create new list with targetUrl at index 0
      final List<String> newOrder = List<String>.from(currentPhotos);
      newOrder.remove(targetUrl);
      newOrder.insert(0, targetUrl);

      await FirebaseFirestore.instance.collection('venues').doc(venueId).update(
        {'photos': newOrder},
      );

      ref.invalidate(merchantVenueProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.merchantPhotosCoverSet),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final venueAsync = ref.watch(merchantVenueProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.merchantPhotosTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUpload,
        backgroundColor: AppTheme.primaryColor,
        icon: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: WainLoadingIndicator(),
              )
            : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(_isUploading ? l10n.merchantPhotosUploading : l10n.merchantPhotosAddBtn),
      ),
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (err, _) => Center(child: Text(l10n.merchantErrorGeneric(err.toString()))),
        data: (venue) {
          if (venue == null) {
            return Center(child: Text(l10n.merchantPhotosNoVenue));
          }

          final photos = (venue['photos'] as List?)?.cast<String>() ?? [];

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.merchantPhotosEmpty,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.merchantPhotosAddPrompt,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final url = photos[index];
              final isPrimary = index == 0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),

                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),

                  // "Primary" Badge
                  if (isPrimary)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              l10n.merchantPhotosCoverLabel,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Actions Menu (Delete / Set Primary)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (action) {
                        if (action == 'delete') _deletePhoto(url);
                        if (action == 'primary') _setAsPrimary(photos, url);
                      },
                      itemBuilder: (context) => [
                        if (!isPrimary)
                          PopupMenuItem(
                            value: 'primary',
                            child: Row(
                              children: [
                                Icon(Icons.photo_album, size: 20),
                                SizedBox(width: 8),
                                Text(l10n.merchantPhotosSetCover),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(l10n.merchantPhotosDelete, style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

