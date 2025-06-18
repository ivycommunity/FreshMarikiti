const express = require('express');
const router = express.Router();
const Rating = require('../models/Rating');
const Product = require('../models/Product');
const User = require('../models/User');
const Order = require('../models/Order');
const { auth } = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const { formatResponse, getPaginationParams, buildSortObject } = require('../utils/helpers');

// @route   POST /api/ratings
// @desc    Create a new rating
// @access  Private (Customer)
router.post('/', [auth, requireRole(['customer'])], async (req, res) => {
  try {
    const {
      ratedEntityId,
      ratedEntityType,
      orderId,
      rating,
      comment,
      tags
    } = req.body;

    // Validate required fields
    if (!ratedEntityId || !ratedEntityType || !rating) {
      return res.status(400).json(formatResponse(false, null, 'Missing required fields'));
    }

    // Validate rating value
    if (rating < 1 || rating > 5) {
      return res.status(400).json(formatResponse(false, null, 'Rating must be between 1 and 5'));
    }

    // Check if user has already rated this entity for this order
    const existingRating = await Rating.findOne({
      ratedBy: req.user.id,
      ratedEntityId,
      ratedEntityType,
      orderId: orderId || { $exists: false }
    });

    if (existingRating) {
      return res.status(400).json(formatResponse(false, null, 'You have already rated this item'));
    }

    // Verify the entity exists
    let ratedEntity;
    switch (ratedEntityType) {
      case 'product':
        ratedEntity = await Product.findById(ratedEntityId);
        break;
      case 'user':
        ratedEntity = await User.findById(ratedEntityId);
        break;
      default:
        return res.status(400).json(formatResponse(false, null, 'Invalid entity type'));
    }

    if (!ratedEntity) {
      return res.status(404).json(formatResponse(false, null, 'Entity not found'));
    }

    // If orderId is provided, verify the customer was part of that order
    if (orderId) {
      const order = await Order.findById(orderId);
      if (!order || order.customer.toString() !== req.user.id) {
        return res.status(403).json(formatResponse(false, null, 'Invalid order'));
      }
    }

    // Create rating
    const newRating = new Rating({
      ratedBy: req.user.id,
      ratedByName: req.user.name,
      ratedEntityId,
      ratedEntityType,
      orderId,
      rating,
      comment: comment || '',
      tags: tags || [],
      isVerified: orderId ? true : false // Verified if linked to an order
    });

    await newRating.save();

    // Update the entity's rating
    await updateEntityRating(ratedEntityId, ratedEntityType);

    const populatedRating = await Rating.findById(newRating._id)
      .populate('ratedBy', 'name profilePicture');

    res.status(201).json(formatResponse(true, populatedRating, 'Rating created successfully'));
  } catch (error) {
    console.error('Error creating rating:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/ratings
// @desc    Get ratings with filters
// @access  Public
router.get('/', async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);

    // Build filter
    let filter = {};
    if (req.query.ratedEntityId) filter.ratedEntityId = req.query.ratedEntityId;
    if (req.query.ratedEntityType) filter.ratedEntityType = req.query.ratedEntityType;
    if (req.query.rating) filter.rating = parseInt(req.query.rating);
    if (req.query.isVerified !== undefined) filter.isVerified = req.query.isVerified === 'true';

    // Rating range filter
    if (req.query.minRating || req.query.maxRating) {
      filter.rating = {};
      if (req.query.minRating) filter.rating.$gte = parseInt(req.query.minRating);
      if (req.query.maxRating) filter.rating.$lte = parseInt(req.query.maxRating);
    }

    const ratings = await Rating.find(filter)
      .populate('ratedBy', 'name profilePicture')
      .sort(sortObj)
      .skip(skip)
      .limit(limit);

    const totalRatings = await Rating.countDocuments(filter);

    res.json(formatResponse(true, {
      ratings,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalRatings / limit),
        totalRatings
      }
    }, 'Ratings retrieved successfully'));
  } catch (error) {
    console.error('Error fetching ratings:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/ratings/:id
// @desc    Get single rating
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const rating = await Rating.findById(req.params.id)
      .populate('ratedBy', 'name profilePicture');

    if (!rating) {
      return res.status(404).json(formatResponse(false, null, 'Rating not found'));
    }

    res.json(formatResponse(true, rating, 'Rating retrieved successfully'));
  } catch (error) {
    console.error('Error fetching rating:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/ratings/:id
// @desc    Update rating (only by creator)
// @access  Private
router.put('/:id', auth, async (req, res) => {
  try {
    const rating = await Rating.findById(req.params.id);

    if (!rating) {
      return res.status(404).json(formatResponse(false, null, 'Rating not found'));
    }

    // Only allow the creator to update
    if (rating.ratedBy.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Not authorized to update this rating'));
    }

    const { rating: newRating, comment, tags } = req.body;

    // Validate new rating if provided
    if (newRating && (newRating < 1 || newRating > 5)) {
      return res.status(400).json(formatResponse(false, null, 'Rating must be between 1 and 5'));
    }

    // Update fields
    if (newRating) rating.rating = newRating;
    if (comment !== undefined) rating.comment = comment;
    if (tags) rating.tags = tags;
    rating.isEdited = true;
    rating.editedAt = new Date();

    await rating.save();

    // Update entity rating if the rating value changed
    if (newRating) {
      await updateEntityRating(rating.ratedEntityId, rating.ratedEntityType);
    }

    const updatedRating = await Rating.findById(rating._id)
      .populate('ratedBy', 'name profilePicture');

    res.json(formatResponse(true, updatedRating, 'Rating updated successfully'));
  } catch (error) {
    console.error('Error updating rating:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   DELETE /api/ratings/:id
// @desc    Delete rating (creator or admin)
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const rating = await Rating.findById(req.params.id);

    if (!rating) {
      return res.status(404).json(formatResponse(false, null, 'Rating not found'));
    }

    // Only allow creator or admin to delete
    if (rating.ratedBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json(formatResponse(false, null, 'Not authorized to delete this rating'));
    }

    const ratedEntityId = rating.ratedEntityId;
    const ratedEntityType = rating.ratedEntityType;

    await Rating.findByIdAndDelete(req.params.id);

    // Update entity rating after deletion
    await updateEntityRating(ratedEntityId, ratedEntityType);

    res.json(formatResponse(true, null, 'Rating deleted successfully'));
  } catch (error) {
    console.error('Error deleting rating:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/ratings/entity/:entityType/:entityId/summary
// @desc    Get rating summary for an entity
// @access  Public
router.get('/entity/:entityType/:entityId/summary', async (req, res) => {
  try {
    const { entityType, entityId } = req.params;

    const summary = await Rating.aggregate([
      {
        $match: {
          ratedEntityId: entityId,
          ratedEntityType: entityType
        }
      },
      {
        $group: {
          _id: null,
          totalRatings: { $sum: 1 },
          averageRating: { $avg: '$rating' },
          ratingBreakdown: {
            $push: '$rating'
          }
        }
      },
      {
        $project: {
          totalRatings: 1,
          averageRating: { $round: ['$averageRating', 1] },
          oneStar: {
            $size: {
              $filter: {
                input: '$ratingBreakdown',
                cond: { $eq: ['$$this', 1] }
              }
            }
          },
          twoStar: {
            $size: {
              $filter: {
                input: '$ratingBreakdown',
                cond: { $eq: ['$$this', 2] }
              }
            }
          },
          threeStar: {
            $size: {
              $filter: {
                input: '$ratingBreakdown',
                cond: { $eq: ['$$this', 3] }
              }
            }
          },
          fourStar: {
            $size: {
              $filter: {
                input: '$ratingBreakdown',
                cond: { $eq: ['$$this', 4] }
              }
            }
          },
          fiveStar: {
            $size: {
              $filter: {
                input: '$ratingBreakdown',
                cond: { $eq: ['$$this', 5] }
              }
            }
          }
        }
      }
    ]);

    const ratingSummary = summary[0] || {
      totalRatings: 0,
      averageRating: 0,
      oneStar: 0,
      twoStar: 0,
      threeStar: 0,
      fourStar: 0,
      fiveStar: 0
    };

    res.json(formatResponse(true, ratingSummary, 'Rating summary retrieved successfully'));
  } catch (error) {
    console.error('Error fetching rating summary:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/ratings/:id/report
// @desc    Report inappropriate rating
// @access  Private
router.post('/:id/report', auth, async (req, res) => {
  try {
    const { reason, description } = req.body;

    const rating = await Rating.findById(req.params.id);

    if (!rating) {
      return res.status(404).json(formatResponse(false, null, 'Rating not found'));
    }

    // Add report to rating
    if (!rating.reports) rating.reports = [];
    
    rating.reports.push({
      reportedBy: req.user.id,
      reason,
      description: description || '',
      reportedAt: new Date()
    });

    // Mark as reported if multiple reports
    if (rating.reports.length >= 3) {
      rating.isReported = true;
    }

    await rating.save();

    res.json(formatResponse(true, null, 'Rating reported successfully'));
  } catch (error) {
    console.error('Error reporting rating:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/ratings/my-ratings
// @desc    Get current user's ratings
// @access  Private
router.get('/my-ratings', auth, async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);

    const ratings = await Rating.find({ ratedBy: req.user.id })
      .populate('ratedEntityId')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const totalRatings = await Rating.countDocuments({ ratedBy: req.user.id });

    res.json(formatResponse(true, {
      ratings,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalRatings / limit),
        totalRatings
      }
    }, 'Your ratings retrieved successfully'));
  } catch (error) {
    console.error('Error fetching user ratings:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// Helper function to update entity rating
async function updateEntityRating(entityId, entityType) {
  try {
    const ratings = await Rating.find({
      ratedEntityId: entityId,
      ratedEntityType: entityType
    });

    if (ratings.length === 0) {
      // No ratings, set to 0
      await updateEntity(entityId, entityType, 0, 0);
      return;
    }

    const totalRating = ratings.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / ratings.length;
    const roundedRating = Math.round(averageRating * 10) / 10; // Round to 1 decimal

    await updateEntity(entityId, entityType, roundedRating, ratings.length);
  } catch (error) {
    console.error('Error updating entity rating:', error);
  }
}

// Helper function to update entity
async function updateEntity(entityId, entityType, rating, totalRatings) {
  const updateData = { rating, totalRatings };

  switch (entityType) {
    case 'product':
      await Product.findByIdAndUpdate(entityId, updateData);
      break;
    case 'user':
      await User.findByIdAndUpdate(entityId, updateData);
      break;
  }
}

module.exports = router; 