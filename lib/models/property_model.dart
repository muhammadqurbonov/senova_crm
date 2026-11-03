import 'package:cloud_firestore/cloud_firestore.dart';

enum PropertyStatus { available, reserved, sold }

extension PropertyStatusX on PropertyStatus {
  String get value => name;
  static PropertyStatus fromString(String? v) =>
      PropertyStatus.values.firstWhere((e) => e.name == v, orElse: () => PropertyStatus.available);
}

class Property {
  final String id;
  final String orgId;
  final String titleTj;
  final String titleRu;
  final String descriptionTj;
  final String descriptionRu;
  final double price;
  final int? rooms;
  final double? area;
  final String district;
  final PropertyStatus status;
  final List<String> photos;
  final bool mortgageAvailable;
  final Map<String, dynamic> custom;

  Property({
    required this.id,
    required this.orgId,
    required this.titleTj,
    required this.titleRu,
    this.descriptionTj = '',
    this.descriptionRu = '',
    required this.price,
    this.rooms,
    this.area,
    this.district = '',
    this.status = PropertyStatus.available,
    this.photos = const [],
    this.mortgageAvailable = false,
    this.custom = const {},
  });

  String title(String lang) {
    if (lang == 'ru' || lang == 'en') return titleRu.isNotEmpty ? titleRu : titleTj;
    return titleTj.isNotEmpty ? titleTj : titleRu;
  }

  factory Property.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Property(
      id: doc.id,
      orgId: data['orgId'] ?? '',
      titleTj: data['title_tj'] ?? '',
      titleRu: data['title_ru'] ?? '',
      descriptionTj: data['description_tj'] ?? '',
      descriptionRu: data['description_ru'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      rooms: data['rooms'],
      area: (data['area'] as num?)?.toDouble(),
      district: data['district'] ?? '',
      status: PropertyStatusX.fromString(data['status']),
      photos: List<String>.from(data['photos'] ?? []),
      mortgageAvailable: data['mortgageAvailable'] ?? false,
      custom: Map<String, dynamic>.from(data['custom'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orgId': orgId,
      'title_tj': titleTj,
      'title_ru': titleRu,
      'description_tj': descriptionTj,
      'description_ru': descriptionRu,
      'price': price,
      'rooms': rooms,
      'area': area,
      'district': district,
      'status': status.value,
      'photos': photos,
      'mortgageAvailable': mortgageAvailable,
      'custom': custom,
    };
  }
}