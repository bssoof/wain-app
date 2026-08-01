import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/features/venue/domain/entities/venue_place_photo.dart';
import 'package:wain_app/features/venue/presentation/widgets/google_place_photo_image.dart';

void main() {
  testWidgets('shows Google Maps and the photo author attribution', (
    tester,
  ) async {
    const photo = VenuePlacePhoto(
      photoUri: 'https://example.test/photo.jpg',
      googleMapsUri: 'https://maps.google.com/photo',
      authorName: 'Photo Owner',
      authorUri: 'https://maps.google.com/author',
      authorPhotoUri: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 240,
          child: GooglePlacePhotoImage(
            photo: photo,
            fallback: ColoredBox(color: Colors.grey),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Google Maps'), findsOneWidget);
    expect(find.text('Photo Owner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
