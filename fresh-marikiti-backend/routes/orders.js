const express = require('express');
const Order = require('../models/Order');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Place a new order
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { vendor, products, totalAmount, deliveryAddress, phoneNumber } = req.body;
    if (!vendor || !products || !totalAmount || !deliveryAddress || !phoneNumber) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const order = new Order({
      customer: req.user._id,
      vendor,
      products,
      totalAmount,
      deliveryAddress,
      phoneNumber,
    });
    await order.save();

    // Send push notification to vendor if they have an FCM token
    const vendorUser = await User.findById(vendor);
    if (vendorUser && vendorUser.fcmToken) {
      const { sendPushNotification } = require('../utils/notification');
      try {
        await sendPushNotification(
          vendorUser.fcmToken,
          'New Order Received',
          'You have a new order from a customer.',
          { orderId: order._id.toString() }
        );
      } catch (err) {
        console.error('Failed to send push notification:', err.message);
      }
    }

    // Notification logic will be added in the next step

    res.status(201).json({ message: 'Order placed', order });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Vendor gets their own orders
router.get(
  '/my',
  authMiddleware,
  async (req, res) => {
    try {
      // Only vendors and vendorAdmins can use this endpoint
      if (!['vendor', 'vendorAdmin'].includes(req.user.role)) {
        return res.status(403).json({ message: 'Unauthorized' });
      }
      const orders = await Order.find({ vendor: req.user._id })
        .populate('customer', 'name email')
        .populate('products.product', 'name');
      res.json(orders);
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
);

// Vendor updates order status
router.patch(
  '/:id/status',
  authMiddleware,
  async (req, res) => {
    try {
      if (!['vendor', 'vendorAdmin'].includes(req.user.role)) {
        return res.status(403).json({ message: 'Unauthorized' });
      }
      const order = await Order.findById(req.params.id);
      if (!order) {
        return res.status(404).json({ message: 'Order not found' });
      }
      // Only the vendor who owns the order or vendorAdmin can update
      if (
        order.vendor.toString() !== req.user._id.toString() &&
        req.user.role !== 'vendorAdmin'
      ) {
        return res.status(403).json({ message: 'Unauthorized' });
      }
      const { status } = req.body;
      if (!status) {
        return res.status(400).json({ message: 'Status is required' });
      }
      order.status = status;
      await order.save();
      res.json({ message: 'Order status updated', order });
    } catch (err) {
      res.status(500).json({ message: err.message });
    }
  }
);

module.exports = router;
