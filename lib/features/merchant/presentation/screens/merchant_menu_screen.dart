import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wain_app/core/routing/navigation_extensions.dart';
import 'package:wain_app/core/theme/app_spacing.dart';
import 'package:wain_app/core/theme/app_theme.dart';
import 'package:wain_app/features/menu/data/repositories/menu_repository.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';

import '../providers/merchant_dashboard_providers.dart';
import 'package:wain_app/shared/widgets/wain_loading_indicator.dart';
import 'package:wain_app/l10n/app_localizations.dart';

const Map<String, String> _arabicIndicDigits = {
  '\u0660': '0',
  '\u0661': '1',
  '\u0662': '2',
  '\u0663': '3',
  '\u0664': '4',
  '\u0665': '5',
  '\u0666': '6',
  '\u0667': '7',
  '\u0668': '8',
  '\u0669': '9',
};

String _formatMenuPrice(double value) {
  if (!value.isFinite) return '0';
  if ((value - value.roundToDouble()).abs() < 0.000001) {
    return value.toStringAsFixed(0);
  }
  final digits = value.abs() < 1 ? 3 : 2;
  return value
      .toStringAsFixed(digits)
      .replaceFirst(RegExp(r'([.]\d*?)0+$'), r'$1')
      .replaceFirst(RegExp(r'[.]$'), '');
}

double? _parseMenuPrice(String raw) {
  if (raw.trim().isEmpty) return null;
  final normalizedDigits = raw.replaceAllMapped(
    RegExp(r'[\u0660-\u0669]'),
    (m) => _arabicIndicDigits[m.group(0)] ?? '',
  );
  final normalized = normalizedDigits
      .replaceAll(',', '.')
      .replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(normalized);
}

class MerchantMenuScreen extends ConsumerStatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  ConsumerState<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends ConsumerState<MerchantMenuScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  List<MenuSection> _sections = const [];
  Set<String> _persistedSectionIds = const <String>{};
  bool _tabRefreshScheduled = false;
  List<MenuSection>? _pendingTabSections;

  String? _venueId;
  String _venueCategory = '';
  String? _activeVersionId;
  String? _draftVersionId;
  String? _draftError;
  String? _draftInitKey;

  bool _isPreparingDraft = false;
  bool _isMutatingVersion = false;
  bool _autoPrepareDraft = true;
  final Set<String> _busyAvailabilityItemIds = <String>{};

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _setAvailabilityBusy(String itemId, bool busy) {
    if (!mounted) return;
    setState(() {
      if (busy) {
        _busyAvailabilityItemIds.add(itemId);
      } else {
        _busyAvailabilityItemIds.remove(itemId);
      }
    });
  }

  bool _sameSections(List<MenuSection> a, List<MenuSection> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i].id != b[i].id ||
          a[i].nameAr != b[i].nameAr ||
          a[i].sortOrder != b[i].sortOrder) {
        return false;
      }
    }
    return true;
  }

  void _syncTabs(List<MenuSection> nextSections) {
    final normalized = [...nextSections]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (_sameSections(_sections, normalized)) {
      return;
    }

    _pendingTabSections = normalized;
    if (_tabRefreshScheduled) return;
    _tabRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabRefreshScheduled = false;
      if (!mounted) return;

      final targetSections = _pendingTabSections;
      _pendingTabSections = null;
      if (targetSections == null) return;
      if (_sameSections(_sections, targetSections)) return;

      final previousIndex = _tabController?.index ?? 0;
      _tabController?.dispose();

      if (targetSections.isEmpty) {
        _tabController = null;
        _sections = const [];
      } else {
        _sections = targetSections;
        final initialIndex = previousIndex.clamp(0, targetSections.length - 1);
        _tabController = TabController(
          length: targetSections.length,
          vsync: this,
          initialIndex: initialIndex,
        );
      }

      setState(() {});
    });
  }

  String _humanizeCategoryId(String value, AppLocalizations l10n) {
    final normalized = value.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return l10n.menuSectionOther;
    return normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  List<MenuSection> _mergeSectionsWithItemCategories(
    List<MenuSection> baseSections,
    List<MenuItem> items,
    AppLocalizations l10n,
  ) {
    if (items.isEmpty) return baseSections;

    final existingById = {
      for (final section in baseSections) section.id: section,
    };
    final merged = [...baseSections];

    final missingCategoryIds =
        items
            .map((item) => item.category.trim())
            .where(
              (categoryId) =>
                  categoryId.isNotEmpty &&
                  !existingById.containsKey(categoryId),
            )
            .toSet()
            .toList()
          ..sort();

    for (var i = 0; i < missingCategoryIds.length; i += 1) {
      final categoryId = missingCategoryIds[i];
      final fallbackName = _humanizeCategoryId(categoryId, l10n);
      merged.add(
        MenuSection(
          id: categoryId,
          nameAr: fallbackName,
          nameEn: fallbackName,
          icon: 'restaurant_menu',
          sortOrder: 1000 + i,
        ),
      );
    }

    merged.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return merged;
  }

  String _normalizeCategoryKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  bool _categoryMatchesSection(String categoryId, String sectionId) {
    if (categoryId == sectionId) return true;
    return _normalizeCategoryKey(categoryId) ==
        _normalizeCategoryKey(sectionId);
  }

  String _effectiveItemCategory(String categoryId) {
    final trimmed = categoryId.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (_sections.isNotEmpty) return _sections.first.id;
    return 'other';
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
          _draftError = AppLocalizations.of(context)!.menuErrorNotMerchant;
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.menuDraftPublished),
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
          content: Text(
            AppLocalizations.of(context)!.menuDraftPublishFailed(e.toString()),
          ),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.menuNoArchivedVersions),
        ),
      );
      return;
    }

    final selected = await showDialog<MenuVersionSummary>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.menuSelectArchivedVersion),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.menuRollbackSuccess),
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
          content: Text(
            AppLocalizations.of(context)!.menuRollbackFailed(e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openSectionManager() async {
    if (_venueId == null || _draftVersionId == null || _sections.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final editableSections = _sections
        .where((section) => _persistedSectionIds.contains(section.id))
        .toList();
    if (editableSections.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.menuNoEditableSections)));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        var sheetSections = List<MenuSection>.from(editableSections);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.menuManageSections,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _addSection();
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.menuAdd),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        itemCount: sheetSections.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = sheetSections.removeAt(oldIndex);
                          sheetSections.insert(newIndex, item);
                          setSheetState(() {});

                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          try {
                            await ref
                                .read(menuRepositoryProvider)
                                .reorderMenuSections(
                                  venueId: _venueId!,
                                  versionId: _draftVersionId!,
                                  orderedSections: sheetSections,
                                );
                          } catch (e) {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.menuReorderFailed(e.toString()),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        itemBuilder: (_, index) {
                          final section = sheetSections[index];
                          return Card(
                            key: ValueKey(section.id),
                            margin: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 8,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              dense: true,
                              title: Text(section.nameAr),
                              subtitle: Text(section.id),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: l10n.menuRename,
                                    onPressed: () {
                                      Navigator.pop(sheetContext);
                                      _renameSection(section);
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: l10n.menuDelete,
                                    onPressed: sheetSections.length <= 1
                                        ? null
                                        : () {
                                            Navigator.pop(sheetContext);
                                            _deleteSection(section);
                                          },
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _promptSectionName({
    required String title,
    String initialValue = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) =>
                Navigator.pop(dialogContext, controller.text.trim()),
            decoration: InputDecoration(hintText: l10n.menuSectionNameHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.menuCancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: Text(l10n.menuSave),
            ),
          ],
        );
      },
    );

    controller.dispose();
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> _addSection() async {
    if (_venueId == null || _draftVersionId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final name = await _promptSectionName(title: l10n.menuAddSectionTitle);
    if (name == null) return;

    try {
      await ref
          .read(menuRepositoryProvider)
          .addMenuSection(
            venueId: _venueId!,
            versionId: _draftVersionId!,
            nameAr: name,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.menuSectionAdded),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.menuSectionAddFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renameSection(MenuSection section) async {
    if (_venueId == null || _draftVersionId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final name = await _promptSectionName(
      title: l10n.menuRenameSectionTitle,
      initialValue: section.nameAr,
    );
    if (name == null || name == section.nameAr) return;

    try {
      await ref
          .read(menuRepositoryProvider)
          .updateMenuSection(
            venueId: _venueId!,
            versionId: _draftVersionId!,
            sectionId: section.id,
            nameAr: name,
            icon: section.icon,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.menuSectionUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.menuSectionUpdateFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteSection(MenuSection section) async {
    if (_venueId == null || _draftVersionId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final editableSections = _sections
        .where((s) => _persistedSectionIds.contains(s.id))
        .toList();
    final fallbackSections = editableSections
        .where((s) => s.id != section.id)
        .toList();
    if (fallbackSections.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.menuKeepOneSection)));
      return;
    }

    var fallbackId = fallbackSections.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l10n.menuDeleteSectionTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.menuDeleteSectionConfirm(section.nameAr)),
                  const SizedBox(height: 10),
                  Text(l10n.menuMoveItemsTo),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: fallbackId,
                    items: fallbackSections
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nameAr),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setStateDialog(() => fallbackId = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.menuCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.menuDelete),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(menuRepositoryProvider)
          .deleteMenuSection(
            venueId: _venueId!,
            versionId: _draftVersionId!,
            sectionId: section.id,
            fallbackSectionId: fallbackId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.menuSectionDeleted),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.menuSectionDeleteFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final venueAsync = ref.watch(merchantVenueProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/merchant/dashboard'),
        ),
        title: Text(l10n.menuManageMenuTitle),
        actions: [
          IconButton(
            onPressed:
                (_draftVersionId != null &&
                    !_isPreparingDraft &&
                    !_isMutatingVersion)
                ? _openSectionManager
                : null,
            icon: const Icon(Icons.category_outlined),
            tooltip: l10n.menuManageCategoriesTooltip,
          ),
          IconButton(
            onPressed:
                (_draftVersionId != null &&
                    !_isPreparingDraft &&
                    !_isMutatingVersion)
                ? _publishDraft
                : null,
            icon: const Icon(Icons.publish),
            tooltip: l10n.menuPublishDraftTooltip,
          ),
          IconButton(
            onPressed: (_venueId != null && !_isMutatingVersion)
                ? _rollbackToArchivedVersion
                : null,
            icon: const Icon(Icons.history),
            tooltip: l10n.menuRollbackTooltip,
          ),
        ],
        bottom: _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
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
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.add, color: colorScheme.onPrimary),
            )
          : null,
      body: venueAsync.when(
        loading: () => const Center(child: WainLoadingIndicator()),
        error: (e, _) => Center(child: Text(l10n.menuError(e.toString()))),
        data: (venue) {
          if (venue == null) {
            return Center(child: Text(l10n.menuNoVenueLinked));
          }

          _venueId = venue['id'] as String;
          final categories =
              (venue['categories'] as List?)?.cast<String>() ?? [];
          final venueCategory = categories.isNotEmpty
              ? categories.first
              : 'restaurant';
          _venueCategory = venueCategory;
          if (_autoPrepareDraft) {
            _ensureDraftPrepared(_venueId!, venueCategory);
          }

          if (_isPreparingDraft || _draftVersionId == null) {
            return const Center(child: WainLoadingIndicator());
          }

          if (_draftError != null) {
            return Center(
              child: Text(l10n.menuDraftPrepareFailed(_draftError!)),
            );
          }

          if (_draftVersionId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.menuDraftPublishedCreateNew,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isMutatingVersion ? null : _startNewDraft,
                      child: Text(l10n.menuCreateNewDraftBtn),
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
          final sectionsAsync = ref.watch(
            menuVersionSectionsProvider(
              MenuVersionSectionsQuery(
                venueId: _venueId!,
                versionId: _draftVersionId!,
                venueCategory: venueCategory,
              ),
            ),
          );

          return sectionsAsync.when(
            loading: () => const Center(child: WainLoadingIndicator()),
            error: (e, _) =>
                Center(child: Text(l10n.menuSectionsError(e.toString()))),
            data: (sections) {
              final fallbackSections = ref.read(
                menuSectionsProvider(venueCategory),
              );
              final baseSections = sections.isEmpty
                  ? fallbackSections
                  : sections;
              _persistedSectionIds = baseSections
                  .map((section) => section.id)
                  .toSet();
              final currentItems =
                  itemsAsync.asData?.value ?? const <MenuItem>[];
              final mergedSections = _mergeSectionsWithItemCategories(
                baseSections,
                currentItems,
                l10n,
              );
              _syncTabs(mergedSections);

              if (_tabController == null || _sections.isEmpty) {
                return Center(child: Text(l10n.menuNoSectionsAvailable));
              }

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppTheme.warningColor.withAlpha(18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      _activeVersionId == null
                          ? l10n.menuEditingUnpublishedDraft
                          : l10n.menuEditingDraftOverActive(_activeVersionId!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                (_draftVersionId != null &&
                                    !_isPreparingDraft &&
                                    !_isMutatingVersion)
                                ? _openSectionManager
                                : null,
                            icon: const Icon(Icons.category_outlined),
                            label: Text(l10n.menuManageSectionsBtn),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                (_draftVersionId != null &&
                                    !_isPreparingDraft &&
                                    !_isMutatingVersion)
                                ? _addSection
                                : null,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.menuAddSectionBtn),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: itemsAsync.when(
                      loading: () =>
                          const Center(child: WainLoadingIndicator()),
                      error: (e, _) =>
                          Center(child: Text(l10n.menuError(e.toString()))),
                      data: (items) {
                        if (items.isEmpty) {
                          return Center(
                            child: Text(l10n.menuEmptyAddFirstItem),
                          );
                        }
                        return TabBarView(
                          controller: _tabController,
                          children: _sections.map((section) {
                            final sectionItems =
                                items
                                    .where(
                                      (i) => _categoryMatchesSection(
                                        _effectiveItemCategory(i.category),
                                        section.id,
                                      ),
                                    )
                                    .toList()
                                  ..sort(
                                    (a, b) =>
                                        a.sortOrder.compareTo(b.sortOrder),
                                  );
                            if (sectionItems.isEmpty) {
                              return Center(
                                child: Text(
                                  l10n.menuNoItemsInSection(section.nameAr),
                                ),
                              );
                            }
                            return ReorderableListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: sectionItems.length,
                              onReorder: (oldIndex, newIndex) async {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = sectionItems.removeAt(oldIndex);
                                sectionItems.insert(newIndex, item);

                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                try {
                                  await ref
                                      .read(menuRepositoryProvider)
                                      .reorderMenuItems(
                                        venueId: _venueId!,
                                        versionId: _draftVersionId,
                                        orderedItems: sectionItems,
                                      );
                                } catch (e) {
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.menuReorderItemsFailed(
                                            e.toString(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (_, i) {
                                final item = sectionItems[i];
                                return _buildItemCard(
                                  item,
                                  key: ValueKey(item.id),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
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

  Widget _buildItemCard(MenuItem item, {Key? key}) {
    return Card(
      key: key,
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
        title: Row(
          children: [
            Expanded(child: Text(item.nameAr)),
            if (item.source == 'ocr')
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.brandAiBadge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text('${_formatMenuPrice(item.price)} ${item.currency}'),
        trailing: Switch(
          value: item.isAvailable,
          onChanged:
              _busyAvailabilityItemIds.contains(item.id) ||
                  _venueId == null ||
                  _draftVersionId == null
              ? null
              : (val) async {
                  _setAvailabilityBusy(item.id, true);
                  try {
                    await ref
                        .read(menuRepositoryProvider)
                        .toggleAvailability(
                          _venueId!,
                          item.id,
                          val,
                          versionId: _draftVersionId,
                        );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.menuItemAvailabilityFailed(e.toString()),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    _setAvailabilityBusy(item.id, false);
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.menuItemDeleted),
            backgroundColor: Colors.green,
          ),
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
        source: 'manual', // Overwrite source to manual upon edit/save
      );

      if (existing == null) {
        await repo.addMenuItem(_venueId!, item, versionId: _draftVersionId);
      } else {
        await repo.updateMenuItem(_venueId!, item, versionId: _draftVersionId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.menuItemSaved),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.menuSaveItemFailed(e.toString()),
          ),
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
          ? _formatMenuPrice(widget.existing!.price)
          : '',
    );
    final existingCategory = widget.existing?.category.trim();
    _categoryId = (existingCategory != null && existingCategory.isNotEmpty)
        ? existingCategory
        : widget.sections.first.id;
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.existing == null
                  ? l10n.menuAddItemTitle
                  : l10n.menuEditItemTitle,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.menuItemNameLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: l10n.menuItemDescLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.menuItemPriceLabel),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
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
              title: Text(l10n.menuItemAvailableToggle),
              value: _isAvailable,
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
            SwitchListTile(
              title: Text(l10n.menuItemFeaturedToggle),
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
                  _pickedPhoto == null
                      ? l10n.menuItemChooseImage
                      : l10n.menuItemImageSelected,
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
                      child: Text(l10n.menuDelete),
                    ),
                  ),
                if (widget.existing != null) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final price = _parseMenuPrice(
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
                    child: Text(l10n.menuSave),
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
