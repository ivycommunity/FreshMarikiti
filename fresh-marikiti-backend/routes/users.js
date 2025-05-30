const express = require('express');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Save or update FCM token for a user
router.post('/:id/fcm-token', authMiddleware, async (req, res) => {
  try {
    const userId = req.params.id;
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM token is required' });
    }

    // Only allow the user themselves or an admin to update
    if (req.user._id.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { fcmToken },
      { new: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ message: 'FCM token updated', user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router; 