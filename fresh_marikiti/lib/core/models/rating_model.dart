enum RatingType {
  customer,
  vendor,
  rider,
  connector,
  order,
}

enum RatingCriteria {
  overall,
  communication,
  punctuality,
  quality,
  professionalism,
  cleanliness,
  accuracy,
  packaging,
  delivery_speed,
  product_freshness,
}

class Rating {
  final String id;
  final String orderId;
  final String raterId; // Person giving the rating
  final String ratedUserId; // Person being rated
  final RatingType ratingType;
  final int overallRating; // 1-5 stars
  final Map<RatingCriteria, int> criteriaRatings; // Detailed ratings
  final String? comment;
  final List<String>? tags; // Quick feedback tags
  final List<String>? images; // Photo evidence if needed
  final bool isAnonymous;
  final String? response; // Response from rated user
  final DateTime createdAt;
  final DateTime? respondedAt;

  Rating({
    required this.id,
    required this.orderId,
    required this.raterId,
    required this.ratedUserId,
    required this.ratingType,
    required this.overallRating,
    required this.criteriaRatings,
    this.comment,
    this.tags,
    this.images,
    this.isAnonymous = false,
    this.response,
    required this.createdAt,
    this.respondedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    Map<RatingCriteria, int> parseCriteriaRatings(Map<String, dynamic>? criteriaData) {
      if (criteriaData == null) return {};
      
      final Map<RatingCriteria, int> result = {};
      criteriaData.forEach((key, value) {
        final criteria = RatingCriteria.values.firstWhere(
          (e) => e.toString().split('.').last == key,
          orElse: () => RatingCriteria.overall,
        );
        result[criteria] = (value as num?)?.toInt() ?? 0;
      });
      return result;
    }

    return Rating(
      id: json['_id'] ?? json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      raterId: json['raterId'] ?? '',
      ratedUserId: json['ratedUserId'] ?? '',
      ratingType: RatingType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['ratingType'] ?? 'customer'),
        orElse: () => RatingType.customer,
      ),
      overallRating: json['overallRating'] ?? 0,
      criteriaRatings: parseCriteriaRatings(json['criteriaRatings']),
      comment: json['comment'],
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      response: json['response'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      respondedAt: DateTime.tryParse(json['respondedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> criteriaToJson() {
      final Map<String, dynamic> result = {};
      criteriaRatings.forEach((criteria, rating) {
        result[criteria.toString().split('.').last] = rating;
      });
      return result;
    }

    return {
      'id': id,
      'orderId': orderId,
      'raterId': raterId,
      'ratedUserId': ratedUserId,
      'ratingType': ratingType.toString().split('.').last,
      'overallRating': overallRating,
      'criteriaRatings': criteriaToJson(),
      'comment': comment,
      'tags': tags,
      'images': images,
      'isAnonymous': isAnonymous,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  Rating copyWith({
    String? id,
    String? orderId,
    String? raterId,
    String? ratedUserId,
    RatingType? ratingType,
    int? overallRating,
    Map<RatingCriteria, int>? criteriaRatings,
    String? comment,
    List<String>? tags,
    List<String>? images,
    bool? isAnonymous,
    String? response,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return Rating(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      raterId: raterId ?? this.raterId,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      ratingType: ratingType ?? this.ratingType,
      overallRating: overallRating ?? this.overallRating,
      criteriaRatings: criteriaRatings ?? this.criteriaRatings,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      images: images ?? this.images,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  // Helper methods
  bool get hasComment => comment != null && comment!.trim().isNotEmpty;
  bool get hasResponse => response != null && response!.trim().isNotEmpty;
  bool get hasImages => images != null && images!.isNotEmpty;
  bool get hasTags => tags != null && tags!.isNotEmpty;

  double get averageCriteriaRating {
    if (criteriaRatings.isEmpty) return 0.0;
    final sum = criteriaRatings.values.fold(0, (sum, rating) => sum + rating);
    return sum / criteriaRatings.length;
  }

  String get ratingText {
    switch (overallRating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      case 1:
        return 'Very Poor';
      default:
        return 'No Rating';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class UserRatingSummary {
  final String userId;
  final RatingType userType;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution; // star count -> number of ratings
  final Map<RatingCriteria, double> criteriaAverages;
  final List<String> topPositiveTags;
  final List<String> topNegativeTags;
  final int responseRate; // Percentage of responses to ratings
  final DateTime lastRatedAt;

  UserRatingSummary({
    required this.userId,
    required this.userType,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.criteriaAverages,
    required this.topPositiveTags,
    required this.topNegativeTags,
    required this.responseRate,
    required this.lastRatedAt,
  });

  factory UserRatingSummary.fromJson(Map<String, dynamic> json) {
    Map<int, int> parseDistribution(Map<String, dynamic>? distData) {
      if (distData == null) return {};
      final Map<int, int> result = {};
      distData.forEach((key, value) {
        final starCount = int.tryParse(key) ?? 0;
        result[starCount] = (value as num?)?.toInt() ?? 0;
      });
      return result;
    }

    Map<RatingCriteria, double> parseCriteriaAverages(Map<String, dynamic>? criteriaData) {
      if (criteriaData == null) return {};
      
      final Map<RatingCriteria, double> result = {};
      criteriaData.forEach((key, value) {
        final criteria = RatingCriteria.values.firstWhere(
          (e) => e.toString().split('.').last == key,
          orElse: () => RatingCriteria.overall,
        );
        result[criteria] = (value as num?)?.toDouble() ?? 0.0;
      });
      return result;
    }

    return UserRatingSummary(
      userId: json['userId'] ?? '',
      userType: RatingType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['userType'] ?? 'customer'),
        orElse: () => RatingType.customer,
      ),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] ?? 0,
      ratingDistribution: parseDistribution(json['ratingDistribution']),
      criteriaAverages: parseCriteriaAverages(json['criteriaAverages']),
      topPositiveTags: List<String>.from(json['topPositiveTags'] ?? []),
      topNegativeTags: List<String>.from(json['topNegativeTags'] ?? []),
      responseRate: json['responseRate'] ?? 0,
      lastRatedAt: DateTime.tryParse(json['lastRatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> distributionToJson() {
      final Map<String, dynamic> result = {};
      ratingDistribution.forEach((stars, count) {
        result[stars.toString()] = count;
      });
      return result;
    }

    Map<String, dynamic> criteriaToJson() {
      final Map<String, dynamic> result = {};
      criteriaAverages.forEach((criteria, average) {
        result[criteria.toString().split('.').last] = average;
      });
      return result;
    }

    return {
      'userId': userId,
      'userType': userType.toString().split('.').last,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': distributionToJson(),
      'criteriaAverages': criteriaToJson(),
      'topPositiveTags': topPositiveTags,
      'topNegativeTags': topNegativeTags,
      'responseRate': responseRate,
      'lastRatedAt': lastRatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get ratingLevel {
    if (averageRating >= 4.5) return 'Excellent';
    if (averageRating >= 4.0) return 'Very Good';
    if (averageRating >= 3.5) return 'Good';
    if (averageRating >= 3.0) return 'Average';
    if (averageRating >= 2.0) return 'Below Average';
    return 'Poor';
  }

  int get fiveStarCount => ratingDistribution[5] ?? 0;
  int get fourStarCount => ratingDistribution[4] ?? 0;
  int get threeStarCount => ratingDistribution[3] ?? 0;
  int get twoStarCount => ratingDistribution[2] ?? 0;
  int get oneStarCount => ratingDistribution[1] ?? 0;

  double get fiveStarPercentage => totalRatings > 0 ? (fiveStarCount / totalRatings) * 100 : 0;
  double get fourStarPercentage => totalRatings > 0 ? (fourStarCount / totalRatings) * 100 : 0;
  double get threeStarPercentage => totalRatings > 0 ? (threeStarCount / totalRatings) * 100 : 0;
  double get twoStarPercentage => totalRatings > 0 ? (twoStarCount / totalRatings) * 100 : 0;
  double get oneStarPercentage => totalRatings > 0 ? (oneStarCount / totalRatings) * 100 : 0;

  bool get hasRatings => totalRatings > 0;
  bool get isHighlyRated => averageRating >= 4.0 && totalRatings >= 10;
}

class RatingFilter {
  final int? minRating;
  final int? maxRating;
  final RatingType? ratingType;
  final List<String>? tags;
  final bool? hasComment;
  final bool? hasResponse;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchQuery;

  RatingFilter({
    this.minRating,
    this.maxRating,
    this.ratingType,
    this.tags,
    this.hasComment,
    this.hasResponse,
    this.startDate,
    this.endDate,
    this.searchQuery,
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    
    if (minRating != null) params['minRating'] = minRating;
    if (maxRating != null) params['maxRating'] = maxRating;
    if (ratingType != null) params['ratingType'] = ratingType.toString().split('.').last;
    if (tags != null && tags!.isNotEmpty) params['tags'] = tags!.join(',');
    if (hasComment != null) params['hasComment'] = hasComment;
    if (hasResponse != null) params['hasResponse'] = hasResponse;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      params['search'] = searchQuery!.trim();
    }
    
    return params;
  }
}

// Pre-defined rating tags for quick feedback
class RatingTags {
  static const Map<RatingType, Map<String, List<String>>> tags = {
    RatingType.vendor: {
      'positive': [
        'Fresh products',
        'Good quality',
        'Fair prices',
        'Quick response',
        'Professional',
        'Accurate description',
        'Well packaged',
        'Variety available',
      ],
      'negative': [
        'Poor quality',
        'Expired products',
        'Overpriced',
        'Slow response',
        'Rude behavior',
        'Misleading description',
        'Poor packaging',
        'Limited stock',
      ],
    },
    RatingType.rider: {
      'positive': [
        'On time',
        'Careful handling',
        'Polite',
        'Found location easily',
        'Good communication',
        'Professional appearance',
        'Safe delivery',
        'Quick delivery',
      ],
      'negative': [
        'Late delivery',
        'Damaged items',
        'Rude behavior',
        'Hard to find',
        'Poor communication',
        'Unprofessional',
        'Unsafe handling',
        'Very slow',
      ],
    },
    RatingType.connector: {
      'positive': [
        'Good shopping',
        'Found alternatives',
        'Excellent communication',
        'Quick shopping',
        'Good quality selection',
        'Followed instructions',
        'Honest pricing',
        'Helpful suggestions',
      ],
      'negative': [
        'Poor shopping',
        'Ignored preferences',
        'Poor communication',
        'Very slow',
        'Bad quality selection',
        'Ignored instructions',
        'Overcharged',
        'Unhelpful',
      ],
    },
    RatingType.customer: {
      'positive': [
        'Clear instructions',
        'Polite',
        'Responsive',
        'Understanding',
        'Flexible',
        'Good communication',
        'Appreciative',
        'Reasonable requests',
      ],
      'negative': [
        'Unclear instructions',
        'Rude behavior',
        'Unresponsive',
        'Demanding',
        'Inflexible',
        'Poor communication',
        'Unappreciative',
        'Unreasonable requests',
      ],
    },
  };

  static List<String> getPositiveTags(RatingType type) {
    return tags[type]?['positive'] ?? [];
  }

  static List<String> getNegativeTags(RatingType type) {
    return tags[type]?['negative'] ?? [];
  }

  static List<String> getAllTags(RatingType type) {
    return [...getPositiveTags(type), ...getNegativeTags(type)];
  }
} 