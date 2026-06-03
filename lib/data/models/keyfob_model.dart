class KeyfobModel {
  final String id;
  final String macAddress;
  final String? userId;
  final String? firmwareVersion;
  final int? batteryLevel;
  final DateTime? registeredAt;
  final DateTime? lastPingAt;

  KeyfobModel({
    required this.id,
    required this.macAddress,
    this.userId,
    this.firmwareVersion,
    this.batteryLevel,
    this.registeredAt,
    this.lastPingAt,
  });

  factory KeyfobModel.fromJson(Map<String, dynamic> json) {
    return KeyfobModel(
      id: json['id'] as String,
      macAddress: json['mac_address'] as String,
      userId: json['user_id'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      batteryLevel: json['battery_level'] as int?,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'])
          : null,
      lastPingAt: json['last_ping_at'] != null
          ? DateTime.tryParse(json['last_ping_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mac_address': macAddress,
        if (userId != null) 'user_id': userId,
        if (firmwareVersion != null) 'firmware_version': firmwareVersion,
        if (batteryLevel != null) 'battery_level': batteryLevel,
      };
}

class CollectionModel {
  final String id;
  final String name;
  final String series;
  final String? imageUrl;
  final double priceCny;
  final double? salePriceCny;
  final bool isNew;
  final bool inStock;
  final String? description;

  CollectionModel({
    required this.id,
    required this.name,
    required this.series,
    this.imageUrl,
    required this.priceCny,
    this.salePriceCny,
    this.isNew = false,
    this.inStock = true,
    this.description,
  });

  bool get isOnSale => salePriceCny != null;

  double get displayPrice => salePriceCny ?? priceCny;

  int get discountPercent {
    if (!isOnSale) return 0;
    return ((1 - salePriceCny! / priceCny) * 100).round();
  }

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      series: json['series'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      priceCny: (json['price_cny'] as num).toDouble(),
      salePriceCny: (json['sale_price_cny'] as num?)?.toDouble(),
      isNew: json['is_new'] as bool? ?? false,
      inStock: json['in_stock'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }
}

class UserCollectionModel {
  final String id;
  final String userId;
  final String collectionId;
  final String? keyfobMac;
  final String serialNumber;
  final DateTime purchasedAt;
  final CollectionModel? collection;

  UserCollectionModel({
    required this.id,
    required this.userId,
    required this.collectionId,
    this.keyfobMac,
    required this.serialNumber,
    required this.purchasedAt,
    this.collection,
  });

  factory UserCollectionModel.fromJson(Map<String, dynamic> json) {
    return UserCollectionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      collectionId: json['collection_id'] as String,
      keyfobMac: json['keyfob_mac'] as String?,
      serialNumber: json['serial_number'] as String? ?? '#0000',
      purchasedAt: DateTime.parse(json['purchased_at'] as String),
      collection: json['collection'] != null
          ? CollectionModel.fromJson(json['collection'] as Map<String, dynamic>)
          : null,
    );
  }
}
