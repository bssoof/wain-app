import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/data/repositories/menu_repository.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';

import '../providers/merchant_dashboard_providers.dart';

class MerchantMenuScreen extends ConsumerStatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  ConsumerState<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends ConsumerState<MerchantMenuScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<MenuSection> _sections = const [];

  String? _venueId;
  String _venueCategory = '';
  String? _activeVersionId;
  String? _draftVersionId;
  String? _draftError;
  String? _draftInitKey;

  bool _isPreparingDraft = false;
  bool _isMutatingVersion = false;
  bool _autoPrepareDraft = true;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initTabs(String venueCategory) {
    if (_venueCategory == venueCategory && _tabController != null) return;
    _venueCategory = venueCategory;
    _sections = ref.read(menuSectionsProvider(venueCategory));
    _tabController?.dispose();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

  void _startNewDraft() {
    if (_venueId == null) return;
    setState(() {
      _autoPrepareDraft = true;
      _draftError = null;
      _draftInitKey = null;
    });
    _ensureDraftPrepared(_venueId!, _venueCategory);
  }

  void _ensureDraftPrepared(String venueId, String venueCategory) {
    final key = '$venueId|$venueCategory';
    if (_draftInitKey == key &&
        (_draftVersionId != null || _isPreparingDraft)) {
      return;
    }
    _draftInitKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() {
        _isPreparingDraft = true;
        _draftError = null;
      });

      final merchantUid = FirebaseAuth.instance.currentUser?.uid;
      if (merchantUid == null) {
        if (!mounted) return;
        setState(() {
          _isPreparingDraft = false;
          _draftError = 'يجب تسجيل الدخول كتاجر';
        });
        return;
      }

      try {
        final draft = await ref
            .read(menuRepositoryProvider)
            .ensureDraftVersion(
              venueId: venueId,
              venueCategory: venueCategory,
              merchantUid: merchantUid,
            );
        if (!mounted) return;
        setState(() {
          _draftVersionId = draft.draftVersionId;
          _activeVersionId = draft.activeVersionId;
          _isPreparingDraft = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isPreparingDraft = false;
          _draftError = e.toString();
        });
      }
    });
  }

  Future<void> _publishDraft() async {
    if (_venueId == null || _draftVersionId == null || _isMutatingVersion) {
      return;
    }
    final merchantUid = FirebaseAuth.instance.currentUser?.uid;
    if (merchantUid == null) return;

    setState(() => _isMutatingVersion = true);
    try {
      await ref
          .read(menuRepositoryProvider)
          .publishDraftVersion(venueId: _venueId!, merchantUid: merchantUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نشر المسودة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isMutatingVersion = false;
        _draftVersionId = null;
        _activeVersionId = null;
        _draftInitKey = null;
        _autoPrepareDraft = false;
      });
      ref.invalidate(menuItemsProvider(_venueId!));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMutatingVersion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل نشر المسودة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rollbackToArchivedVersion() async {
    if (_venueId == null || _isMutatingVersion) return;
    final merchantUid = FirebaseAuth.instance.currentUser?.uid;
    if (merchantUid == null) return;

    final versions = await ref
        .read(menuRepositoryProvider)
        .listMenuVersions(_venueId!);
    final archived = versions.where((v) => v.status == 'archived').toList();
    if (!mounted) return;
    if (archived.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد إصدار مؤرشف للرجوع إليه')),
      );
      return;
    }

    final selected = await showDialog<MenuVersionSummary>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('اختر إصدار للرجوع'),
        children: archived
            .map(
              (v) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, v),
                child: Text(v.versionId),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null) return;

    setState(() => _isMutatingVersion = true);
    try {
      await ref
          .read(menuRepositoryProvider)
          .rollbackToVersion(
            venueId: _venueId!,
            targetVersionId: selected.versionId,
            merchantUid: merchantUid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الرجوع للإصدار السابق'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _isMutatingVersion = false;
        _draftVersionId = null;
        _activeVersionId = null;
        _draftInitKey = null;
        _autoPrepareDraft = false;
      });
      ref.invalidate(menuItemsProvider(_venueId!));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMutatingVersion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الرجوع: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final venueAsync = ref.watch(merchantVenueProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('إدارة المنيو'),
        actions: [
          IconButton(
            onPressed:
                (_draftVersionId != null &&
                    !_isPreparingDraft &&
                    !_isMutatingVersion)
                ? _publishDraft
                : null,
            icon: const Icon(Icons.publish),
            tooltip: 'نشر المسودة',
          ),
          IconButton(
            onPressed: (_venueId != null && !_isMutatingVersion)
                ? _rollbackToArchivedVersion
                : null,
            icon: const Icon(Icons.history),
            tooltip: 'الرجوع لإصدار مؤرشف',
          ),
        ],
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                tabs: _sections.map((s) => Tab(text: s.nameAr)).toList(),
              )
            : null,
      ),
      floatingActionButton:
          _venueId != null &&
              _draftVersionId != null &&
              _tabController != null &&
              !_isPreparingDraft
          ? FloatingActionButton(
              onPressed: () => _openItemEditor(),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: venueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (venue) {
          if (venue == null) {
            return const Center(child: Text('لا يوجد محل مربوط'));
          }

          _venueId = venue['id'] as String;
          final categories =
              (venue['categories'] as List?)?.cast<String>() ?? [];
          final venueCategory = categories.isNotEmpty
              ? categories.first
              : 'restaurant';
          _initTabs(venueCategory);
          if (_autoPrepareDraft) {
            _ensureDraftPrepared(_venueId!, venueCategory);
          }

          if (_isPreparingDraft ||
              _tabController == null ||
              _draftVersionId == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_draftError != null) {
            return Center(child: Text('فشل تجهيز المسودة: $_draftError'));
          }

          if (_draftVersionId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'تم نشر آخر مسودة. لا توجد مسودة جديدة حاليًا.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isMutatingVersion ? null : _startNewDraft,
                      child: const Text('إنشاء مسودة جديدة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final itemsAsync = ref.watch(
            menuVersionItemsProvider(
              MenuVersionItemsQuery(
                venueId: _venueId!,
                versionId: _draftVersionId!,
              ),
            ),
          );

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  _activeVersionId == null
                      ? 'مسودة جديدة غير منشورة'
                      : 'تحرير مسودة فوق الإصدار النشط: $_activeVersionId',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                ),
              ),
              Expanded(
                child: itemsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('خطأ: $e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(child: Text('المنيو فارغ'));
                    }
                    return TabBarView(
                      controller: _tabController,
                      children: _sections.map((section) {
                        final sectionItems =
                            items
                                .where((i) => i.category == section.id)
                                .toList()
                              ..sort(
                                (a, b) => a.sortOrder.compareTo(b.sortOrder),
                              );
                        if (sectionItems.isEmpty) {
                          return Center(
                            child: Text('لا يوجد عناصر في ${section.nameAr}'),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: sectionItems.length,
                          itemBuilder: (_, i) =>
                              _buildItemCard(sectionItems[i]),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openItemEditor(existing: item),
        leading: item.photoUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.photoUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.restaurant),
                ),
              )
            : const Icon(Icons.restaurant),
        title: Text(item.nameAr),
        subtitle: Text('${item.price.toStringAsFixed(0)} ${item.currency}'),
        trailing: Switch(
          value: item.isAvailable,
          onChanged: (val) {
            if (_venueId != null && _draftVersionId != null) {
              ref
                  .read(menuRepositoryProvider)
                  .toggleAvailability(
                    _venueId!,
                    item.id,
                    val,
                    versionId: _draftVersionId,
                  );
            }
          },
        ),
      ),
    );
  }

  Future<void> _openItemEditor({MenuItem? existing}) async {
    if (_venueId == null || _draftVersionId == null || _sections.isEmpty) {
      return;
    }
    final result = await showModalBottomSheet<_EditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ItemEditorSheet(existing: existing, sections: _sections),
    );
    if (result == null) return;

    final repo = ref.read(menuRepositoryProvider);
    try {
      if (result.delete && existing != null) {
        await repo.deleteMenuItem(
          _venueId!,
          existing,
          versionId: _draftVersionId,
        );
        return;
      }

      String photoUrl = existing?.photoUrl ?? '';
      if (result.pickedPhoto != null) {
        photoUrl = await repo.uploadMenuItemPhoto(
          _venueId!,
          result.pickedPhoto!,
        );
      }

      final item = MenuItem(
        id: existing?.id ?? '',
        nameAr: result.nameAr,
        descriptionAr: result.descriptionAr,
        price: result.price,
        category: result.categoryId,
        photoUrl: photoUrl,
        isFeatured: result.isFeatured,
        isAvailable: result.isAvailable,
        sortOrder: existing?.sortOrder ?? 0,
      );

      if (existing == null) {
        await repo.addMenuItem(_venueId!, item, versionId: _draftVersionId);
      } else {
        await repo.updateMenuItem(_venueId!, item, versionId: _draftVersionId);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل حفظ العنصر: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _EditorResult {
  final String nameAr;
  final String descriptionAr;
  final double price;
  final String categoryId;
  final bool isAvailable;
  final bool isFeatured;
  final bool delete;
  final File? pickedPhoto;

  const _EditorResult({
    required this.nameAr,
    required this.descriptionAr,
    required this.price,
    required this.categoryId,
    required this.isAvailable,
    required this.isFeatured,
    required this.delete,
    required this.pickedPhoto,
  });
}

class _ItemEditorSheet extends StatefulWidget {
  final MenuItem? existing;
  final List<MenuSection> sections;

  const _ItemEditorSheet({required this.existing, required this.sections});

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late String _categoryId;
  late bool _isAvailable;
  late bool _isFeatured;
  File? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existing?.nameAr ?? '',
    );
    _descController = TextEditingController(
      text: widget.existing?.descriptionAr ?? '',
    );
    _priceController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.price.toStringAsFixed(0)
          : '',
    );
    _categoryId = widget.existing?.category ?? widget.sections.first.id;
    _isAvailable = widget.existing?.isAvailable ?? true;
    _isFeatured = widget.existing?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'إضافة عنصر' : 'تعديل عنصر'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'السعر'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _categoryId,
              items: widget.sections
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.nameAr)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoryId = v);
              },
            ),
            SwitchListTile(
              title: const Text('متوفر'),
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            SwitchListTile(
              title: const Text('مميز'),
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 900,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setState(() => _pickedPhoto = File(picked.path));
                  }
                },
                icon: const Icon(Icons.image),
                label: Text(
                  _pickedPhoto == null ? 'اختيار صورة' : 'تم اختيار صورة',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.existing != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        const _EditorResult(
                          nameAr: '',
                          descriptionAr: '',
                          price: 0,
                          categoryId: '',
                          isAvailable: true,
                          isFeatured: false,
                          delete: true,
                          pickedPhoto: null,
                        ),
                      ),
                      child: const Text('حذف'),
                    ),
                  ),
                if (widget.existing != null) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final price = double.tryParse(
                        _priceController.text.trim(),
                      );
                      if (name.isEmpty || price == null) return;
                      Navigator.pop(
                        context,
                        _EditorResult(
                          nameAr: name,
                          descriptionAr: _descController.text.trim(),
                          price: price,
                          categoryId: _categoryId,
                          isAvailable: _isAvailable,
                          isFeatured: _isFeatured,
                          delete: false,
                          pickedPhoto: _pickedPhoto,
                        ),
                      );
                    },
                    child: const Text('حفظ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
