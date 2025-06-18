const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Product = require('../models/Product');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const { 
  formatResponse, 
  getPaginationParams, 
  buildSortObject,
  generateOrderId,
  calculateDistance,
  calculateDeliveryFee,
  calculateEcoPoints,
  calculateCommissions
} = require('../utils/helpers');

// @route   POST /api/orders
// @desc    Create new order
// @access  Private (Customer)
router.post('/', [auth, requireRole(['customer'])], async (req, res) => {
  try {
    const {
      items,
      deliveryAddress,
      deliveryType,
      scheduledDeliveryTime,
      paymentMethod,
      ecoPointsUsed
    } = req.body;

    // Validate items and calculate totals
    let subtotal = 0;
    let totalEcoPoints = 0;
    const orderItems = [];

    for (const item of items) {
      const product = await Product.findById(item.productId);
      
      if (!product) {
        return res.status(400).json(formatResponse(false, null, `Product ${item.productId} not found`));
      }

      if (!product.isAvailable || product.stock < item.quantity) {
        return res.status(400).json(formatResponse(false, null, `Insufficient stock for ${product.name}`));
      }

      const itemTotal = product.price * item.quantity;
      const itemEcoPoints = calculateEcoPoints(itemTotal, [{ ...product.toObject(), quantity: item.quantity }]);

      orderItems.push({
        product: product._id,
        productName: product.name,
        productImage: product.primaryImage,
        vendor: product.vendor,
        vendorName: product.vendorName,
        quantity: item.quantity,
        unit: product.unit,
        unitPrice: product.price,
        totalPrice: itemTotal,
        discount: 0,
        ecoPointsEarned: itemEcoPoints
      });

      subtotal += itemTotal;
      totalEcoPoints += itemEcoPoints;
    }

    // Calculate delivery fee based on distance
    const customerCoords = deliveryAddress.coordinates;
    // For now, use a default vendor location. In production, this would be calculated based on closest vendor
    const vendorCoords = { latitude: -1.2921, longitude: 36.8219 }; // Nairobi center
    const distance = calculateDistance(
      customerCoords.latitude, 
      customerCoords.longitude,
      vendorCoords.latitude, 
      vendorCoords.longitude
    );
    const deliveryFee = calculateDeliveryFee(distance);

    // Calculate other fees
    const serviceFee = subtotal * 0.02; // 2% service fee
    const tax = 0; // No tax for now

    // Apply eco points discount
    const ecoPointsDiscount = Math.min(ecoPointsUsed || 0, subtotal * 0.1); // Max 10% discount
    const totalAmount = subtotal + deliveryFee + serviceFee + tax - ecoPointsDiscount;

    // Calculate commissions
    const commissions = calculateCommissions(totalAmount);

    // Generate order ID
    const orderId = generateOrderId();

    // Create order
    const order = new Order({
      orderId,
      customer: req.user.id,
      customerName: req.user.name,
      customerPhone: req.user.phone,
      items: orderItems,
      deliveryAddress,
      deliveryType: deliveryType || 'standard',
      scheduledDeliveryTime,
      subtotal,
      deliveryFee,
      serviceFee,
      tax,
      totalAmount,
      paymentMethod,
      ecoPointsUsed: ecoPointsUsed || 0,
      ecoPointsEarned: totalEcoPoints,
      platformCommission: commissions.platform,
      riderCommission: commissions.rider,
      connectorCommission: commissions.connector,
      estimatedDeliveryTime: new Date(Date.now() + (deliveryType === 'express' ? 30 : 60) * 60 * 1000)
    });

    await order.save();

    // Update product stock
    for (const item of items) {
      await Product.findByIdAndUpdate(item.productId, {
        $inc: { stock: -item.quantity, totalSold: item.quantity }
      });
    }

    // Update user eco points if used
    if (ecoPointsUsed > 0) {
      await User.findByIdAndUpdate(req.user.id, {
        $inc: { ecoPointsUsed: ecoPointsUsed }
      });
    }

    const populatedOrder = await Order.findById(order._id)
      .populate('customer', 'name phone email')
      .populate('items.product', 'name images')
      .populate('items.vendor', 'name phone email');

    res.status(201).json(formatResponse(true, populatedOrder, 'Order created successfully'));
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/orders
// @desc    Get orders (filtered by user role)
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);

    let filter = {};

    // Role-based filtering
    switch (req.user.role) {
      case 'customer':
        filter.customer = req.user.id;
        break;
      case 'vendor':
        filter['items.vendor'] = req.user.id;
        break;
      case 'rider':
        filter.rider = req.user.id;
        break;
      case 'connector':
        filter.connector = req.user.id;
        break;
      case 'admin':
        // Admin can see all orders
        break;
      default:
        return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    // Status filter
    if (req.query.status) {
      filter.status = req.query.status;
    }

    // Date range filter
    if (req.query.startDate || req.query.endDate) {
      filter.createdAt = {};
      if (req.query.startDate) filter.createdAt.$gte = new Date(req.query.startDate);
      if (req.query.endDate) filter.createdAt.$lte = new Date(req.query.endDate);
    }

    const orders = await Order.find(filter)
      .populate('customer', 'name phone email')
      .populate('rider', 'name phone email')
      .populate('connector', 'name phone email')
      .populate('items.product', 'name images')
      .populate('items.vendor', 'name phone email')
      .sort(sortObj)
      .skip(skip)
      .limit(limit);

    const totalOrders = await Order.countDocuments(filter);

    res.json(formatResponse(true, {
      orders,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalOrders / limit),
        totalOrders
      }
    }, 'Orders retrieved successfully'));
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/orders/:id
// @desc    Get single order by ID
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('customer', 'name phone email profilePicture')
      .populate('rider', 'name phone email profilePicture rating')
      .populate('connector', 'name phone email profilePicture rating')
      .populate('items.product', 'name images description unit')
      .populate('items.vendor', 'name phone email profilePicture location rating');

    if (!order) {
      return res.status(404).json(formatResponse(false, null, 'Order not found'));
    }

    // Check if user has access to this order
    const hasAccess = 
      req.user.role === 'admin' ||
      order.customer.toString() === req.user.id ||
      order.rider?.toString() === req.user.id ||
      order.connector?.toString() === req.user.id ||
      order.items.some(item => item.vendor.toString() === req.user.id);

    if (!hasAccess) {
      return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    res.json(formatResponse(true, order, 'Order retrieved successfully'));
  } catch (error) {
    console.error('Error fetching order:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/orders/:id/status
// @desc    Update order status
// @access  Private
router.put('/:id/status', auth, async (req, res) => {
  try {
    const { status, notes } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json(formatResponse(false, null, 'Order not found'));
    }

    // Role-based status update permissions
    const allowedStatusUpdates = {
      vendor: ['confirmed', 'preparing', 'ready_for_pickup'],
      rider: ['picked_up', 'in_transit', 'delivered'],
      connector: ['confirmed', 'preparing', 'ready_for_pickup'],
      admin: ['pending', 'confirmed', 'preparing', 'ready_for_pickup', 'picked_up', 'in_transit', 'delivered', 'cancelled', 'refunded'],
      customer: ['cancelled'] // Only before confirmed
    };

    if (!allowedStatusUpdates[req.user.role]?.includes(status)) {
      return res.status(403).json(formatResponse(false, null, 'Not authorized to update to this status'));
    }

    // Additional validations
    if (req.user.role === 'customer' && status === 'cancelled' && order.status !== 'pending') {
      return res.status(400).json(formatResponse(false, null, 'Cannot cancel order after confirmation'));
    }

    // Update order status
    const updateData = { status };
    
    if (status === 'delivered') {
      updateData.actualDeliveryTime = new Date();
      
      // Award eco points to customer
      if (order.ecoPointsEarned > 0) {
        await User.findByIdAndUpdate(order.customer, {
          $inc: { 
            ecoPoints: order.ecoPointsEarned,
            totalEcoPointsEarned: order.ecoPointsEarned
          }
        });
      }
    }

    if (status === 'picked_up' && req.user.role === 'rider') {
      updateData.rider = req.user.id;
      updateData.riderName = req.user.name;
      updateData.riderPhone = req.user.phone;
    }

    if (notes) {
      if (!order.statusHistory) order.statusHistory = [];
      order.statusHistory.push({
        status,
        notes,
        updatedBy: req.user.id,
        updatedAt: new Date()
      });
    }

    const updatedOrder = await Order.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('customer rider connector items.vendor');

    res.json(formatResponse(true, updatedOrder, 'Order status updated successfully'));
  } catch (error) {
    console.error('Error updating order status:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/orders/:id/assign-rider
// @desc    Assign rider to order
// @access  Private (Admin/Connector)
router.post('/:id/assign-rider', [auth, requireRole(['admin', 'connector'])], async (req, res) => {
  try {
    const { riderId } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json(formatResponse(false, null, 'Order not found'));
    }

    const rider = await User.findById(riderId);
    if (!rider || rider.role !== 'rider') {
      return res.status(400).json(formatResponse(false, null, 'Invalid rider'));
    }

    const updatedOrder = await Order.findByIdAndUpdate(
      req.params.id,
      {
        rider: riderId,
        riderName: rider.name,
        riderPhone: rider.phone
      },
      { new: true }
    ).populate('customer rider connector items.vendor');

    res.json(formatResponse(true, updatedOrder, 'Rider assigned successfully'));
  } catch (error) {
    console.error('Error assigning rider:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/orders/:id/assign-connector
// @desc    Assign connector to order
// @access  Private (Admin)
router.post('/:id/assign-connector', [auth, requireRole(['admin'])], async (req, res) => {
  try {
    const { connectorId } = req.body;
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json(formatResponse(false, null, 'Order not found'));
    }

    const connector = await User.findById(connectorId);
    if (!connector || connector.role !== 'connector') {
      return res.status(400).json(formatResponse(false, null, 'Invalid connector'));
    }

    const updatedOrder = await Order.findByIdAndUpdate(
      req.params.id,
      {
        connector: connectorId,
        connectorName: connector.name
      },
      { new: true }
    ).populate('customer rider connector items.vendor');

    res.json(formatResponse(true, updatedOrder, 'Connector assigned successfully'));
  } catch (error) {
    console.error('Error assigning connector:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/orders/stats/summary
// @desc    Get order statistics summary
// @access  Private (Role-based)
router.get('/stats/summary', auth, async (req, res) => {
  try {
    let matchStage = {};

    // Role-based filtering
    switch (req.user.role) {
      case 'customer':
        matchStage.customer = req.user.id;
        break;
      case 'vendor':
        matchStage['items.vendor'] = req.user.id;
        break;
      case 'rider':
        matchStage.rider = req.user.id;
        break;
      case 'connector':
        matchStage.connector = req.user.id;
        break;
      case 'admin':
        // Admin can see all
        break;
      default:
        return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    const stats = await Order.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalOrders: { $sum: 1 },
          totalRevenue: { $sum: '$totalAmount' },
          averageOrderValue: { $avg: '$totalAmount' },
          pendingOrders: { $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] } },
          confirmedOrders: { $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] } },
          inTransitOrders: { $sum: { $cond: [{ $eq: ['$status', 'in_transit'] }, 1, 0] } },
          deliveredOrders: { $sum: { $cond: [{ $eq: ['$status', 'delivered'] }, 1, 0] } },
          cancelledOrders: { $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] } }
        }
      }
    ]);

    const summary = stats[0] || {
      totalOrders: 0,
      totalRevenue: 0,
      averageOrderValue: 0,
      pendingOrders: 0,
      confirmedOrders: 0,
      inTransitOrders: 0,
      deliveredOrders: 0,
      cancelledOrders: 0
    };

    res.json(formatResponse(true, summary, 'Order statistics retrieved successfully'));
  } catch (error) {
    console.error('Error fetching order stats:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/orders/available
// @desc    Get available orders for riders/connectors
// @access  Private (Rider/Connector)
router.get('/available', [auth, requireRole(['rider', 'connector'])], async (req, res) => {
  try {
    let filter = {};

    if (req.user.role === 'rider') {
      filter = { 
        status: 'ready_for_pickup',
        rider: { $exists: false }
      };
    } else if (req.user.role === 'connector') {
      filter = { 
        status: 'pending',
        connector: { $exists: false }
      };
    }

    const orders = await Order.find(filter)
      .populate('customer', 'name phone')
      .populate('items.vendor', 'name location coordinates')
      .sort({ createdAt: -1 })
      .limit(20);

    res.json(formatResponse(true, orders, 'Available orders retrieved successfully'));
  } catch (error) {
    console.error('Error fetching available orders:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

module.exports = router; 