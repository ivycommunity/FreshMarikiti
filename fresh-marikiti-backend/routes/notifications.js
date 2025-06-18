const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const { formatResponse, getPaginationParams, buildSortObject } = require('../utils/helpers');

// @route   GET /api/notifications
// @desc    Get user's notifications
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);

    // Build filter
    let filter = { recipient: req.user.id };
    
    // Status filter
    if (req.query.isRead !== undefined) {
      filter.isRead = req.query.isRead === 'true';
    }

    // Type filter
    if (req.query.type) {
      filter.type = req.query.type;
    }

    // Priority filter
    if (req.query.priority) {
      filter.priority = req.query.priority;
    }

    const notifications = await Notification.find(filter)
      .populate('sender', 'name profilePicture role')
      .sort(sortObj)
      .skip(skip)
      .limit(limit);

    const totalNotifications = await Notification.countDocuments(filter);

    res.json(formatResponse(true, {
      notifications,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalNotifications / limit),
        totalNotifications
      }
    }, 'Notifications retrieved successfully'));
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/notifications/unread-count
// @desc    Get unread notifications count
// @access  Private
router.get('/unread-count', auth, async (req, res) => {
  try {
    const unreadCount = await Notification.countDocuments({
      recipient: req.user.id,
      isRead: false
    });

    res.json(formatResponse(true, { unreadCount }, 'Unread count retrieved successfully'));
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/notifications
// @desc    Create new notification (Admin/System)
// @access  Private (Admin)
router.post('/', [auth, requireRole(['admin'])], async (req, res) => {
  try {
    const {
      recipient,
      title,
      message,
      type,
      priority,
      data,
      scheduledFor
    } = req.body;

    // Validate required fields
    if (!recipient || !title || !message) {
      return res.status(400).json(formatResponse(false, null, 'Missing required fields'));
    }

    // Verify recipient exists
    const recipientUser = await User.findById(recipient);
    if (!recipientUser) {
      return res.status(404).json(formatResponse(false, null, 'Recipient not found'));
    }

    const notification = new Notification({
      recipient,
      sender: req.user.id,
      title,
      message,
      type: type || 'general',
      priority: priority || 'medium',
      data: data || {},
      scheduledFor: scheduledFor ? new Date(scheduledFor) : new Date()
    });

    await notification.save();

    const populatedNotification = await Notification.findById(notification._id)
      .populate('sender', 'name profilePicture role')
      .populate('recipient', 'name email fcmToken');

    // TODO: Send push notification if user has FCM token
    // if (populatedNotification.recipient.fcmToken) {
    //   await sendPushNotification(populatedNotification);
    // }

    res.status(201).json(formatResponse(true, populatedNotification, 'Notification created successfully'));
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/notifications/broadcast
// @desc    Broadcast notification to multiple users
// @access  Private (Admin)
router.post('/broadcast', [auth, requireRole(['admin'])], async (req, res) => {
  try {
    const {
      recipients,
      roles,
      title,
      message,
      type,
      priority,
      data
    } = req.body;

    if (!title || !message) {
      return res.status(400).json(formatResponse(false, null, 'Missing required fields'));
    }

    let targetUsers = [];

    // Get users by specific IDs
    if (recipients && recipients.length > 0) {
      const users = await User.find({ _id: { $in: recipients } });
      targetUsers = targetUsers.concat(users);
    }

    // Get users by roles
    if (roles && roles.length > 0) {
      const users = await User.find({ role: { $in: roles }, isActive: true });
      targetUsers = targetUsers.concat(users);
    }

    // Remove duplicates
    const uniqueUsers = targetUsers.filter((user, index, self) => 
      index === self.findIndex(u => u._id.toString() === user._id.toString())
    );

    if (uniqueUsers.length === 0) {
      return res.status(400).json(formatResponse(false, null, 'No valid recipients found'));
    }

    // Create notifications for all users
    const notifications = uniqueUsers.map(user => ({
      recipient: user._id,
      sender: req.user.id,
      title,
      message,
      type: type || 'general',
      priority: priority || 'medium',
      data: data || {}
    }));

    const createdNotifications = await Notification.insertMany(notifications);

    // TODO: Send push notifications to users with FCM tokens
    // const usersWithTokens = uniqueUsers.filter(user => user.fcmToken);
    // if (usersWithTokens.length > 0) {
    //   await sendBulkPushNotifications(usersWithTokens, { title, message, data });
    // }

    res.status(201).json(formatResponse(true, {
      notificationsSent: createdNotifications.length,
      recipients: uniqueUsers.map(u => ({ id: u._id, name: u.name, role: u.role }))
    }, 'Broadcast notification sent successfully'));
  } catch (error) {
    console.error('Error broadcasting notification:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/notifications/:id/read
// @desc    Mark notification as read
// @access  Private
router.put('/:id/read', auth, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json(formatResponse(false, null, 'Notification not found'));
    }

    // Check if user owns this notification
    if (notification.recipient.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    notification.isRead = true;
    notification.readAt = new Date();
    await notification.save();

    res.json(formatResponse(true, notification, 'Notification marked as read'));
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/notifications/mark-all-read
// @desc    Mark all notifications as read
// @access  Private
router.put('/mark-all-read', auth, async (req, res) => {
  try {
    const result = await Notification.updateMany(
      { recipient: req.user.id, isRead: false },
      { isRead: true, readAt: new Date() }
    );

    res.json(formatResponse(true, { 
      modifiedCount: result.modifiedCount 
    }, 'All notifications marked as read'));
  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   DELETE /api/notifications/:id
// @desc    Delete notification
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json(formatResponse(false, null, 'Notification not found'));
    }

    // Check if user owns this notification or is admin
    if (notification.recipient.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    await Notification.findByIdAndDelete(req.params.id);

    res.json(formatResponse(true, null, 'Notification deleted successfully'));
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/notifications/fcm-token
// @desc    Update user's FCM token for push notifications
// @access  Private
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { fcmToken, deviceInfo } = req.body;

    if (!fcmToken) {
      return res.status(400).json(formatResponse(false, null, 'FCM token is required'));
    }

    await User.findByIdAndUpdate(req.user.id, {
      fcmToken,
      deviceInfo: deviceInfo || {}
    });

    res.json(formatResponse(true, null, 'FCM token updated successfully'));
  } catch (error) {
    console.error('Error updating FCM token:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/notifications/templates
// @desc    Get notification templates (Admin only)
// @access  Private (Admin)
router.get('/templates', [auth, requireRole(['admin'])], async (req, res) => {
  try {
    // Static templates - in production these could be from database
    const templates = [
      {
        id: 'order_confirmed',
        name: 'Order Confirmed',
        title: 'Order Confirmed',
        message: 'Your order #{orderId} has been confirmed and is being prepared.',
        type: 'order',
        priority: 'high',
        variables: ['orderId']
      },
      {
        id: 'order_ready',
        name: 'Order Ready for Pickup',
        title: 'Order Ready',
        message: 'Your order #{orderId} is ready for pickup.',
        type: 'order',
        priority: 'high',
        variables: ['orderId']
      },
      {
        id: 'order_delivered',
        name: 'Order Delivered',
        title: 'Order Delivered',
        message: 'Your order #{orderId} has been delivered successfully.',
        type: 'order',
        priority: 'medium',
        variables: ['orderId']
      },
      {
        id: 'eco_points_awarded',
        name: 'Eco Points Awarded',
        title: 'Eco Points Earned!',
        message: 'You earned {points} eco points for waste collection.',
        type: 'eco_points',
        priority: 'medium',
        variables: ['points']
      },
      {
        id: 'new_message',
        name: 'New Message',
        title: 'New Message',
        message: 'You have a new message from {senderName}.',
        type: 'chat',
        priority: 'medium',
        variables: ['senderName']
      }
    ];

    res.json(formatResponse(true, templates, 'Notification templates retrieved successfully'));
  } catch (error) {
    console.error('Error fetching templates:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/notifications/stats
// @desc    Get notification statistics (Admin only)
// @access  Private (Admin)
router.get('/stats', [auth, requireRole(['admin'])], async (req, res) => {
  try {
    const stats = await Notification.aggregate([
      {
        $group: {
          _id: null,
          totalNotifications: { $sum: 1 },
          readNotifications: { $sum: { $cond: ['$isRead', 1, 0] } },
          unreadNotifications: { $sum: { $cond: ['$isRead', 0, 1] } },
          byType: {
            $push: {
              type: '$type',
              priority: '$priority'
            }
          }
        }
      }
    ]);

    const typeBreakdown = await Notification.aggregate([
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          readCount: { $sum: { $cond: ['$isRead', 1, 0] } }
        }
      }
    ]);

    const summary = {
      ...(stats[0] || { totalNotifications: 0, readNotifications: 0, unreadNotifications: 0 }),
      typeBreakdown
    };

    res.json(formatResponse(true, summary, 'Notification statistics retrieved successfully'));
  } catch (error) {
    console.error('Error fetching notification stats:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

module.exports = router; 