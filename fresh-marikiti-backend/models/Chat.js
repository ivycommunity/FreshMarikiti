const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  senderName: {
    type: String,
    required: true,
  },
  message: {
    type: String,
    required: true,
    trim: true,
  },
  messageType: {
    type: String,
    enum: ['text', 'image', 'location', 'system'],
    default: 'text',
  },
  attachments: [{
    type: String,
    url: String,
    filename: String,
  }],
  readBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    readAt: {
      type: Date,
      default: Date.now,
    },
  }],
  timestamp: {
    type: Date,
    default: Date.now,
  },
});

const chatSchema = new mongoose.Schema(
  {
    // Chat participants
    participants: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    }],

    // Chat type
    chatType: {
      type: String,
      enum: ['order', 'support', 'general'],
      default: 'general',
    },

    // Related order (if order chat)
    order: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order',
    },

    // Messages
    messages: [messageSchema],

    // Last message info
    lastMessage: {
      type: String,
      default: '',
    },

    lastMessageAt: {
      type: Date,
      default: Date.now,
    },

    lastMessageBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },

    // Status
    isActive: {
      type: Boolean,
      default: true,
    },

    unreadCount: {
      type: Map,
      of: Number,
      default: new Map(),
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

// Instance methods
chatSchema.methods.addMessage = function(senderId, senderName, message, messageType = 'text') {
  const newMessage = {
    sender: senderId,
    senderName,
    message,
    messageType,
    timestamp: new Date(),
  };

  this.messages.push(newMessage);
  this.lastMessage = message;
  this.lastMessageAt = new Date();
  this.lastMessageBy = senderId;

  // Update unread counts
  this.participants.forEach(participantId => {
    if (participantId.toString() !== senderId.toString()) {
      const currentCount = this.unreadCount.get(participantId.toString()) || 0;
      this.unreadCount.set(participantId.toString(), currentCount + 1);
    }
  });

  return this.save();
};

chatSchema.methods.markAsRead = function(userId) {
  this.unreadCount.set(userId.toString(), 0);
  
  // Mark messages as read
  this.messages.forEach(message => {
    const hasRead = message.readBy.some(read => read.user.toString() === userId.toString());
    if (!hasRead) {
      message.readBy.push({
        user: userId,
        readAt: new Date(),
      });
    }
  });

  return this.save();
};

// Static methods
chatSchema.statics.findByParticipants = function(participant1, participant2) {
  return this.findOne({
    participants: { $all: [participant1, participant2] },
    chatType: 'general',
  });
};

chatSchema.statics.findByUser = function(userId) {
  return this.find({
    participants: userId,
    isActive: true,
  }).sort({ lastMessageAt: -1 });
};

chatSchema.statics.findByOrder = function(orderId) {
  return this.findOne({
    order: orderId,
    chatType: 'order',
  });
};

// Indexes
chatSchema.index({ participants: 1 });
chatSchema.index({ order: 1 });
chatSchema.index({ lastMessageAt: -1 });
chatSchema.index({ chatType: 1, isActive: 1 });

module.exports = mongoose.model('Chat', chatSchema); 