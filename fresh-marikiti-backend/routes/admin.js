const express = require('express');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

const router = express.Router();

// Protect all routes, allow only admin
router.use(authMiddleware);
router.use(roleMiddleware('admin'));

// Get all users (optionally filter by role)
router.get('/users', async (req, res) => {
  try {
    const { role } = req.query;
    const filter = role ? { role } : {};
    const users = await User.find(filter).select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update user (e.g. activate/deactivate, change role)
router.put('/users/:id', async (req, res) => {
  try {
    const { isActive, role } = req.body;
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    if (typeof isActive === 'boolean') user.isActive = isActive;
    if (role && ['customer', 'vendor', 'connector', 'rider', 'admin', 'vendorAdmin'].includes(role)) {
      user.role = role;
    }

    await user.save();
    res.json({ message: 'User updated', user: { id: user._id, name: user.name, role: user.role, isActive: user.isActive } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
