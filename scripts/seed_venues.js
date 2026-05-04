/**
 * seed_venues.js
 * يملأ المحاكي المحلي بـ 15 كافيه/مطعم/جهة واقعية في فلسطين
 * يستخدم Firebase Admin SDK الذي يتجاوز Firestore Security Rules
 */

// Point Admin SDK at emulators
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "wain-d2e28" });
const db = admin.firestore();

const venues = [
  {
    name_ar: "كافيه زمان",
    name_en: "Zaman Cafe",
    city: "رام الله",
    lat: 31.9038,
    lng: 35.2034,
    categories: ["cafe", "dessert"],
    phone: "022963001",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "كافيه زمان - أجواء تراثية فلسطينية مع أفضل القهوة العربية",
    description_en: "Zaman Cafe - Traditional Palestinian vibes with the best Arabic coffee",
  },
  {
    name_ar: "مقهى الفنجان الذهبي",
    name_en: "Golden Cup Cafe",
    city: "رام الله",
    lat: 31.9025,
    lng: 35.2050,
    categories: ["cafe"],
    phone: "022961122",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "قهوة مختصة وأجواء هادئة في قلب رام الله",
    description_en: "Specialty coffee and calm atmosphere in the heart of Ramallah",
  },
  {
    name_ar: "مطعم بيتنا",
    name_en: "Baituna Restaurant",
    city: "رام الله",
    lat: 31.9010,
    lng: 35.2065,
    categories: ["restaurant", "traditional"],
    phone: "022965500",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "أكل بيتي فلسطيني أصيل - مسخن، مقلوبة، منسف",
    description_en: "Authentic Palestinian home cooking",
  },
  {
    name_ar: "بوظة عارف",
    name_en: "Aref Ice Cream",
    city: "نابلس",
    lat: 32.2211,
    lng: 35.2544,
    categories: ["dessert", "ice_cream"],
    phone: "092371234",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "بوظة نابلسية أصلية منذ 1950",
    description_en: "Original Nablus ice cream since 1950",
  },
  {
    name_ar: "كنافة الأقصى",
    name_en: "Al-Aqsa Knafeh",
    city: "نابلس",
    lat: 32.2225,
    lng: 35.2610,
    categories: ["dessert", "traditional"],
    phone: "092375678",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "أشهر كنافة نابلسية - الطعم الأصلي",
    description_en: "The most famous Nablus knafeh",
  },
  {
    name_ar: "كافيه لاتيه آرت",
    name_en: "Latte Art Cafe",
    city: "بيت لحم",
    lat: 31.7054,
    lng: 35.2024,
    categories: ["cafe", "brunch"],
    phone: "022742200",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "كافيه عصري في بيت لحم مع أفضل اللاتيه آرت",
    description_en: "Modern cafe in Bethlehem with the best latte art",
  },
  {
    name_ar: "مطعم السلطان",
    name_en: "Sultan Restaurant",
    city: "الخليل",
    lat: 31.5326,
    lng: 35.0998,
    categories: ["restaurant", "grill"],
    phone: "022291100",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "expired",
    description_ar: "مشاوي ومأكولات شرقية فاخرة",
    description_en: "Premium grills and oriental cuisine",
  },
  {
    name_ar: "شاي وسكر",
    name_en: "Tea & Sugar",
    city: "جنين",
    lat: 32.4610,
    lng: 35.2953,
    categories: ["cafe", "tea"],
    phone: "042501234",
    operational_status: "active",
    visibility_status: "hidden",
    subscription_status: "active",
    description_ar: "بيت الشاي الفلسطيني - أكثر من 30 نوع شاي",
    description_en: "Palestinian tea house - over 30 tea varieties",
  },
  {
    name_ar: "مقهى البلد",
    name_en: "Al-Balad Cafe",
    city: "رام الله",
    lat: 31.8995,
    lng: 35.2040,
    categories: ["cafe", "hookah"],
    phone: "022964400",
    operational_status: "suspended",
    visibility_status: "hidden",
    subscription_status: "active",
    description_ar: "مقهى شعبي في البلدة القديمة",
    description_en: "Popular cafe in the old town",
  },
  {
    name_ar: "بيتزا تايم",
    name_en: "Pizza Time",
    city: "رام الله",
    lat: 31.9055,
    lng: 35.2080,
    categories: ["restaurant", "pizza", "fast_food"],
    phone: "022967788",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "بيتزا إيطالية أصلية بمكونات طازجة",
    description_en: "Authentic Italian pizza with fresh ingredients",
  },
  {
    name_ar: "عصير الجنة",
    name_en: "Paradise Juice",
    city: "نابلس",
    lat: 32.2200,
    lng: 35.2595,
    categories: ["juice", "healthy"],
    phone: "092379999",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "عصائر طبيعية طازجة وسموذي صحي",
    description_en: "Fresh natural juices and healthy smoothies",
  },
  {
    name_ar: "مخبز الطابون",
    name_en: "Taboun Bakery",
    city: "بيت لحم",
    lat: 31.7040,
    lng: 35.2040,
    categories: ["bakery", "traditional"],
    phone: "022743300",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "paused",
    description_ar: "خبز طابون ومعجنات فلسطينية تقليدية",
    description_en: "Taboun bread and traditional Palestinian pastries",
  },
  {
    name_ar: "كافيه سيراميك",
    name_en: "Ceramic Cafe",
    city: "رام الله",
    lat: 31.9042,
    lng: 35.2015,
    categories: ["cafe", "art"],
    phone: "022968800",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "ارسم على السيراميك واستمتع بقهوتك - تجربة فريدة",
    description_en: "Paint ceramics and enjoy your coffee - unique experience",
  },
  {
    name_ar: "برجر هاوس",
    name_en: "Burger House",
    city: "رام الله",
    lat: 31.9060,
    lng: 35.2025,
    categories: ["restaurant", "burger", "fast_food"],
    phone: "022969900",
    operational_status: "active",
    visibility_status: "visible",
    subscription_status: "active",
    description_ar: "أفضل برجر في رام الله - لحم أنغوس طازج",
    description_en: "Best burgers in Ramallah - fresh Angus beef",
  },
  {
    name_ar: "حلويات العلامي",
    name_en: "Al-Alami Sweets",
    city: "الخليل",
    lat: 31.5290,
    lng: 35.0955,
    categories: ["dessert", "traditional"],
    phone: "022222333",
    operational_status: "archived",
    visibility_status: "hidden",
    subscription_status: "expired",
    description_ar: "حلويات شرقية تقليدية - بقلاوة، معمول، هريسة",
    description_en: "Traditional oriental sweets",
  },
];

async function main() {
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("  🏪 ملء المحاكي المحلي بـ 15 جهة واقعية");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("");

  let success = 0;
  let fail = 0;

  for (let i = 0; i < venues.length; i++) {
    const venue = venues[i];
    try {
      const now = admin.firestore.Timestamp.now();
      const doc = {
        ...venue,
        created_at: now,
        updated_at: now,
        has_offers: Math.random() > 0.5,
        offer_count: Math.floor(Math.random() * 5),
        review_count: Math.floor(Math.random() * 50),
        average_rating: +(3.5 + Math.random() * 1.5).toFixed(1),
      };

      const ref = await db.collection("venues").add(doc);
      console.log(`✅ ${i + 1}. ${venue.name_ar} (${venue.name_en}) → ${ref.id}`);
      success++;
    } catch (err) {
      console.error(`❌ فشل إضافة "${venue.name_ar}":`, err.message);
      fail++;
    }
  }

  console.log("");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log(`  ✅ نجح: ${success} | ❌ فشل: ${fail}`);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("");
  console.log("  🎉 افتح اللوحة على http://localhost:3011/admin/venues");
  console.log("  واضغط تحديث (F5) لترى الجهات الجديدة!");

  process.exit(0);
}

main().catch((err) => {
  console.error("خطأ عام:", err);
  process.exit(1);
});
