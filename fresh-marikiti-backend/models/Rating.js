const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema(
  {
    // Rating information
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },

    review: {
      type: String,
      trim: true,
      maxlength: 500,
    },

    // Who is being rated
    ratedUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    ratedUserType: {
      type: String,
      enum: ['vendor', 'rider', 'connector'],
      required: true,
    },

    // Who gave the rating
    reviewer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    reviewerType: {
      type: String,
      enum: ['customer', 'vendor', 'rider', 'admin'],
      required: true,
    },

    // Context
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
    },

    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
    },

    // Status
    isActive: {
      type: Boolean,
      default: true,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    // Moderation
    isFlagged: {
      type: Boolean,
      default: false,
    },

    flagReason: {
      type: String,
      default: '',
    },

    moderatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
  }
);

// Indexes
ratingSchema.index({ ratedUser: 1, createdAt: -1 });
ratingSchema.index({ reviewer: 1, createdAt: -1 });
ratingSchema.index({ order: 1 });
ratingSchema.index({ product: 1 });
ratingSchema.index({ rating: -1 });
ratingSchema.index({ isActive: 1, isVerified: 1 });

module.exports = mongoose.model('Rating', ratingSchema); 