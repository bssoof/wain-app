import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import '../providers/merchant_dashboard_providers.dart';

/// Merchant Stories Screen — إدارة الستوريات
class MerchantStoriesScreen extends ConsumerWidget {
  const MerchantStoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueIdAsync = ref.watch(merchantVenueIdProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('الستوريات 📖'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStory(context, ref),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('ستوري جديد'),
      ),
      body: venueIdAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (e, s) => const Center(child: Text('خطأ')),
        data: (venueId) {
          if (venueId == null) {
            return const Center(child: Text('ما في محل مربوط'));
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ما في ستوريات بعد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أنشر ستوري عشان يشوفها زبائنك!',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 80,
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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPromoted
                            ? Colors.amber
                            : (isExpired
                                  ? Colors.red.shade200
                                  : Colors.grey.shade200),
                        width: isPromoted ? 2 : 1,
                      ),
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
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          )
                        else if (videoUrl != null)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.videocam,
                                    size: 48,
                                    color: Colors.deepPurple,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '🎬 فيديو',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (text.isNotEmpty)
                                Text(
                                  text,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              const SizedBox(height: 8),
                              // Status row
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Promote Status Badge
                                  if (isPromoted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            size: 12,
                                            color: Colors.orange,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'مروج',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  // Expiry Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpired
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isExpired ? 'منتهي' : 'فعّال',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isExpired
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Action buttons row - prominent promote button
                              Row(
                                children: [
                                  // Promote Button — large and prominent
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
                                            ? 'تمديد الترويج'
                                            : 'ترويج 🚀',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPromoted
                                            ? Colors.amber.shade700
                                            : Colors.amber,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    onPressed: () => _deleteStory(
                                      context,
                                      ref,
                                      storyId,
                                      imageUrl,
                                      videoUrl,
                                    ),
                                    tooltip: 'حذف',
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
    final duration = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ترويج الستوري 🚀'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سيظهر الستوري في الصفحة الرئيسية لكل المستخدمين!'),
            const SizedBox(height: 16),
            const Text('اختر المدة:'),
            const SizedBox(height: 8),
            _PromoteOption(label: 'يوم واحد (1\$)', days: 1),
            _PromoteOption(label: '3 أيام (2.5\$)', days: 3),
            _PromoteOption(label: 'أسبوع (5\$)', days: 7),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
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
        const SnackBar(
          content: Text('✅ تم ترويج الستوري بنجاح!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ خطأ: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ حدث خطأ غير متوقع'),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الستوري'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم', style: TextStyle(color: Colors.red)),
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
        const SnackBar(
          content: Text('تم حذف الستوري'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حذف الستوري: $e'),
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
    final text = _textController.text.trim();
    if (text.isEmpty && _pickedImage == null && _pickedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف نص أو صورة أو فيديو على الأقل')),
      );
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
        const SnackBar(
          content: Text('✅ تم نشر الستوري'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'ستوري جديد 📖',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Media Picker — Image or Video
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
                                  '📷 صورة',
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
                                  '✅ تم اختيار الفيديو',
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
                                  '🎬 فيديو',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '(حد أقصى 30 ثانية)',
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
                hintText: 'اكتب نص الستوري...',
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
                const Text('مدة الستوري:'),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('24 ساعة'),
                  selected: _expiryHours == 24,
                  onSelected: (_) => setState(() => _expiryHours = 24),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('48 ساعة'),
                  selected: _expiryHours == 48,
                  onSelected: (_) => setState(() => _expiryHours = 48),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('7 أيام'),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: const Text(
                  'نشر الستوري',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
