// import 'package:flutter/material.dart';
// import 'package:fresh_marikiti/core/models/rating_model.dart';
// import 'package:fresh_marikiti/core/services/rating_service.dart';
// import 'package:fresh_marikiti/core/services/logger_service.dart';

// class RatingProvider with ChangeNotifier {
//   List<Rating> _userRatings = [];
//   List<Rating> _givenRatings = [];
//   UserRatingSummary? _ratingSummary;
  
//   bool _isLoading = false;
//   bool _isSubmitting = false;
//   String? _error;

//   // Getters
//   List<Rating> get userRatings => List.unmodifiable(_userRatings);
//   List<Rating> get givenRatings => List.unmodifiable(_givenRatings);
//   UserRatingSummary? get ratingSummary => _ratingSummary;
  
//   bool get isLoading => _isLoading;
//   bool get isSubmitting => _isSubmitting;
//   String? get error => _error;

//   /// Initialize provider
//   Future<void> initialize(String userId) async {
//     await loadUserRatings(userId);
//     await loadGivenRatings(userId);
//     await loadRatingSummary(userId);
//   }

//   /// Load ratings received by user
//   Future<void> loadUserRatings(String userId, {bool refresh = false}) async {
//     if (_isLoading && !refresh) return;
    
//     _isLoading = true;
//     _error = null;
//     notifyListeners();

//     try {
//       _userRatings = await RatingService.getUserRatings(userId: userId);
//     } catch (e) {
//       LoggerService.error('Failed to load user ratings', error: e, tag: 'RatingProvider');
//       _error = 'Failed to load ratings: ${e.toString()}';
//       _userRatings = [];
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Load ratings given by user
//   Future<void> loadGivenRatings(String userId, {bool refresh = false}) async {
//     if (_isLoading && !refresh) return;
    
//     _isLoading = true;
//     notifyListeners();

//     try {
//       _givenRatings = await RatingService.getRatingsGivenByUser(userId: userId);
//     } catch (e) {
//       LoggerService.error('Failed to load given ratings', error: e, tag: 'RatingProvider');
//       _error = 'Failed to load given ratings: ${e.toString()}';
//       _givenRatings = [];
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   /// Load user rating summary
//   Future<void> loadRatingSummary(String userId) async {
//     try {
//       _ratingSummary = await RatingService.getUserRatingSummary(userId);
//       notifyListeners();
//     } catch (e) {
//       LoggerService.error('Failed to load rating summary', error: e, tag: 'RatingProvider');
//     }
//   }

//   /// Submit rating
//   Future<bool> submitRating({
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
//     _isSubmitting = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final result = await RatingService.submitRating(
//         orderId: orderId,
//         ratedUserId: ratedUserId,
//         ratingType: ratingType,
//         overallRating: overallRating,
//         criteriaRatings: criteriaRatings,
//         comment: comment,
//         tags: tags,
//         images: images,
//         isAnonymous: isAnonymous,
//       );

//       if (result['success'] == true) {
//         final newRating = result['rating'] as Rating;
//         _givenRatings.insert(0, newRating);
//         notifyListeners();
//         return true;
//       } else {
//         _error = result['message'] ?? 'Failed to submit rating';
//         notifyListeners();
//         return false;
//       }
//     } catch (e) {
//       LoggerService.error('Failed to submit rating', error: e, tag: 'RatingProvider');
//       _error = 'Failed to submit rating: ${e.toString()}';
//       notifyListeners();
//       return false;
//     } finally {
//       _isSubmitting = false;
//       notifyListeners();
//     }
//   }

//   /// Respond to rating
//   Future<bool> respondToRating({
//     required String ratingId,
//     required String response,
//   }) async {
//     _isSubmitting = true;
//     _error = null;
//     notifyListeners();

//     try {
//       final result = await RatingService.respondToRating(
//         ratingId: ratingId,
//         response: response,
//       );

//       if (result['success'] == true) {
//         final updatedRating = result['rating'] as Rating;
        
//         // Update in user ratings
//         final index = _userRatings.indexWhere((r) => r.id == ratingId);
//         if (index != -1) {
//           _userRatings[index] = updatedRating;
//           notifyListeners();
//         }
//         return true;
//       } else {
//         _error = result['message'] ?? 'Failed to submit response';
//         notifyListeners();
//         return false;
//       }
//     } catch (e) {
//       LoggerService.error('Failed to respond to rating', error: e, tag: 'RatingProvider');
//       _error = 'Failed to submit response: ${e.toString()}';
//       notifyListeners();
//       return false;
//     } finally {
//       _isSubmitting = false;
//       notifyListeners();
//     }
//   }

//   /// Get order ratings
//   Future<List<Rating>> getOrderRatings(String orderId) async {
//     try {
//       return await RatingService.getOrderRatings(orderId);
//     } catch (e) {
//       LoggerService.error('Failed to get order ratings', error: e, tag: 'RatingProvider');
//       return [];
//     }
//   }

//   /// Check if user can rate for an order
//   bool canRateForOrder(String orderId, String ratedUserId) {
//     return !_givenRatings.any(
//       (rating) => rating.orderId == orderId && rating.ratedUserId == ratedUserId
//     );
//   }

//   /// Get user's rating for a specific order and user
//   Rating? getUserRatingForOrder(String orderId, String ratedUserId) {
//     try {
//       return _givenRatings.firstWhere(
//         (rating) => rating.orderId == orderId && rating.ratedUserId == ratedUserId
//       );
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Refresh all data
//   Future<void> refresh(String userId) async {
//     await Future.wait([
//       loadUserRatings(userId, refresh: true),
//       loadGivenRatings(userId, refresh: true),
//       loadRatingSummary(userId),
//     ]);
//   }

//   /// Clear error
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// } 