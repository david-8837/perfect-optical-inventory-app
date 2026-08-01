class FrameItem {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String priceSymbol;
  final String color;
  final String imagePath;
  final List<String> imagePaths;
  final double rating;
  final int reviewCount;
  final bool inStock;
  int stockCount;
  final String boxNumber;
  final String vendor;
  bool isPendingSync;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  FrameItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.priceSymbol = '₹',
    required this.color,
    String? imagePath,
    List<String>? imagePaths,
    this.rating = 4.8,
    this.reviewCount = 250,
    this.inStock = true,
    int? stockCount,
    this.boxNumber = 'BOX-01',
    this.vendor = 'Perfect Optical Direct',
    this.isPendingSync = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  })  : imagePaths = (imagePaths != null && imagePaths.isNotEmpty)
            ? imagePaths
            : ((imagePath != null && imagePath.isNotEmpty) ? [imagePath] : []),
        imagePath = (imagePath != null && imagePath.isNotEmpty)
            ? imagePath
            : ((imagePaths != null && imagePaths.isNotEmpty) ? imagePaths.first : ''),
        stockCount = stockCount ?? 12,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hourNum = createdAt.hour > 12
        ? createdAt.hour - 12
        : (createdAt.hour == 0 ? 12 : createdAt.hour);
    final period = createdAt.hour >= 12 ? 'PM' : 'AM';
    final minStr = createdAt.minute.toString().padLeft(2, '0');
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year} • $hourNum:$minStr $period';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'title': name,
      'brand': brand,
      'category': category,
      'price': price,
      'price_symbol': priceSymbol,
      'color': color,
      'image_path': imagePath,
      'image_paths': imagePaths.join('|||'),
      'rating': rating,
      'review_count': reviewCount,
      'reviews': reviewCount,
      'stock_count': stockCount,
      'box_number': boxNumber,
      'vendor': vendor,
      'is_pending_sync': isPendingSync,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  factory FrameItem.fromMap(Map<String, dynamic> map) {
    final parsedName = (map['name'] ?? map['title'] ?? '').toString();
    final mainImg = (map['image_path'] ?? map['imagePath'] ?? map['image'] ?? '').toString();
    List<String> parsedPaths = [];
    if (map['image_paths'] != null && map['image_paths'].toString().isNotEmpty) {
      parsedPaths = map['image_paths'].toString().split('|||').where((p) => p.isNotEmpty).toList();
    } else if (map['imagePaths'] is List) {
      parsedPaths = (map['imagePaths'] as List).map((e) => e.toString()).where((p) => p.isNotEmpty).toList();
    }
    if (parsedPaths.isEmpty && mainImg.isNotEmpty) {
      parsedPaths = [mainImg];
    }

    return FrameItem(
      id: map['id']?.toString() ?? '',
      name: parsedName.isNotEmpty ? parsedName : 'Optical Frame',
      brand: (map['brand'] ?? 'Ray-Ban').toString(),
      category: (map['category'] ?? 'Plastic Frame').toString(),
      price: (map['price'] as num?)?.toDouble() ?? 195.0,
      priceSymbol: (map['price_symbol'] ?? map['priceSymbol'] ?? '₹').toString(),
      color: (map['color'] ?? 'Black').toString(),
      imagePath: mainImg,
      imagePaths: parsedPaths,
      rating: (map['rating'] as num?)?.toDouble() ?? (double.tryParse(map['rating']?.toString() ?? '') ?? 4.8),
      reviewCount: (map['review_count'] as num?)?.toInt() ?? (map['reviews'] as num?)?.toInt() ?? (int.tryParse(map['reviews']?.toString() ?? '') ?? 250),
      inStock: map['in_stock'] ?? map['inStock'] ?? true,
      stockCount: (map['stock_count'] as num?)?.toInt() ?? (map['stockCount'] as num?)?.toInt() ?? 12,
      boxNumber: (map['box_number'] ?? map['boxNumber'] ?? 'BOX-01').toString(),
      vendor: (map['vendor'] ?? 'Perfect Optical Direct').toString(),
      isPendingSync: map['is_pending_sync'] ?? map['isPendingSync'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : (map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : (map['updatedAt'] != null
              ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      isDeleted: map['is_deleted'] ?? map['isDeleted'] ?? false,
    );
  }

  FrameItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    double? price,
    String? priceSymbol,
    String? color,
    String? imagePath,
    List<String>? imagePaths,
    double? rating,
    int? reviewCount,
    bool? inStock,
    int? stockCount,
    String? boxNumber,
    String? vendor,
    bool? isPendingSync,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return FrameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      priceSymbol: priceSymbol ?? this.priceSymbol,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? (stockCount != null ? stockCount > 0 : this.inStock),
      stockCount: stockCount ?? this.stockCount,
      boxNumber: boxNumber ?? this.boxNumber,
      vendor: vendor ?? this.vendor,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

