import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/theme/app_shadows.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/core/widgets/app_empty_state.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';
import '../providers/merchant_dashboard_providers.dart';

/// Merchant Stories Screen — إدارة الستوريات
class MerchantStoriesScreen extends ConsumerWidget {
  const MerchantStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueIdAsync = ref.watch(merchantVenueIdProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.merchantStoriesTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStory(context, ref),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(l10n.merchantStoriesNewStory),
      ),
      body: venueIdAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (e, s) => Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              l10n.merchantStoriesError,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        data: (venueId) {
          if (venueId == null) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Text(
                  l10n.merchantStoriesNoVenue,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('stories')
                .where('venue_id', isEqualTo: venueId)
                .orderBy('created_at', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: WainLoadingIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppEmptyState(
                        icon: Icons.auto_stories_outlined,
                        message: l10n.merchantStoriesEmpty,
                      ),
                      Text(
                        l10n.merchantStoriesEmptyPrompt,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  96,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final storyId = docs[index].id;
                  final createdAt = data['created_at'] as Timestamp?;
                  final expiresAt = data['expires_at'] as Timestamp?;
                  final isExpired =
                      expiresAt != null &&
                      expiresAt.toDate().isBefore(DateTime.now());
                  final imageUrl = data['image_url'] as String?;
                  final videoUrl = data['video_url'] as String?;
                  final text = data['text'] as String? ?? '';
                  final dateStr = createdAt != null
                      ? '${createdAt.toDate().day}/${createdAt.toDate().month} ${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
                      : '';
                  final isPromoted =
                      data['promoted_until'] != null &&
                      (data['promoted_until'] as Timestamp).toDate().isAfter(
                        DateTime.now(),
                      );

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: AppSpacing.radiusLg,
                      border: Border.all(
                        color: isPromoted
                            ? AppTheme.warningColor
                            : (isExpired
                                  ? colorScheme.error.withAlpha(90)
                                  : colorScheme.outline),
                        width: isPromoted ? 2 : 1,
                      ),
                      boxShadow: AppShadows.elevated,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 200,
                                color: colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          )
                        else if (videoUrl != null)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 48,
                                    color: colorScheme.primary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    l10n.merchantStoriesVideo,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (text.isNotEmpty)
                                Text(text, style: theme.textTheme.bodyLarge),
                              const SizedBox(height: AppSpacing.sm),
                              // Status row
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const Spacer(),
                                  // Promote Status Badge
                                  if (isPromoted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningColor.withAlpha(
                                          18,
                                        ),
                                        borderRadius: AppSpacing.radiusSm,
                                        border: Border.all(
                                          color: AppTheme.warningColor
                                              .withAlpha(72),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 12,
                                            color: AppTheme.warningColor,
                                          ),
                                          const SizedBox(width: AppSpacing.xs),
                                          Text(
                                            l10n.merchantStoriesPromoted,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.warningColor,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  // Expiry Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpired
                                          ? colorScheme.errorContainer
                                          : AppTheme.successColor.withAlpha(18),
                                      borderRadius: AppSpacing.radiusSm,
                                    ),
                                    child: Text(
                                      isExpired
                                          ? l10n.merchantStoriesExpired
                                          : l10n.merchantStoriesActive,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isExpired
                                                ? colorScheme.onErrorContainer
                                                : AppTheme.successColor,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              // Action buttons row - prominent promote button
                              Row(
                                children: [
                                  // Promote Button -- large and prominent
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _promoteStory(context, storyId),
                                      icon: const Icon(
                                        Icons.rocket_launch,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isPromoted
                                            ? l10n.merchantStoriesExtendPromo
                                            : l10n.merchantStoriesPromote,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPromoted
                                            ? AppTheme.warningColor
                                            : colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppSpacing.radiusMd,
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.errorColor,
                                      size: 22,
                                    ),
                                    onPressed: () => _deleteStory(
                                      context,
                                      ref,
                                      storyId,
                                      imageUrl,
                                      videoUrl,
                                    ),
                                    tooltip: l10n.merchantStoriesDeleteTooltip,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _promoteStory(BuildContext context, String storyId) async {
    final l10n = AppLocalizations.of(context)!;
    final duration = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.merchantStoriesPromoteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.merchantStoriesPromoteDesc),
            const SizedBox(height: 16),
            Text(l10n.merchantStoriesChooseDuration),
            const SizedBox(height: 8),
            _PromoteOption(label: l10n.merchantStoriesPromote1Day, days: 1),
            _PromoteOption(label: l10n.merchantStoriesPromote3Days, days: 3),
            _PromoteOption(label: l10n.merchantStoriesPromote7Days, days: 7),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.merchantStoriesCancel),
          ),
        ],
      ),
    );

    if (duration == null) return;
    if (!context.mounted) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: WainLoadingIndicator()),
      );

      // Call Cloud Function
      await FirebaseFunctions.instance.httpsCallable('promoteStory').call({
        'storyId': storyId,
        'durationDays': duration,
      });

      // Close loading
      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPromoteSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPromoteError(e.message ?? '')),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesUnexpectedError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteStory(
    BuildContext context,
    WidgetRef ref,
    String storyId,
    String? imageUrl,
    String? videoUrl,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.merchantStoriesDeleteTitle),
        content: Text(l10n.merchantStoriesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.merchantStoriesNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.merchantStoriesYes,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .delete();
      if (imageUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (_) {}
      }
      if (videoUrl != null) {
        try {
          await FirebaseStorage.instance.refFromURL(videoUrl).delete();
        } catch (_) {}
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesDeleteFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateStory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateStorySheet(ref: ref),
    );
  }
}

class _PromoteOption extends StatelessWidget {
  final String label;
  final int days;

  const _PromoteOption({required this.label, required this.days});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context, days),
        child: Text(label),
      ),
    );
  }
}

/// Create Story Bottom Sheet
class _CreateStorySheet extends StatefulWidget {
  final WidgetRef ref;
  const _CreateStorySheet({required this.ref});

  @override
  State<_CreateStorySheet> createState() => _CreateStorySheetState();
}

class _CreateStorySheetState extends State<_CreateStorySheet> {
  final _textController = TextEditingController();
  XFile? _pickedImage;
  XFile? _pickedVideo;
  bool _isSubmitting = false;
  int _expiryHours = 24;
  String _mediaType = 'none'; // 'none', 'image', 'video'

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = picked;
        _pickedVideo = null;
        _mediaType = 'image';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked != null) {
      setState(() {
        _pickedVideo = picked;
        _pickedImage = null;
        _mediaType = 'video';
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _textController.text.trim();
    if (text.isEmpty && _pickedImage == null && _pickedVideo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.merchantStoriesAddContent)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final venueId = await widget.ref.read(merchantVenueIdProvider.future);
      if (venueId == null) throw Exception('No venue');

      // Fetch venue data for name and photo
      final venueDoc = await FirebaseFirestore.instance
          .collection('venues')
          .doc(venueId)
          .get();
      final venueData = venueDoc.data() ?? {};
      final venueName = venueData['name_ar'] ?? venueData['name'] ?? '';
      final venuePhotos = venueData['photos'] as List?;
      final venuePhotoUrl = (venuePhotos != null && venuePhotos.isNotEmpty)
          ? venuePhotos.first as String?
          : null;

      String? imageUrl;
      String? videoUrl;
      if (_pickedImage != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(
          'venues/$venueId/stories/$fileName',
        );
        await storageRef.putFile(File(_pickedImage!.path));
        imageUrl = await storageRef.getDownloadURL();
      }
      if (_pickedVideo != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
        final storageRef = FirebaseStorage.instance.ref().child(
          'venues/$venueId/stories/$fileName',
        );
        await storageRef.putFile(File(_pickedVideo!.path));
        videoUrl = await storageRef.getDownloadURL();
      }

      String storyType = 'text';
      if (imageUrl != null) storyType = 'image';
      if (videoUrl != null) storyType = 'video';

      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('stories').add({
        'venue_id': venueId,
        'venue_name': venueName,
        'venue_photo_url': venuePhotoUrl,
        'type': storyType,
        'text': text,
        'image_url': imageUrl,
        'video_url': videoUrl,
        'created_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(
          now.add(Duration(hours: _expiryHours)),
        ),
        'created_by': FirebaseAuth.instance.currentUser?.uid,
      });

      // Update venue doc to indicate active stories for list view
      await FirebaseFirestore.instance.collection('venues').doc(venueId).update(
        {'last_story_at': Timestamp.fromDate(now)},
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPublished),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.merchantStoriesPublishError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
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
              l10n.merchantStoriesNewStoryTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Media Picker -- Image or Video
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: _mediaType == 'image'
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mediaType == 'image'
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: _mediaType == 'image' ? 2 : 1,
                        ),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 36,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.merchantStoriesPhoto,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickVideo,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: _mediaType == 'video'
                            ? Colors.deepPurple.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _mediaType == 'video'
                              ? Colors.deepPurple
                              : Colors.grey.shade300,
                          width: _mediaType == 'video' ? 2 : 1,
                        ),
                      ),
                      child: _pickedVideo != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.videocam,
                                  size: 40,
                                  color: Colors.deepPurple,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.merchantStoriesVideoSelected,
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  size: 36,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.merchantStoriesVideo,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  l10n.merchantStoriesVideoLimit,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text
            TextField(
              controller: _textController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.merchantStoriesTextHint,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Expiry
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 8),
                Text(l10n.merchantStoriesDuration),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: Text(l10n.merchantStories24h),
                  selected: _expiryHours == 24,
                  onSelected: (_) => setState(() => _expiryHours = 24),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.merchantStories48h),
                  selected: _expiryHours == 48,
                  onSelected: (_) => setState(() => _expiryHours = 48),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.merchantStoriesPromote7),
                  selected: _expiryHours == 168,
                  onSelected: (_) => setState(() => _expiryHours = 168),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: WainLoadingIndicator(),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  l10n.merchantStoriesPublishBtn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
