const express = require('express');
const User = require('../models/User');
const Order = require('../models/Order');
const WasteLog = require('../models/WasteLog');
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

// Helper function to get date range based on period
const getDateRange = (period) => {
  const now = new Date();
  let startDate;

  switch (period) {
    case 'Today':
      startDate = new Date(now.setHours(0, 0, 0, 0));
      break;
    case 'This Week':
      startDate = new Date(now.setDate(now.getDate() - now.getDay()));
      break;
    case 'This Month':
      startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      break;
    case 'This Year':
      startDate = new Date(now.getFullYear(), 0, 1);
      break;
    default:
      startDate = new Date(now.setMonth(now.getMonth() - 1)); // Default to last month
  }

  return { startDate, endDate: new Date() };
};

// Get general admin analytics
router.get('/analytics', async (req, res) => {
  try {
    const { period } = req.query;
    const { startDate, endDate } = getDateRange(period);

    // Get user metrics
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const newUsers = await User.countDocuments({ createdAt: { $gte: startDate, $lte: endDate } });

    // Get order metrics
    const totalOrders = await Order.countDocuments();
    const completedOrders = await Order.countDocuments({ status: { $in: ['completed', 'delivered'] } });
    const pendingOrders = await Order.countDocuments({ status: { $in: ['pending', 'processing'] } });
    const totalRevenue = await Order.aggregate([
      { $match: { status: { $in: ['completed', 'delivered'] } } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);

    // Get vendor metrics
    const totalVendors = await User.countDocuments({ role: 'vendor' });
    const activeVendors = await User.countDocuments({ role: 'vendor', isActive: true });
    const topVendor = await Order.aggregate([
      { $match: { status: { $in: ['completed', 'delivered'] } } },
      { $group: { _id: '$vendor', total: { $sum: '$totalAmount' } } },
      { $sort: { total: -1 } },
      { $limit: 1 },
      { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'vendor' } }
    ]);

    // Get waste metrics
    const wasteStats = await WasteLog.aggregate([
      { $match: { createdAt: { $gte: startDate, $lte: endDate } } },
      { $group: { 
        _id: null, 
        totalCollected: { $sum: '$quantityKg' },
        totalRecycled: { $sum: { $multiply: ['$quantityKg', 0.93] } } // Assuming 93% recycling rate
      }}
    ]);

    res.json({
      users: {
        total: totalUsers,
        active: activeUsers,
        new: newUsers,
        growth: ((newUsers / totalUsers) * 100).toFixed(1)
      },
      orders: {
        total: totalOrders,
        completed: completedOrders,
        pending: pendingOrders,
        revenue: totalRevenue[0]?.total || 0
      },
      vendors: {
        total: totalVendors,
        active: activeVendors,
        topPerformer: topVendor[0]?.vendor[0]?.name || 'N/A',
        averageRating: 4.5 // This would need to be calculated from reviews
      },
      waste: {
        collected: wasteStats[0]?.totalCollected || 0,
        recycled: wasteStats[0]?.totalRecycled || 0,
        efficiency: 93.0, // This could be calculated based on actual data
        reduction: 15.5 // This would need to be calculated based on historical data
      }
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get user-specific metrics
router.get('/analytics/users', async (req, res) => {
  try {
    const { period } = req.query;
    const { startDate, endDate } = getDateRange(period);

    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const newUsers = await User.countDocuments({ createdAt: { $gte: startDate, $lte: endDate } });
    const usersByRole = await User.aggregate([
      { $group: { _id: '$role', count: { $sum: 1 } } }
    ]);

    res.json({
      total: totalUsers,
      active: activeUsers,
      new: newUsers,
      growth: ((newUsers / totalUsers) * 100).toFixed(1),
      byRole: usersByRole.reduce((acc, curr) => ({ ...acc, [curr._id]: curr.count }), {})
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get order-specific metrics
router.get('/analytics/orders', async (req, res) => {
  try {
    const { period } = req.query;
    const { startDate, endDate } = getDateRange(period);

    const totalOrders = await Order.countDocuments();
    const completedOrders = await Order.countDocuments({ status: { $in: ['completed', 'delivered'] } });
    const pendingOrders = await Order.countDocuments({ status: { $in: ['pending', 'processing'] } });
    const totalRevenue = await Order.aggregate([
      { $match: { status: { $in: ['completed', 'delivered'] } } },
      { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);

    const ordersByStatus = await Order.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    res.json({
      total: totalOrders,
      completed: completedOrders,
      pending: pendingOrders,
      revenue: totalRevenue[0]?.total || 0,
      byStatus: ordersByStatus.reduce((acc, curr) => ({ ...acc, [curr._id]: curr.count }), {})
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get vendor-specific metrics
router.get('/analytics/vendors', async (req, res) => {
  try {
    const { period } = req.query;
    const { startDate, endDate } = getDateRange(period);

    const totalVendors = await User.countDocuments({ role: 'vendor' });
    const activeVendors = await User.countDocuments({ role: 'vendor', isActive: true });
    const topVendors = await Order.aggregate([
      { $match: { status: { $in: ['completed', 'delivered'] } } },
      { $group: { _id: '$vendor', total: { $sum: '$totalAmount' } } },
      { $sort: { total: -1 } },
      { $limit: 5 },
      { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'vendor' } }
    ]);

    res.json({
      total: totalVendors,
      active: activeVendors,
      topPerformers: topVendors.map(v => ({
        name: v.vendor[0]?.name || 'Unknown',
        total: v.total
      }))
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get waste-specific metrics
router.get('/analytics/waste', async (req, res) => {
  try {
    const { period } = req.query;
    const { startDate, endDate } = getDateRange(period);

    const wasteStats = await WasteLog.aggregate([
      { $match: { createdAt: { $gte: startDate, $lte: endDate } } },
      { $group: { 
        _id: null, 
        totalCollected: { $sum: '$quantityKg' },
        totalRecycled: { $sum: { $multiply: ['$quantityKg', 0.93] } }
      }}
    ]);

    const wasteByType = await WasteLog.aggregate([
      { $match: { createdAt: { $gte: startDate, $lte: endDate } } },
      { $group: { _id: '$wasteType', total: { $sum: '$quantityKg' } } }
    ]);

    res.json({
      collected: wasteStats[0]?.totalCollected || 0,
      recycled: wasteStats[0]?.totalRecycled || 0,
      efficiency: 93.0,
      byType: wasteByType.reduce((acc, curr) => ({ ...acc, [curr._id]: curr.total }), {})
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
