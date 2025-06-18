const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      required: true,
    },

    category: {
      type: String,
      required: true,
      enum: [
        'fruits',
        'vegetables',
        'dairy',
        'meat',
        'seafood',
        'grains',
        'herbs',
        'beverages',
        'processed',
        'other'
      ],
    },

    subcategory: {
      type: String,
      default: '',
    },

    // Vendor information
    vendor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    vendorName: {
      type: String,
      required: true,
    },

    // Pricing
    price: {
      type: Number,
      required: true,
      min: 0,
    },

    originalPrice: {
      type: Number,
      default: 0,
    },

    discount: {
      type: Number,
      default: 0,
      min: 0,
      max: 100,
    },

    unit: {
      type: String,
      required: true,
      enum: ['kg', 'g', 'lbs', 'pieces', 'liters', 'ml', 'bunches', 'bags', 'boxes'],
      default: 'kg',
    },

    // Stock management
    stock: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    minStock: {
      type: Number,
      default: 5,
    },

    maxStock: {
      type: Number,
      default: 1000,
    },

    // Images
    images: [{
      type: String,
      required: true,
    }],

    primaryImage: {
      type: String,
      default: '',
    },

    // Product status
    isActive: {
      type: Boolean,
      default: true,
    },

    isAvailable: {
      type: Boolean,
      default: true,
    },

    isFeatured: {
      type: Boolean,
      default: false,
    },

    // Quality and freshness
    freshness: {
      type: String,
      enum: ['fresh', 'very-fresh', 'good', 'average'],
      default: 'fresh',
    },

    expiryDate: {
      type: Date,
    },

    harvestDate: {
      type: Date,
    },

    // Location and delivery
    origin: {
      type: String,
      default: '',
    },

    deliveryTime: {
      type: String,
      default: '30-60 minutes',
    },

    // Ratings and reviews
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

    totalReviews: {
      type: Number,
      default: 0,
    },

    // Sales data
    totalSold: {
      type: Number,
      default: 0,
    },

    totalRevenue: {
      type: Number,
      default: 0,
    },

    // SEO and search
    tags: [{
      type: String,
      lowercase: true,
    }],

    searchKeywords: [{
      type: String,
      lowercase: true,
    }],

    // Nutritional information (optional)
    nutrition: {
      calories: Number,
      protein: Number,
      carbs: Number,
      fat: Number,
      fiber: Number,
      vitamins: [String],
    },

    // Eco-friendly data
    isOrganic: {
      type: Boolean,
      default: false,
    },

    isLocallySourced: {
      type: Boolean,
      default: false,
    },

    carbonFootprint: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'medium',
    },

    ecoPointsReward: {
      type: Number,
      default: 1,
    },

    // Additional metadata
    weight: {
      type: Number,
      default: 0,
    },

    dimensions: {
      length: Number,
      width: Number,
      height: Number,
    },

    // Vendor-specific data
    vendorSku: {
      type: String,
      default: '',
    },

    barcode: {
      type: String,
      default: '',
    },

    // Timestamps
    createdAt: {
      type: Date,
      default: Date.now,
    },

    updatedAt: {
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

// Virtual fields for frontend compatibility
productSchema.virtual('imageUrls').get(function() {
  return this.images || [];
});

productSchema.virtual('stockQuantity').get(function() {
  return this.stock;
});

productSchema.virtual('stockStatus').get(function() {
  if (this.stock <= 0) return 'out_of_stock';
  if (this.stock <= this.minStock) return 'low_stock';
  return 'in_stock';
});

productSchema.virtual('discountedPrice').get(function() {
  if (this.discount > 0) {
    return this.price - (this.price * this.discount / 100);
  }
  return this.price;
});

productSchema.virtual('isOnSale').get(function() {
  return this.discount > 0;
});

productSchema.virtual('averageRating').get(function() {
  return parseFloat(this.rating.toFixed(1));
});

productSchema.virtual('isLowStock').get(function() {
  return this.stock <= this.minStock && this.stock > 0;
});

productSchema.virtual('isOutOfStock').get(function() {
  return this.stock <= 0;
});

productSchema.virtual('canOrder').get(function() {
  return this.isActive && this.isAvailable && this.stock > 0;
});

// Update timestamp before saving
productSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  
  // Set primary image if not set
  if (!this.primaryImage && this.images && this.images.length > 0) {
    this.primaryImage = this.images[0];
  }
  
  // Auto-set availability based on stock
  if (this.stock <= 0) {
    this.isAvailable = false;
  }
  
  next();
});

// Instance methods
productSchema.methods.updateStock = function(quantity, operation = 'reduce') {
  if (operation === 'reduce') {
    this.stock = Math.max(0, this.stock - quantity);
  } else if (operation === 'add') {
    this.stock = Math.min(this.maxStock, this.stock + quantity);
  }
  
  // Update availability
  this.isAvailable = this.stock > 0;
  
  return this.save();
};

productSchema.methods.addRating = function(rating, review) {
  const newTotalRatings = this.totalRatings + 1;
  const newRating = ((this.rating * this.totalRatings) + rating) / newTotalRatings;
  
  this.rating = newRating;
  this.totalRatings = newTotalRatings;
  
  if (review) {
    this.totalReviews += 1;
  }
  
  return this.save();
};

productSchema.methods.recordSale = function(quantity, salePrice) {
  this.totalSold += quantity;
  this.totalRevenue += (salePrice * quantity);
  return this.updateStock(quantity, 'reduce');
};

// Static methods
productSchema.statics.findByVendor = function(vendorId) {
  return this.find({ vendor: vendorId, isActive: true });
};

productSchema.statics.findByCategory = function(category) {
  return this.find({ category, isActive: true, isAvailable: true });
};

productSchema.statics.findFeatured = function() {
  return this.find({ isFeatured: true, isActive: true, isAvailable: true });
};

productSchema.statics.findInStock = function() {
  return this.find({ stock: { $gt: 0 }, isActive: true });
};

productSchema.statics.searchProducts = function(query) {
  return this.find({
    $and: [
      { isActive: true },
      { isAvailable: true },
      {
        $or: [
          { name: { $regex: query, $options: 'i' } },
          { description: { $regex: query, $options: 'i' } },
          { tags: { $in: [new RegExp(query, 'i')] } },
          { searchKeywords: { $in: [new RegExp(query, 'i')] } },
          { category: { $regex: query, $options: 'i' } }
        ]
      }
    ]
  });
};

// Indexes for efficient queries
productSchema.index({ vendor: 1, isActive: 1 });
productSchema.index({ category: 1, isActive: 1, isAvailable: 1 });
productSchema.index({ isFeatured: 1, isActive: 1 });
productSchema.index({ rating: -1, totalRatings: -1 });
productSchema.index({ price: 1 });
productSchema.index({ stock: 1 });
productSchema.index({ createdAt: -1 });
productSchema.index({ name: 'text', description: 'text', tags: 'text' });
productSchema.index({ totalSold: -1 });

module.exports = mongoose.model('Product', productSchema); 