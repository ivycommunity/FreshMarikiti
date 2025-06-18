const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  productName: {
    type: String,
    required: true,
  },
  productImage: {
    type: String,
    default: '',
  },
  vendor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  vendorName: {
    type: String,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  unit: {
    type: String,
    required: true,
  },
  unitPrice: {
    type: Number,
    required: true,
    min: 0,
  },
  totalPrice: {
    type: Number,
    required: true,
    min: 0,
  },
  discount: {
    type: Number,
    default: 0,
  },
  ecoPointsEarned: {
    type: Number,
    default: 0,
  },
});

const deliveryAddressSchema = new mongoose.Schema({
  street: {
    type: String,
    required: true,
  },
  city: {
    type: String,
    required: true,
  },
  state: {
    type: String,
    default: '',
  },
  zipCode: {
    type: String,
    default: '',
  },
  coordinates: {
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
  },
  landmark: {
    type: String,
    default: '',
  },
  instructions: {
    type: String,
    default: '',
  },
});

const orderSchema = new mongoose.Schema(
  {
    // Order identification
    orderId: {
      type: String,
      unique: true,
      required: true,
    },

    // Customer information
    customer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    customerName: {
      type: String,
      required: true,
    },

    customerPhone: {
      type: String,
      required: true,
    },

    // Order items
    items: [orderItemSchema],

    // Order status and tracking
    status: {
      type: String,
      enum: [
        'pending',           // Order placed, awaiting vendor confirmation
        'confirmed',         // Vendor confirmed order
        'preparing',         // Vendor preparing items
        'ready_for_pickup',  // Ready for rider pickup
        'picked_up',         // Rider picked up order
        'in_transit',        // Order being delivered
        'delivered',         // Successfully delivered
        'cancelled',         // Order cancelled
        'refunded'           // Order refunded
      ],
      default: 'pending',
    },

    // Delivery information
    deliveryAddress: deliveryAddressSchema,

    deliveryType: {
      type: String,
      enum: ['standard', 'express', 'scheduled'],
      default: 'standard',
    },

    scheduledDeliveryTime: {
      type: Date,
    },

    estimatedDeliveryTime: {
      type: Date,
    },

    actualDeliveryTime: {
      type: Date,
    },

    // Rider assignment
    rider: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },

    riderName: {
      type: String,
      default: '',
    },

    riderPhone: {
      type: String,
      default: '',
    },

    // Connector (if used)
    connector: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },

    connectorName: {
      type: String,
      default: '',
    },

    // Pricing and payments
    subtotal: {
      type: Number,
      required: true,
      min: 0,
    },

    discount: {
      type: Number,
      default: 0,
    },

    deliveryFee: {
      type: Number,
      default: 0,
    },

    serviceFee: {
      type: Number,
      default: 0,
    },

    tax: {
      type: Number,
      default: 0,
    },

    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },

    // Payment information
    paymentMethod: {
      type: String,
      enum: ['cash', 'card', 'mobile_money', 'wallet', 'eco_points'],
      required: true,
    },

    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded', 'partial'],
      default: 'pending',
    },

    transactionId: {
      type: String,
      default: '',
    },

    // Eco points
    ecoPointsUsed: {
      type: Number,
      default: 0,
    },

    ecoPointsEarned: {
      type: Number,
      default: 0,
    },

    // Commission and revenue tracking
    platformCommission: {
      type: Number,
      default: 0,
    },

    riderCommission: {
      type: Number,
      default: 0,
    },

    connectorCommission: {
      type: Number,
      default: 0,
    },

    vendorEarnings: {
      type: Number,
      default: 0,
    },

    // Time tracking
    orderPlacedAt: {
      type: Date,
      default: Date.now,
    },

    confirmedAt: {
      type: Date,
    },

    preparedAt: {
      type: Date,
    },

    pickedUpAt: {
      type: Date,
    },

    deliveredAt: {
      type: Date,
    },

    cancelledAt: {
      type: Date,
    },

    // Cancellation and refund
    cancellationReason: {
      type: String,
      default: '',
    },

    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },

    refundAmount: {
      type: Number,
      default: 0,
    },

    refundReason: {
      type: String,
      default: '',
    },

    // Rating and feedback
    customerRating: {
      type: Number,
      min: 1,
      max: 5,
    },

    customerReview: {
      type: String,
      default: '',
    },

    riderRating: {
      type: Number,
      min: 1,
      max: 5,
    },

    riderReview: {
      type: String,
      default: '',
    },

    // Special instructions and notes
    specialInstructions: {
      type: String,
      default: '',
    },

    vendorNotes: {
      type: String,
      default: '',
    },

    riderNotes: {
      type: String,
      default: '',
    },

    adminNotes: {
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
orderSchema.virtual('isCompleted').get(function() {
  return this.status === 'delivered';
});

orderSchema.virtual('isCancelled').get(function() {
  return this.status === 'cancelled';
});

orderSchema.virtual('isPending').get(function() {
  return this.status === 'pending';
});

orderSchema.virtual('isInProgress').get(function() {
  return ['confirmed', 'preparing', 'ready_for_pickup', 'picked_up', 'in_transit'].includes(this.status);
});

orderSchema.virtual('canCancel').get(function() {
  return ['pending', 'confirmed'].includes(this.status);
});

orderSchema.virtual('canRate').get(function() {
  return this.status === 'delivered' && !this.customerRating;
});

orderSchema.virtual('deliveryDuration').get(function() {
  if (this.deliveredAt && this.orderPlacedAt) {
    return Math.round((this.deliveredAt - this.orderPlacedAt) / (1000 * 60)); // in minutes
  }
  return null;
});

orderSchema.virtual('totalItems').get(function() {
  return this.items.reduce((total, item) => total + item.quantity, 0);
});

orderSchema.virtual('uniqueVendors').get(function() {
  const vendors = new Set();
  this.items.forEach(item => vendors.add(item.vendor.toString()));
  return vendors.size;
});

// Pre-save middleware to generate order ID and calculate commissions
orderSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  
  // Generate order ID if not exists
  if (!this.orderId) {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substr(2, 5);
    this.orderId = `FM${timestamp}${random}`.toUpperCase();
  }
  
  // Calculate commissions (typical percentages)
  if (this.totalAmount > 0) {
    this.platformCommission = this.totalAmount * 0.05; // 5% platform commission
    this.riderCommission = Math.max(this.deliveryFee * 0.8, 50); // 80% of delivery fee or minimum 50
    this.connectorCommission = this.connector ? this.totalAmount * 0.02 : 0; // 2% if connector involved
    this.vendorEarnings = this.subtotal - this.platformCommission - this.connectorCommission;
  }
  
  next();
});

// Instance methods
orderSchema.methods.updateStatus = function(newStatus, userId) {
  const oldStatus = this.status;
  this.status = newStatus;
  
  // Set timestamps based on status
  const now = new Date();
  switch (newStatus) {
    case 'confirmed':
      this.confirmedAt = now;
      break;
    case 'preparing':
      this.preparedAt = now;
      break;
    case 'picked_up':
      this.pickedUpAt = now;
      break;
    case 'delivered':
      this.deliveredAt = now;
      this.actualDeliveryTime = now;
      break;
    case 'cancelled':
      this.cancelledAt = now;
      this.cancelledBy = userId;
      break;
  }
  
  return this.save();
};

orderSchema.methods.assignRider = function(riderId, riderName, riderPhone) {
  this.rider = riderId;
  this.riderName = riderName;
  this.riderPhone = riderPhone;
  return this.save();
};

orderSchema.methods.addRating = function(rating, review, type = 'customer') {
  if (type === 'customer') {
    this.customerRating = rating;
    this.customerReview = review;
  } else if (type === 'rider') {
    this.riderRating = rating;
    this.riderReview = review;
  }
  return this.save();
};

orderSchema.methods.calculateEcoPoints = function() {
  let totalEcoPoints = 0;
  this.items.forEach(item => {
    totalEcoPoints += item.ecoPointsEarned || 0;
  });
  this.ecoPointsEarned = totalEcoPoints;
  return totalEcoPoints;
};

// Static methods
orderSchema.statics.findByCustomer = function(customerId) {
  return this.find({ customer: customerId }).sort({ createdAt: -1 });
};

orderSchema.statics.findByVendor = function(vendorId) {
  return this.find({ 'items.vendor': vendorId }).sort({ createdAt: -1 });
};

orderSchema.statics.findByRider = function(riderId) {
  return this.find({ rider: riderId }).sort({ createdAt: -1 });
};

orderSchema.statics.findByStatus = function(status) {
  return this.find({ status }).sort({ createdAt: -1 });
};

orderSchema.statics.findActiveOrders = function() {
  return this.find({ 
    status: { $in: ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'picked_up', 'in_transit'] }
  }).sort({ createdAt: -1 });
};

orderSchema.statics.getOrderStats = function(startDate, endDate) {
  const matchStage = {
    createdAt: {
      $gte: startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Default 30 days
      $lte: endDate || new Date()
    }
  };
  
  return this.aggregate([
    { $match: matchStage },
    {
      $group: {
        _id: null,
        totalOrders: { $sum: 1 },
        totalRevenue: { $sum: '$totalAmount' },
        averageOrderValue: { $avg: '$totalAmount' },
        completedOrders: {
          $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] }
        },
        cancelledOrders: {
          $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
        }
      }
    }
  ]);
};

// Indexes for efficient queries
orderSchema.index({ customer: 1, createdAt: -1 });
orderSchema.index({ 'items.vendor': 1, createdAt: -1 });
orderSchema.index({ rider: 1, createdAt: -1 });
orderSchema.index({ connector: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });
orderSchema.index({ orderId: 1 }, { unique: true });
orderSchema.index({ paymentStatus: 1 });
orderSchema.index({ deliveredAt: -1 });
orderSchema.index({ 'deliveryAddress.coordinates': '2dsphere' });

module.exports = mongoose.model('Order', orderSchema); 