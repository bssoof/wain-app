class VenuePlacePhoto {
  final String photoUri;
  final String googleMapsUri;
  final String authorName;
  final String authorUri;
  final String authorPhotoUri;

  const VenuePlacePhoto({
    required this.photoUri,
    required this.googleMapsUri,
    required this.authorName,
    required this.authorUri,
    required this.authorPhotoUri,
  });

  factory VenuePlacePhoto.fromJson(Map<String, dynamic> json) {
    String value(String key) => json[key]?.toString().trim() ?? '';

    return VenuePlacePhoto(
      photoUri: value('photoUri'),
      googleMapsUri: value('googleMapsUri'),
      authorName: value('authorName'),
      authorUri: value('authorUri'),
      authorPhotoUri: value('authorPhotoUri'),
    );
  }
}
