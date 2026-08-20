import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/demo/application/demo_merchant_session.dart';
import 'package:wain_app/features/demo/application/demo_session_store.dart';
import 'package:wain_app/features/demo/data/demo_menu_repository.dart';
import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/data/demo_menu_catalog.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/presentation/providers/menu_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late DemoMenuRepository repository;

  setUp(() {
    container = ProviderContainer();
    container.read(demoMerchantSessionProvider.notifier).enter();
    repository = container.read(menuRepositoryProvider) as DemoMenuRepository;
    addTearDown(container.dispose);
  });

  test('merchant menu repository is Firebase-free and stateful', () async {
    final draft = await repository.ensureDraftVersion(
      venueId: DemoMode.venueId,
      venueCategory: 'cafe',
      merchantUid: 'demo-owner',
    );
    final sectionId = await repository.addMenuSection(
      venueId: DemoMode.venueId,
      versionId: draft.draftVersionId,
      nameAr: 'إضافات الديمو',
      nameEn: 'Demo extras',
      icon: 'add_circle',
    );
    final itemId = await repository.addMenuItem(
      DemoMode.venueId,
      MenuItem(
        id: 'ignored-by-local-store',
        nameAr: 'صنف تجريبي جديد',
        nameEn: 'New demo item',
        descriptionAr: 'يظهر فورًا داخل جلسة العرض',
        price: 18,
        category: sectionId,
      ),
      versionId: draft.draftVersionId,
    );

    expect(
      (await repository
              .watchMenuSectionsForVersion(
                DemoMode.venueId,
                draft.draftVersionId,
              )
              .first)
          .any((section) => section.id == sectionId),
      isTrue,
    );
    expect(
      (await repository
              .watchMenuItemsForVersion(DemoMode.venueId, draft.draftVersionId)
              .first)
          .any((item) => item.id == itemId),
      isTrue,
    );

    await repository.toggleAvailability(
      DemoMode.venueId,
      itemId,
      false,
      versionId: draft.draftVersionId,
    );
    expect(
      (await repository.getMenuItems(
        DemoMode.venueId,
      )).firstWhere((item) => item.id == itemId).isAvailable,
      isFalse,
    );

    final beforePublish = DateTime.now();
    await repository.publishDraftVersion(
      venueId: DemoMode.venueId,
      merchantUid: 'demo-owner',
    );
    final versions = await repository.listMenuVersions(DemoMode.venueId);
    expect(
      versions.first.publishedAt!.toDate().isBefore(beforePublish),
      isFalse,
    );
  });

  test(
    'Reset Demo restores the catalog and the rolling publish timestamp',
    () async {
      final initialCount = demoMenuItems.length;
      final draft = await repository.ensureDraftVersion(
        venueId: DemoMode.venueId,
        venueCategory: 'cafe',
        merchantUid: 'demo-owner',
      );
      await repository.addMenuItem(
        DemoMode.venueId,
        MenuItem(
          id: 'temporary',
          nameAr: 'مؤقت',
          price: 1,
          category: demoMenuSections.first.id,
        ),
        versionId: draft.draftVersionId,
      );
      expect(
        await repository.getMenuItems(DemoMode.venueId),
        hasLength(initialCount + 1),
      );

      container.read(demoSessionStoreProvider.notifier).reset();
      repository = container.read(menuRepositoryProvider) as DemoMenuRepository;

      expect(
        await repository.getMenuItems(DemoMode.venueId),
        hasLength(initialCount),
      );
      final resetVersion = (await repository.listMenuVersions(
        DemoMode.venueId,
      )).first;
      final resetPublishedAt = resetVersion.publishedAt!.toDate();
      expect(
        DateTime.now().difference(resetPublishedAt).inDays,
        4,
        reason: 'catalog freshness rolls with the real clock',
      );
    },
  );
}
