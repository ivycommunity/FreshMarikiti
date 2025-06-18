const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    // Recipient
    recipient: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    // Notification content
    title: {
      type: String,
      required: true,
      trim: true,
    },

    message: {
      type: String,
      required: true,
      trim: true,
    },

    // Notification type
    type: {
      type: String,
      enum: [
        'order_placed',
        'order_confirmed',
        'order_cancelled',
        'order_delivered',
        'rider_assigned',
        'payment_received',
        'new_product',
        'promotion',
        'system',
        'chat_message',
        'rating_received',
        'eco_points_earned',
        'low_stock',
        'vendor_application',
        'account_verified'
      ],
      required: true,
    },

    // Category for filtering
    category: {
      type: String,
      enum: ['order', 'payment', 'system', 'marketing', 'chat', 'inventory'],
      required: true,
    },

    // Related entities
    relatedOrder: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
    },

    relatedUser: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },

    relatedProduct: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
    },

    // Notification data
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },

    // Status
    isRead: {
      type: Boolean,
      default: false,
    },

    readAt: {
      type: Date,
    },

    // Delivery status
    isPushed: {
      type: Boolean,
      default: false,
    },

    pushSentAt: {
      type: Date,
    },

    pushSuccess: {
      type: Boolean,
      default: false,
    },

    pushError: {
      type: String,
      default: '',
    },

    // Priority
    priority: {
      type: String,
      enum: ['low', 'normal', 'high', 'urgent'],
      default: 'normal',
    },

    // Scheduling
    scheduledFor: {
      type: Date,
    },

    expiresAt: {
      type: Date,
    },

    // Actions
    actionUrl: {
      type: String,
      default: '',
    },

    actionType: {
      type: String,
      enum: ['none', 'navigate', 'deeplink', 'external'],
      default: 'none',
    },

    // Metadata
    isActive: {
      type: Boolean,
      default: true,
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

// Virtual for checking if notification is expired
notificationSchema.virtual('isExpired').get(function() {
  return this.expiresAt && this.expiresAt < new Date();
});

// Instance methods
notificationSchema.methods.markAsRead = function() {
  this.isRead = true;
  this.readAt = new Date();
  return this.save();
};

notificationSchema.methods.markAsPushed = function(success = true, error = '') {
  this.isPushed = true;
  this.pushSentAt = new Date();
  this.pushSuccess = success;
  this.pushError = error;
  return this.save();
};

// Static methods
notificationSchema.statics.findUnreadByUser = function(userId) {
  return this.find({
    recipient: userId,
    isRead: false,
    isActive: true,
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } }
    ]
  }).sort({ createdAt: -1 });
};

notificationSchema.statics.findByUser = function(userId, limit = 50) {
  return this.find({
    recipient: userId,
    isActive: true,
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } }
    ]
  })
  .sort({ createdAt: -1 })
  .limit(limit);
};

notificationSchema.statics.findPending = function() {
  return this.find({
    isPushed: false,
    isActive: true,
    $or: [
      { scheduledFor: { $exists: false } },
      { scheduledFor: { $lte: new Date() } }
    ],
    $or: [
      { expiresAt: { $exists: false } },
      { expiresAt: { $gt: new Date() } }
    ]
  }).sort({ priority: -1, createdAt: 1 });
};

notificationSchema.statics.createNotification = function(data) {
  return this.create({
    recipient: data.recipient,
    title: data.title,
    message: data.message,
    type: data.type,
    category: data.category,
    relatedOrder: data.relatedOrder,
    relatedUser: data.relatedUser,
    relatedProduct: data.relatedProduct,
    data: data.data || {},
    priority: data.priority || 'normal',
    scheduledFor: data.scheduledFor,
    expiresAt: data.expiresAt,
    actionUrl: data.actionUrl || '',
    actionType: data.actionType || 'none',
  });
};

// Indexes
notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ recipient: 1, isRead: 1 });
notificationSchema.index({ type: 1, category: 1 });
notificationSchema.index({ isPushed: 1, scheduledFor: 1 });
notificationSchema.index({ expiresAt: 1 });
notificationSchema.index({ createdAt: -1 });
notificationSchema.index({ priority: -1, createdAt: 1 });

module.exports = mongoose.model('Notification', notificationSchema); 