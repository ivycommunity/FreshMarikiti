const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    phone: {
      type: String,
      required: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
      minlength: 6,
    },

    role: {
      type: String,
      required: true,
      enum: ['customer', 'vendor', 'rider', 'connector', 'admin', 'vendorAdmin'],
      default: 'customer',
    },

    // Profile information
    profilePicture: {
      type: String,
      default: '',
    },

    bio: {
      type: String,
      default: '',
    },

    // Contact information
    address: {
      type: String,
      default: '',
    },

    // Location data for delivery/vendor tracking
    coordinates: {
      latitude: { type: Number },
      longitude: { type: Number },
    },

    location: {
      type: String,
      default: '',
    },

    // Account status
    isActive: {
      type: Boolean,
      default: true,
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    // Ratings and reviews (for vendors, riders, connectors)
    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },

    totalRatings: {
      type: Number,
      default: 0,
    },

    // Eco points system
    ecoPoints: {
      type: Number,
      default: 0,
    },

    totalEcoPointsEarned: {
      type: Number,
      default: 0,
    },

    ecoPointsUsed: {
      type: Number,
      default: 0,
    },

    // Wallet and financial
    walletBalance: {
      type: Number,
      default: 0,
    },

    // Device and notification tokens
    fcmToken: {
      type: String,
      default: '',
    },

    deviceInfo: {
      platform: String,
      deviceId: String,
      appVersion: String,
    },

    // Role-specific data (flexible for different user types)
    additionalData: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    // Authentication and security
    lastLogin: {
      type: Date,
    },

    passwordResetToken: {
      type: String,
    },

    passwordResetExpires: {
      type: Date,
    },

    // Verification
    emailVerificationToken: {
      type: String,
    },

    phoneVerificationCode: {
      type: String,
    },

    phoneVerifiedAt: {
      type: Date,
    },

    emailVerifiedAt: {
      type: Date,
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

// Virtual for full name display
userSchema.virtual('displayName').get(function() {
  return this.name || 'Unknown User';
});

// Virtual for checking user roles
userSchema.virtual('isCustomer').get(function() {
  return this.role === 'customer';
});

userSchema.virtual('isVendor').get(function() {
  return this.role === 'vendor';
});

userSchema.virtual('isRider').get(function() {
  return this.role === 'rider';
});

userSchema.virtual('isConnector').get(function() {
  return this.role === 'connector';
});

userSchema.virtual('isAdmin').get(function() {
  return this.role === 'admin';
});

userSchema.virtual('isVendorAdmin').get(function() {
  return this.role === 'vendorAdmin';
});

// Virtual for available eco points
userSchema.virtual('availableEcoPoints').get(function() {
  return this.ecoPoints - this.ecoPointsUsed;
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  // Only hash password if it's been modified (or is new)
  if (!this.isModified('password')) return next();
  
  try {
    // Hash password with cost of 12
    const salt = await bcrypt.genSalt(12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to check password
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

// Instance method to update last login
userSchema.methods.updateLastLogin = function() {
  this.lastLogin = new Date();
  return this.save();
};

// Static method to find by email
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

// Static method to find active users by role
userSchema.statics.findActiveByRole = function(role) {
  return this.find({ role, isActive: true });
};

// Indexes for efficient queries
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ phone: 1 });
userSchema.index({ role: 1, isActive: 1 });
userSchema.index({ coordinates: '2dsphere' });
userSchema.index({ rating: -1, totalRatings: -1 });
userSchema.index({ ecoPoints: -1 });

module.exports = mongoose.model('User', userSchema); 