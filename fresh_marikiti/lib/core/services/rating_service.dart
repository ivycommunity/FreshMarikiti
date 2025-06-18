// import 'dart:convert';
// import 'package:fresh_marikiti/core/services/api_service.dart';
// import 'package:fresh_marikiti/core/services/logger_service.dart';
// import 'package:fresh_marikiti/core/models/rating_model.dart';

// class RatingService {
//   static const String _baseUrl = '/ratings';

//   // =================== SUBMIT RATINGS ===================

//   /// Submit a rating for an order participant
//   static Future<Map<String, dynamic>> submitRating({
//     required String orderId,
//     required String ratedUserId,
//     required RatingType ratingType,
//     required int overallRating,
//     Map<RatingCriteria, int>? criteriaRatings,
//     String? comment,
//     List<String>? tags,
//     List<String>? images,
//     bool isAnonymous = false,
//   }) async {
//     try {
//       LoggerService.info('Submitting rating for order: $orderId, user: $ratedUserId', tag: 'RatingService');

//       final requestData = {
//         'orderId': orderId,
//         'ratedUserId': ratedUserId,
//         'ratingType': ratingType.toString().split('.').last,
//         'overallRating': overallRating,
//         'criteriaRatings': criteriaRatings?.map((k, v) => MapEntry(k.toString().split('.').last, v)) ?? {},
//         'comment': comment,
//         'tags': tags ?? [],
//         'images': images ?? [],
//         'isAnonymous': isAnonymous,
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       final response = await ApiService.post('$_baseUrl/submit', requestData);
      
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return {
//           'success': true,
//           'rating': Rating.fromJson(data['rating']),
//           'message': 'Rating submitted successfully',
//         };
//       } else {
//         final error = json.decode(response.body);
//         return {
//           'success': false,
//           'message': error['message'] ?? 'Failed to submit rating',
//         };
//       }
//     } catch (e) {
//       LoggerService.error('Error submitting rating', error: e, tag: 'RatingService');
//       return {
//         'success': false,
//         'message': 'Network error: Failed to submit rating',
//       };
//     }
//   }

//   /// Respond to a rating
//   static Future<Map<String, dynamic>> respondToRating({
//     required String ratingId,
//     required String response,
//   }) async {
//     try {
//       final requestData = {
//         'response': response,
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       final responseResult = await ApiService.post('$_baseUrl/$ratingId/respond', requestData);
      
//       if (responseResult.statusCode == 200) {
//         final data = json.decode(responseResult.body);
//         return {
//           'success': true,
//           'rating': Rating.fromJson(data['rating']),
//           'message': 'Response submitted successfully',
//         };
//       } else {
//         final error = json.decode(responseResult.body);
//         return {
//           'success': false,
//           'message': error['message'] ?? 'Failed to submit response',
//         };
//       }
//     } catch (e) {
//       LoggerService.error('Error responding to rating', error: e, tag: 'RatingService');
//       return {
//         'success': false,
//         'message': 'Network error: Failed to submit response',
//       };
//     }
//   }

//   // =================== GET RATINGS ===================

//   /// Get ratings for a specific user
//   static Future<List<Rating>> getUserRatings({
//     required String userId,
//     RatingType? ratingType,
//     int page = 1,
//     int limit = 20,
//     RatingFilter? filter,
//   }) async {
//     try {
//       final queryParams = <String>[];
//       queryParams.add('page=$page');
//       queryParams.add('limit=$limit');
      
//       if (ratingType != null) {
//         queryParams.add('ratingType=${ratingType.toString().split('.').last}');
//       }

//       // Add filter parameters
//       if (filter != null) {
//         final filterParams = filter.toQueryParams();
//         filterParams.forEach((key, value) {
//           queryParams.add('$key=$value');
//         });
//       }

//       final url = '$_baseUrl/user/$userId?${queryParams.join('&')}';
//       final response = await ApiService.get(url);
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final ratings = data['ratings'] ?? data['data'] ?? [];
//         return ratings.map<Rating>((json) => Rating.fromJson(json)).toList();
//       }
//       return [];
//     } catch (e) {
//       LoggerService.error('Error fetching user ratings', error: e, tag: 'RatingService');
//       return [];
//     }
//   }

//   /// Get ratings for a specific order
//   static Future<List<Rating>> getOrderRatings(String orderId) async {
//     try {
//       final response = await ApiService.get('$_baseUrl/order/$orderId');
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final ratings = data['ratings'] ?? [];
//         return ratings.map<Rating>((json) => Rating.fromJson(json)).toList();
//       }
//       return [];
//     } catch (e) {
//       LoggerService.error('Error fetching order ratings', error: e, tag: 'RatingService');
//       return [];
//     }
//   }

//   /// Get ratings given by a user
//   static Future<List<Rating>> getRatingsGivenByUser({
//     required String userId,
//     int page = 1,
//     int limit = 20,
//   }) async {
//     try {
//       final url = '$_baseUrl/given-by/$userId?page=$page&limit=$limit';
//       final response = await ApiService.get(url);
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final ratings = data['ratings'] ?? [];
//         return ratings.map<Rating>((json) => Rating.fromJson(json)).toList();
//       }
//       return [];
//     } catch (e) {
//       LoggerService.error('Error fetching ratings given by user', error: e, tag: 'RatingService');
//       return [];
//     }
//   }

//   // =================== RATING SUMMARIES ===================

//   /// Get user rating summary
//   static Future<UserRatingSummary?> getUserRatingSummary(String userId) async {
//     try {
//       final response = await ApiService.get('$_baseUrl/summary/$userId');
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return UserRatingSummary.fromJson(data['summary']);
//       }
//       return null;
//     } catch (e) {
//       LoggerService.error('Error fetching user rating summary', error: e, tag: 'RatingService');
//       return null;
//     }
//   }

//   /// Get ratings overview for dashboard
//   static Future<Map<String, dynamic>> getRatingsOverview() async {
//     try {
//       final response = await ApiService.get('$_baseUrl/overview');
      
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//       return {};
//     } catch (e) {
//       LoggerService.error('Error fetching ratings overview', error: e, tag: 'RatingService');
//       return {};
//     }
//   }

//   // =================== RATING ANALYTICS ===================

//   /// Get rating analytics for a user
//   static Future<Map<String, dynamic>> getUserRatingAnalytics({
//     required String userId,
//     DateTime? startDate,
//     DateTime? endDate,
//   }) async {
//     try {
//       final queryParams = <String>[];
//       if (startDate != null) {
//         queryParams.add('startDate=${startDate.toIso8601String()}');
//       }
//       if (endDate != null) {
//         queryParams.add('endDate=${endDate.toIso8601String()}');
//       }

//       final url = '$_baseUrl/analytics/$userId?${queryParams.join('&')}';
//       final response = await ApiService.get(url);
      
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//       return {};
//     } catch (e) {
//       LoggerService.error('Error fetching user rating analytics', error: e, tag: 'RatingService');
//       return {};
//     }
//   }

//   /// Get platform-wide rating analytics
//   static Future<Map<String, dynamic>> getPlatformRatingAnalytics({
//     DateTime? startDate,
//     DateTime? endDate,
//     String? groupBy = 'day',
//   }) async {
//     try {
//       final queryParams = <String>[];
//       if (startDate != null) {
//         queryParams.add('startDate=${startDate.toIso8601String()}');
//       }
//       if (endDate != null) {
//         queryParams.add('endDate=${endDate.toIso8601String()}');
//       }
//       if (groupBy != null) {
//         queryParams.add('groupBy=$groupBy');
//       }

//       final url = '$_baseUrl/analytics/platform?${queryParams.join('&')}';
//       final response = await ApiService.get(url);
      
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//       return {};
//     } catch (e) {
//       LoggerService.error('Error fetching platform rating analytics', error: e, tag: 'RatingService');
//       return {};
//     }
//   }

//   // =================== RATING VALIDATION ===================

//   /// Check if user can rate another user for a specific order
//   static Future<Map<String, dynamic>> canUserRate({
//     required String orderId,
//     required String ratedUserId,
//     required RatingType ratingType,
//   }) async {
//     try {
//       final queryParams = [
//         'orderId=$orderId',
//         'ratedUserId=$ratedUserId',
//         'ratingType=${ratingType.toString().split('.').last}',
//       ];

//       final url = '$_baseUrl/can-rate?${queryParams.join('&')}';
//       final response = await ApiService.get(url);
      
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//       return {'canRate': false, 'reason': 'Unknown error'};
//     } catch (e) {
//       LoggerService.error('Error checking rating eligibility', error: e, tag: 'RatingService');
//       return {'canRate': false, 'reason': 'Network error'};
//     }
//   }

//   /// Get pending ratings for a user
//   static Future<List<Map<String, dynamic>>> getPendingRatings() async {
//     try {
//       final response = await ApiService.get('$_baseUrl/pending');
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return List<Map<String, dynamic>>.from(data['pendingRatings'] ?? []);
//       }
//       return [];
//     } catch (e) {
//       LoggerService.error('Error fetching pending ratings', error: e, tag: 'RatingService');
//       return [];
//     }
//   }

//   // =================== BULK OPERATIONS ===================

//   /// Submit multiple ratings for an order
//   static Future<Map<String, dynamic>> submitOrderRatings({
//     required String orderId,
//     required List<Map<String, dynamic>> ratings,
//   }) async {
//     try {
//       final requestData = {
//         'orderId': orderId,
//         'ratings': ratings,
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       final response = await ApiService.post('$_baseUrl/bulk-submit', requestData);
      
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body);
//         return {
//           'success': true,
//           'ratings': (data['ratings'] as List).map((json) => Rating.fromJson(json)).toList(),
//           'message': 'All ratings submitted successfully',
//         };
//       } else {
//         final error = json.decode(response.body);
//         return {
//           'success': false,
//           'message': error['message'] ?? 'Failed to submit ratings',
//         };
//       }
//     } catch (e) {
//       LoggerService.error('Error submitting bulk ratings', error: e, tag: 'RatingService');
//       return {
//         'success': false,
//         'message': 'Network error: Failed to submit ratings',
//       };
//     }
//   }

//   // =================== REPORTING & MODERATION ===================

//   /// Report inappropriate rating
//   static Future<Map<String, dynamic>> reportRating({
//     required String ratingId,
//     required String reason,
//     String? details,
//   }) async {
//     try {
//       final requestData = {
//         'reason': reason,
//         'details': details,
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       final response = await ApiService.post('$_baseUrl/$ratingId/report', requestData);
      
//       if (response.statusCode == 200) {
//         return {
//           'success': true,
//           'message': 'Rating reported successfully',
//         };
//       } else {
//         final error = json.decode(response.body);
//         return {
//           'success': false,
//           'message': error['message'] ?? 'Failed to report rating',
//         };
//       }
//     } catch (e) {
//       LoggerService.error('Error reporting rating', error: e, tag: 'RatingService');
//       return {
//         'success': false,
//         'message': 'Network error: Failed to report rating',
//       };
//     }
//   }

//   /// Get reported ratings (admin only)
//   static Future<List<Map<String, dynamic>>> getReportedRatings({
//     int page = 1,
//     int limit = 20,
//     String? status,
//   }) async {
//     try {
//       final queryParams = ['page=$page', 'limit=$limit'];
//       if (status != null) {
//         queryParams.add('status=$status');
//       }

//       final url = '$_baseUrl/reported?${queryParams.join('&')}';
//       final response = await ApiService.get(url);
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return List<Map<String, dynamic>>.from(data['reportedRatings'] ?? []);
//       }
//       return [];
//     } catch (e) {
//       LoggerService.error('Error fetching reported ratings', error: e, tag: 'RatingService');
//       return [];
//     }
//   }

//   // =================== UTILITY METHODS ===================

//   /// Get rating criteria for a rating type
//   static List<RatingCriteria> getCriteriaForType(RatingType ratingType) {
//     switch (ratingType) {
//       case RatingType.vendor:
//         return [
//           RatingCriteria.overall,
//           RatingCriteria.quality,
//           RatingCriteria.communication,
//           RatingCriteria.professionalism,
//           RatingCriteria.product_freshness,
//           RatingCriteria.packaging,
//         ];
      
//       case RatingType.rider:
//         return [
//           RatingCriteria.overall,
//           RatingCriteria.punctuality,
//           RatingCriteria.communication,
//           RatingCriteria.professionalism,
//           RatingCriteria.delivery_speed,
//           RatingCriteria.cleanliness,
//         ];
      
//       case RatingType.connector:
//         return [
//           RatingCriteria.overall,
//           RatingCriteria.communication,
//           RatingCriteria.quality,
//           RatingCriteria.professionalism,
//           RatingCriteria.accuracy,
//         ];
      
//       case RatingType.customer:
//         return [
//           RatingCriteria.overall,
//           RatingCriteria.communication,
//           RatingCriteria.professionalism,
//         ];
      
//       case RatingType.order:
//         return [
//           RatingCriteria.overall,
//         ];
//     }
//   }

//   /// Validate rating data
//   static Map<String, String> validateRatingData({
//     required int overallRating,
//     Map<RatingCriteria, int>? criteriaRatings,
//     String? comment,
//     List<String>? tags,
//   }) {
//     final errors = <String, String>{};

//     // Validate overall rating
//     if (overallRating < 1 || overallRating > 5) {
//       errors['overallRating'] = 'Rating must be between 1 and 5 stars';
//     }

//     // Validate criteria ratings
//     if (criteriaRatings != null) {
//       for (final entry in criteriaRatings.entries) {
//         if (entry.value < 1 || entry.value > 5) {
//           errors['criteriaRatings'] = 'All criteria ratings must be between 1 and 5 stars';
//           break;
//         }
//       }
//     }

//     // Validate comment length
//     if (comment != null && comment.length > 1000) {
//       errors['comment'] = 'Comment must be less than 1000 characters';
//     }

//     // Validate tags
//     if (tags != null && tags.length > 10) {
//       errors['tags'] = 'Maximum 10 tags allowed';
//     }

//     return errors;
//   }

//   /// Get rating color based on score
//   static String getRatingColor(int rating) {
//     switch (rating) {
//       case 5:
//         return '#4CAF50'; // Green
//       case 4:
//         return '#8BC34A'; // Light Green
//       case 3:
//         return '#FF9800'; // Orange
//       case 2:
//         return '#FF5722'; // Deep Orange
//       case 1:
//         return '#F44336'; // Red
//       default:
//         return '#9E9E9E'; // Grey
//     }
//   }

//   /// Get rating emoji
//   static String getRatingEmoji(int rating) {
//     switch (rating) {
//       case 5:
//         return '😍';
//       case 4:
//         return '😊';
//       case 3:
//         return '😐';
//       case 2:
//         return '😞';
//       case 1:
//         return '😠';
//       default:
//         return '❓';
//     }
//   }

//   /// Format rating display
//   static String formatRating(double rating) {
//     return rating.toStringAsFixed(1);
//   }

//   /// Generate star display
//   static String generateStarDisplay(double rating) {
//     final fullStars = rating.floor();
//     final hasHalfStar = (rating - fullStars) >= 0.5;
    
//     String stars = '★' * fullStars;
//     if (hasHalfStar) stars += '½';
//     stars += '☆' * (5 - fullStars - (hasHalfStar ? 1 : 0));
    
//     return stars;
//   }

//   /// Get appropriate tags for rating type and score
//   static List<String> getSuggestedTags(RatingType ratingType, int rating) {
//     if (rating >= 4) {
//       return RatingTags.getPositiveTags(ratingType);
//     } else {
//       return RatingTags.getNegativeTags(ratingType);
//     }
//   }

//   /// Calculate rating distribution
//   static Map<int, double> calculateRatingDistribution(List<Rating> ratings) {
//     if (ratings.isEmpty) return {};

//     final distribution = <int, int>{};
//     for (int i = 1; i <= 5; i++) {
//       distribution[i] = 0;
//     }

//     for (final rating in ratings) {
//       distribution[rating.overallRating] = (distribution[rating.overallRating] ?? 0) + 1;
//     }

//     final total = ratings.length;
//     return distribution.map((key, value) => MapEntry(key, (value / total) * 100));
//   }
// } 