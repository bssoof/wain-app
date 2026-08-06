import 'package:wain_app/features/demo/demo_mode.dart';
import 'package:wain_app/features/menu/domain/entities/menu_item.dart';
import 'package:wain_app/features/menu/domain/entities/menu_section.dart';

/// The demo menu is served for the standalone demo venue only — never for a
/// published shop. See [DemoMode].
const String demoMenuVenueId = DemoMode.venueId;
const String demoMenuVenueName = DemoMode.venueNameAr;

bool shouldUseDemoMenu(String venueId) {
  return DemoMode.isDemoVenue(venueId);
}

const String _img = 'asset://assets/images/demo_menu';

const List<MenuSection> demoMenuSections = <MenuSection>[
  MenuSection(
    id: 'hot_drinks',
    nameAr: 'مشروبات ساخنة',
    nameEn: 'Hot Drinks',
    icon: 'coffee',
    sortOrder: 1,
  ),
  MenuSection(
    id: 'specialty_coffee',
    nameAr: 'قهوة مختصة',
    nameEn: 'Specialty Coffee',
    icon: 'coffee_maker',
    sortOrder: 2,
  ),
  MenuSection(
    id: 'cold_drinks',
    nameAr: 'مشروبات باردة',
    nameEn: 'Cold Drinks',
    icon: 'local_drink',
    sortOrder: 3,
  ),
  MenuSection(
    id: 'juices',
    nameAr: 'عصائر وموهيتو',
    nameEn: 'Juices & Mojito',
    icon: 'local_bar',
    sortOrder: 4,
  ),
  MenuSection(
    id: 'desserts',
    nameAr: 'حلويات',
    nameEn: 'Desserts',
    icon: 'cake',
    sortOrder: 5,
  ),
  MenuSection(
    id: 'breakfast',
    nameAr: 'فطور ووجبات خفيفة',
    nameEn: 'Breakfast & Light Bites',
    icon: 'brunch_dining',
    sortOrder: 6,
  ),
];

/// 24 available items across 6 sections, plus one deliberately unavailable item
/// so the merchant surface has something to show that the customer must not
/// see.
///
/// LIMITATION — the project ships 10 café photographs, so a photo is reused
/// across items that genuinely look alike (a latte shot on both "لاتيه" and
/// "فلات وايت"). Every item still resolves to a real local asset; none falls
/// back to a grey placeholder. Drop 14 more photos into
/// `assets/images/demo_menu/` and repoint the `photoUrl`s to make each item
/// unique.
const List<MenuItem> demoMenuItems = <MenuItem>[
  // ---------------------------------------------------------------- hot
  MenuItem(
    id: 'demo_latte',
    nameAr: 'كافيه لاتيه',
    nameEn: 'Cafe Latte',
    descriptionAr: 'إسبريسو غني مع حليب مبخر ورغوة مخملية',
    price: 15,
    category: 'hot_drinks',
    photoUrl: '$_img/cafe_latte.jpg',
    isFeatured: true,
    sortOrder: 1,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_cappuccino',
    nameAr: 'كابتشينو',
    nameEn: 'Cappuccino',
    descriptionAr: 'إسبريسو كلاسيكي مع رغوة حليب كثيفة ورشة كاكاو',
    price: 14,
    category: 'hot_drinks',
    photoUrl: '$_img/cappuccino.jpg',
    sortOrder: 2,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_flat_white',
    nameAr: 'فلات وايت',
    nameEn: 'Flat White',
    descriptionAr: 'جرعتا إسبريسو مع حليب مبخر ناعم وطبقة رغوة رفيعة',
    price: 16,
    category: 'hot_drinks',
    photoUrl: '$_img/cafe_latte.jpg',
    sortOrder: 3,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_mint_tea',
    nameAr: 'شاي بالنعناع',
    nameEn: 'Mint Tea',
    descriptionAr: 'شاي أسود مع نعناع طازج يقدم في إبريق صغير',
    price: 10,
    category: 'hot_drinks',
    photoUrl: '$_img/lemon_mint.jpg',
    sortOrder: 4,
    source: 'demo',
  ),

  // --------------------------------------------------------- specialty
  MenuItem(
    id: 'demo_v60',
    nameAr: 'في 60',
    nameEn: 'V60 Pour Over',
    descriptionAr: 'تقطير يدوي لحبوب مختصة بنكهات فاكهية واضحة',
    price: 22,
    category: 'specialty_coffee',
    photoUrl: '$_img/cafe_latte.jpg',
    sortOrder: 1,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_cold_brew',
    nameAr: 'كولد برو',
    nameEn: 'Cold Brew',
    descriptionAr: 'قهوة منقوعة على البارد 18 ساعة، خفيفة الحموضة',
    price: 20,
    category: 'specialty_coffee',
    photoUrl: '$_img/iced_spanish_latte.jpg',
    isFeatured: true,
    sortOrder: 2,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_cortado',
    nameAr: 'كورتادو',
    nameEn: 'Cortado',
    descriptionAr: 'إسبريسو مع كمية مساوية من الحليب المبخر',
    price: 17,
    category: 'specialty_coffee',
    photoUrl: '$_img/cappuccino.jpg',
    sortOrder: 3,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_double_espresso',
    nameAr: 'إسبريسو مزدوج',
    nameEn: 'Double Espresso',
    descriptionAr: 'جرعتان مركزتان بكريما ذهبية كثيفة',
    price: 13,
    category: 'specialty_coffee',
    photoUrl: '$_img/cappuccino.jpg',
    sortOrder: 4,
    source: 'demo',
  ),

  // -------------------------------------------------------------- cold
  MenuItem(
    id: 'demo_iced_spanish_latte',
    nameAr: 'سبانش لاتيه بارد',
    nameEn: 'Iced Spanish Latte',
    descriptionAr: 'حليب بارد محلى مع إسبريسو وثلج',
    price: 19,
    category: 'cold_drinks',
    photoUrl: '$_img/iced_spanish_latte.jpg',
    isFeatured: true,
    sortOrder: 1,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_iced_latte',
    nameAr: 'آيس لاتيه',
    nameEn: 'Iced Latte',
    descriptionAr: 'إسبريسو مع حليب بارد وثلج مجروش',
    price: 17,
    category: 'cold_drinks',
    photoUrl: '$_img/cafe_latte.jpg',
    sortOrder: 2,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_iced_mocha',
    nameAr: 'آيس موكا',
    nameEn: 'Iced Mocha',
    descriptionAr: 'إسبريسو وشوكولاتة مع حليب بارد وكريمة',
    price: 21,
    category: 'cold_drinks',
    photoUrl: '$_img/cappuccino.jpg',
    sortOrder: 3,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_mint_lemonade',
    nameAr: 'ليموناضة بالنعناع',
    nameEn: 'Mint Lemonade',
    descriptionAr: 'ليمون طازج مخفوق مع نعناع وثلج',
    price: 16,
    category: 'cold_drinks',
    photoUrl: '$_img/lemon_mint.jpg',
    sortOrder: 4,
    source: 'demo',
  ),
  // Hidden from customers on purpose — visible in the merchant surface only.
  MenuItem(
    id: 'demo_caramel_frappuccino',
    nameAr: 'فرابتشينو كراميل',
    nameEn: 'Caramel Frappuccino',
    descriptionAr: 'مشروب مثلج بالكراميل — غير متوفر حاليًا',
    price: 23,
    category: 'cold_drinks',
    photoUrl: '$_img/iced_spanish_latte.jpg',
    isAvailable: false,
    sortOrder: 5,
    source: 'demo',
  ),

  // ------------------------------------------------------------ juices
  MenuItem(
    id: 'demo_orange_juice',
    nameAr: 'عصير برتقال طازج',
    nameEn: 'Fresh Orange Juice',
    descriptionAr: 'برتقال طازج معصور عند الطلب',
    price: 16,
    category: 'juices',
    photoUrl: '$_img/orange_juice.jpg',
    isFeatured: true,
    sortOrder: 1,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_lemon_mint',
    nameAr: 'ليمون ونعنع',
    nameEn: 'Lemon Mint',
    descriptionAr: 'ليمون طازج ونعنع مع ثلج مجروش',
    price: 17,
    category: 'juices',
    photoUrl: '$_img/lemon_mint.jpg',
    sortOrder: 2,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_berry_mojito',
    nameAr: 'موهيتو التوت',
    nameEn: 'Berry Mojito',
    descriptionAr: 'توت طازج مع ليمون ونعناع وثلج مجروش',
    price: 18,
    category: 'juices',
    photoUrl: '$_img/berry_mojito.jpg',
    sortOrder: 3,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_fruit_cocktail',
    nameAr: 'كوكتيل فواكه',
    nameEn: 'Fruit Cocktail',
    descriptionAr: 'طبقات من عصائر الفواكه الموسمية',
    price: 20,
    category: 'juices',
    photoUrl: '$_img/orange_juice.jpg',
    sortOrder: 4,
    source: 'demo',
  ),

  // ---------------------------------------------------------- desserts
  MenuItem(
    id: 'demo_san_sebastian',
    nameAr: 'تشيز كيك سان سباستيان',
    nameEn: 'San Sebastian Cheesecake',
    descriptionAr: 'تشيز كيك مخبوز بقلب كريمي غني',
    price: 24,
    category: 'desserts',
    photoUrl: '$_img/san_sebastian.jpg',
    isFeatured: true,
    sortOrder: 1,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_belgian_waffle',
    nameAr: 'وافل بلجيكي',
    nameEn: 'Belgian Waffle',
    descriptionAr: 'وافل مع فواكه طازجة وشوكولاتة وبوظة فانيلا',
    price: 26,
    category: 'desserts',
    photoUrl: '$_img/belgian_waffle.jpg',
    sortOrder: 2,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_brownie',
    nameAr: 'براوني بالآيس كريم',
    nameEn: 'Brownie à la Mode',
    descriptionAr: 'براوني دافئ مع كرة آيس كريم وصوص شوكولاتة',
    price: 25,
    category: 'desserts',
    photoUrl: '$_img/san_sebastian.jpg',
    sortOrder: 3,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_pancake',
    nameAr: 'بانكيك بالعسل',
    nameEn: 'Honey Pancakes',
    descriptionAr: 'ثلاث طبقات بانكيك مع عسل وزبدة',
    price: 23,
    category: 'desserts',
    photoUrl: '$_img/belgian_waffle.jpg',
    sortOrder: 4,
    source: 'demo',
  ),

  // --------------------------------------------------------- breakfast
  MenuItem(
    id: 'demo_club_sandwich',
    nameAr: 'كلوب ساندويش دجاج',
    nameEn: 'Chicken Club Sandwich',
    descriptionAr: 'دجاج مشوي وخضار طازجة مع بطاطا مقلية',
    price: 32,
    category: 'breakfast',
    photoUrl: '$_img/club_sandwich.jpg',
    isFeatured: true,
    sortOrder: 1,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_caesar_salad',
    nameAr: 'سلطة سيزر بالدجاج',
    nameEn: 'Chicken Caesar Salad',
    descriptionAr: 'خس طازج ودجاج مشوي وبارميزان وكروتون',
    price: 29,
    category: 'breakfast',
    photoUrl: '$_img/caesar_salad.jpg',
    sortOrder: 2,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_english_breakfast',
    nameAr: 'فطور إنجليزي',
    nameEn: 'English Breakfast',
    descriptionAr: 'بيض وحلومي وفول وخبز محمص وخضار',
    price: 38,
    category: 'breakfast',
    photoUrl: '$_img/club_sandwich.jpg',
    sortOrder: 3,
    source: 'demo',
  ),
  MenuItem(
    id: 'demo_avocado_toast',
    nameAr: 'توست أفوكادو',
    nameEn: 'Avocado Toast',
    descriptionAr: 'خبز الحبوب الكاملة مع أفوكادو وبيض مسلوق',
    price: 30,
    category: 'breakfast',
    photoUrl: '$_img/caesar_salad.jpg',
    sortOrder: 4,
    source: 'demo',
  ),
];
