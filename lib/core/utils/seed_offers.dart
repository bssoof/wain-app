import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seed trial offers (Run this once)
Future<void> seedOffers() async {
  final firestore = FirebaseFirestore.instance;
  final offersRef = firestore.collection('offers');

  // 1. Darna Restaurant Offer
  // darna_01 (Assuming this venue exists from previous context)
  await offersRef.doc('offer_darna_01').set({
    'venue_id': 'darna_01',
    'title_ar': 'خصم خاص 15% على الفطور',
    'title_en': '15% Off Breakfast',
    'description_ar':
        'احصل على خصم 15% على جميع وجبات الفطور عند الطلب قبل الساعة 11 صباحاً.',
    'description_en':
        'Get 15% off all breakfast items when ordering before 11 AM.',
    'discount_type': 'percent',
    'discount_value': 15,
    'start_at': FieldValue.serverTimestamp(),
    'end_at': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
    'is_active': true,
    'terms_ar': 'يسري العرض للفترة الصباحية فقط. لا يشمل المشروبات.',
    'image_url': null,
    'is_partner': true,
    'partner_tier': 'gold',
  });

  // 2. Azure Offer (Amount Discount)
  // azure_01
  await offersRef.doc('offer_azure_01').set({
    'venue_id': 'azure_01',
    'title_ar': 'خصم 20 شيكل على الغداء',
    'title_en': '20 ILS Off Lunch',
    'description_ar':
        'استمتع بوجبة الغداء مع خصم 20 شيكل عند إنفاق 100 شيكل أو أكثر.',
    'description_en':
        'Enjoy lunch with 20 ILS off when you spend 100 ILS or more.',
    'discount_type': 'amount',
    'discount_value': 20,
    'currency': 'ILS',
    'start_at': FieldValue.serverTimestamp(),
    'end_at': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    'is_active': true,
    'terms_ar': 'العرض ساري من الساعة 12 ظهراً وحتى 4 عصراً.',
    'is_partner': false,
  });

  // 3. Stones Offer (Free Item)
  // stones_01
  await offersRef.doc('offer_stones_01').set({
    'venue_id': 'stones_01',
    'title_ar': 'قهوة مجانية مع أي حلوى',
    'title_en': 'Free Coffee with Dessert',
    'description_ar':
        'احصل على كوب قهوة (أمريكانو أو إسبريسو) مجاناً عند طلب أي نوع حلوى.',
    'description_en':
        'Get a free coffee (Americano or Espresso) when ordering any dessert.',
    'discount_type': 'free_item',
    'discount_value': 0,
    'start_at': FieldValue.serverTimestamp(),
    'end_at': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    'is_active': true,
    'terms_ar': 'يسري العرض داخل المطعم فقط.',
    'is_partner': true,
  });

  debugPrint('✅ Seeded 3 offers successfully');
}
