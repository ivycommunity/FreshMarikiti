const express = require('express');
const router = express.Router();
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const { formatResponse, getPaginationParams, buildSortObject } = require('../utils/helpers');

// Waste Request Schema (embedded in User model as additionalData)
const WasteRequest = {
  id: String,
  vendorId: String,
  vendorName: String,
  connectorId: String,
  connectorName: String,
  wasteType: String, // 'organic', 'packaging', 'mixed'
  quantity: Number, // in kg
  description: String,
  images: [String],
  ecoPointsAwarded: Number,
  status: String, // 'pending', 'verified', 'rejected'
  location: {
    latitude: Number,
    longitude: Number,
    address: String
  },
  createdAt: Date,
  verifiedAt: Date,
  verifiedBy: String
};

// @route   POST /api/waste/log
// @desc    Log waste collection (Connector only)
// @access  Private (Connector)
router.post('/log', [auth, requireRole(['connector'])], async (req, res) => {
  try {
    const {
      vendorId,
      wasteType,
      quantity,
      description,
      images,
      location
    } = req.body;

    // Validate required fields
    if (!vendorId || !wasteType || !quantity) {
      return res.status(400).json(formatResponse(false, null, 'Missing required fields'));
    }

    // Verify vendor exists
    const vendor = await User.findById(vendorId);
    if (!vendor || vendor.role !== 'vendor') {
      return res.status(404).json(formatResponse(false, null, 'Vendor not found'));
    }

    // Calculate eco points based on waste type and quantity
    const ecoPointsAwarded = calculateEcoPointsForWaste(wasteType, quantity);

    // Create waste request
    const wasteRequest = {
      id: new Date().getTime().toString(),
      vendorId,
      vendorName: vendor.name,
      connectorId: req.user.id,
      connectorName: req.user.name,
      wasteType,
      quantity,
      description: description || '',
      images: images || [],
      ecoPointsAwarded,
      status: 'verified', // Auto-verify for now, can add admin verification later
      location: location || {},
      createdAt: new Date(),
      verifiedAt: new Date(),
      verifiedBy: req.user.id
    };

    // Add to connector's waste log
    await User.findByIdAndUpdate(req.user.id, {
      $push: {
        'additionalData.wasteRequests': wasteRequest
      }
    });

    // Award eco points to vendor
    await User.findByIdAndUpdate(vendorId, {
      $inc: { 
        ecoPoints: ecoPointsAwarded,
        totalEcoPointsEarned: ecoPointsAwarded
      },
      $push: {
        'additionalData.ecoPointsHistory': {
          points: ecoPointsAwarded,
          reason: `Waste collection: ${quantity}kg of ${wasteType} waste`,
          awardedBy: req.user.id,
          awardedAt: new Date(),
          wasteRequestId: wasteRequest.id
        }
      }
    });

    res.status(201).json(formatResponse(true, wasteRequest, 'Waste logged and eco points awarded successfully'));
  } catch (error) {
    console.error('Error logging waste:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/waste/requests
// @desc    Get waste requests (role-based filtering)
// @access  Private
router.get('/requests', auth, async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);

    let matchStage = {};

    // Role-based filtering
    switch (req.user.role) {
      case 'connector':
        matchStage = { 'additionalData.wasteRequests.connectorId': req.user.id };
        break;
      case 'vendor':
        matchStage = { 'additionalData.wasteRequests.vendorId': req.user.id };
        break;
      case 'admin':
        // Admin can see all
        matchStage = { 'additionalData.wasteRequests': { $exists: true, $ne: [] } };
        break;
      default:
        return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    // Status filter
    if (req.query.status) {
      matchStage['additionalData.wasteRequests.status'] = req.query.status;
    }

    // Date range filter
    if (req.query.startDate || req.query.endDate) {
      const dateFilter = {};
      if (req.query.startDate) dateFilter.$gte = new Date(req.query.startDate);
      if (req.query.endDate) dateFilter.$lte = new Date(req.query.endDate);
      matchStage['additionalData.wasteRequests.createdAt'] = dateFilter;
    }

    const users = await User.aggregate([
      { $match: matchStage },
      { $unwind: '$additionalData.wasteRequests' },
      { $match: matchStage },
      { $sort: { 'additionalData.wasteRequests.createdAt': -1 } },
      { $skip: skip },
      { $limit: limit },
      {
        $project: {
          wasteRequest: '$additionalData.wasteRequests',
          _id: 0
        }
      }
    ]);

    const wasteRequests = users.map(u => u.wasteRequest);

    // Get total count
    const totalCount = await User.aggregate([
      { $match: matchStage },
      { $unwind: '$additionalData.wasteRequests' },
      { $match: matchStage },
      { $count: 'total' }
    ]);

    const totalRequests = totalCount[0]?.total || 0;

    res.json(formatResponse(true, {
      wasteRequests,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalRequests / limit),
        totalRequests
      }
    }, 'Waste requests retrieved successfully'));
  } catch (error) {
    console.error('Error fetching waste requests:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/waste/stats
// @desc    Get waste collection statistics
// @access  Private
router.get('/stats', auth, async (req, res) => {
  try {
    let matchStage = {};

    // Role-based filtering
    switch (req.user.role) {
      case 'connector':
        matchStage = { 'additionalData.wasteRequests.connectorId': req.user.id };
        break;
      case 'vendor':
        matchStage = { 'additionalData.wasteRequests.vendorId': req.user.id };
        break;
      case 'admin':
        // Admin can see all
        matchStage = { 'additionalData.wasteRequests': { $exists: true, $ne: [] } };
        break;
      default:
        return res.status(403).json(formatResponse(false, null, 'Access denied'));
    }

    const stats = await User.aggregate([
      { $match: matchStage },
      { $unwind: '$additionalData.wasteRequests' },
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalRequests: { $sum: 1 },
          totalQuantity: { $sum: '$additionalData.wasteRequests.quantity' },
          totalEcoPoints: { $sum: '$additionalData.wasteRequests.ecoPointsAwarded' },
          organicWaste: {
            $sum: {
              $cond: [
                { $eq: ['$additionalData.wasteRequests.wasteType', 'organic'] },
                '$additionalData.wasteRequests.quantity',
                0
              ]
            }
          },
          packagingWaste: {
            $sum: {
              $cond: [
                { $eq: ['$additionalData.wasteRequests.wasteType', 'packaging'] },
                '$additionalData.wasteRequests.quantity',
                0
              ]
            }
          },
          mixedWaste: {
            $sum: {
              $cond: [
                { $eq: ['$additionalData.wasteRequests.wasteType', 'mixed'] },
                '$additionalData.wasteRequests.quantity',
                0
              ]
            }
          }
        }
      }
    ]);

    const summary = stats[0] || {
      totalRequests: 0,
      totalQuantity: 0,
      totalEcoPoints: 0,
      organicWaste: 0,
      packagingWaste: 0,
      mixedWaste: 0
    };

    res.json(formatResponse(true, summary, 'Waste statistics retrieved successfully'));
  } catch (error) {
    console.error('Error fetching waste stats:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/waste/leaderboard
// @desc    Get eco points leaderboard
// @access  Public
router.get('/leaderboard', async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    const leaderboard = await User.find({
      role: 'vendor',
      isActive: true,
      totalEcoPointsEarned: { $gt: 0 }
    })
    .select('name profilePicture location totalEcoPointsEarned ecoPoints')
    .sort({ totalEcoPointsEarned: -1 })
    .limit(parseInt(limit));

    res.json(formatResponse(true, leaderboard, 'Eco points leaderboard retrieved successfully'));
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/waste/redeem
// @desc    Redeem eco points (Vendor only)
// @access  Private (Vendor)
router.post('/redeem', [auth, requireRole(['vendor'])], async (req, res) => {
  try {
    const { points, rewardType, description } = req.body;

    if (!points || !rewardType) {
      return res.status(400).json(formatResponse(false, null, 'Missing required fields'));
    }

    const user = await User.findById(req.user.id);
    
    // Check if user has enough points
    const availablePoints = user.ecoPoints - user.ecoPointsUsed;
    if (availablePoints < points) {
      return res.status(400).json(formatResponse(false, null, 'Insufficient eco points'));
    }

    // Update user points
    await User.findByIdAndUpdate(req.user.id, {
      $inc: { ecoPointsUsed: points },
      $push: {
        'additionalData.redemptionHistory': {
          points,
          rewardType,
          description: description || '',
          redeemedAt: new Date()
        }
      }
    });

    const updatedUser = await User.findById(req.user.id).select('-password');

    res.json(formatResponse(true, updatedUser, 'Eco points redeemed successfully'));
  } catch (error) {
    console.error('Error redeeming eco points:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/waste/rewards
// @desc    Get available rewards for eco points
// @access  Public
router.get('/rewards', async (req, res) => {
  try {
    // Static rewards catalog - in production this could be from database
    const rewards = [
      {
        id: 1,
        name: 'Market Stall Cleaning Supplies',
        description: 'Basic cleaning supplies for your market stall',
        pointsCost: 100,
        category: 'supplies',
        image: '/images/rewards/cleaning-supplies.jpg'
      },
      {
        id: 2,
        name: 'Eco-Friendly Packaging',
        description: 'Biodegradable packaging materials',
        pointsCost: 150,
        category: 'packaging',
        image: '/images/rewards/eco-packaging.jpg'
      },
      {
        id: 3,
        name: 'Fresh Marikiti T-Shirt',
        description: 'Official Fresh Marikiti branded t-shirt',
        pointsCost: 200,
        category: 'merchandise',
        image: '/images/rewards/tshirt.jpg'
      },
      {
        id: 4,
        name: 'Digital Scale',
        description: 'Accurate digital scale for weighing produce',
        pointsCost: 500,
        category: 'equipment',
        image: '/images/rewards/scale.jpg'
      },
      {
        id: 5,
        name: 'Cash Voucher - 500 KES',
        description: 'Cash voucher worth 500 Kenya Shillings',
        pointsCost: 1000,
        category: 'cash',
        image: '/images/rewards/voucher.jpg'
      }
    ];

    res.json(formatResponse(true, rewards, 'Rewards catalog retrieved successfully'));
  } catch (error) {
    console.error('Error fetching rewards:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// Helper function to calculate eco points based on waste type and quantity
function calculateEcoPointsForWaste(wasteType, quantity) {
  const pointsPerKg = {
    organic: 5,     // 5 points per kg of organic waste
    packaging: 3,   // 3 points per kg of packaging waste
    mixed: 2        // 2 points per kg of mixed waste
  };

  const basePoints = (pointsPerKg[wasteType] || 2) * quantity;
  
  // Bonus points for larger quantities (encourages bulk collection)
  let bonus = 0;
  if (quantity >= 10) bonus = Math.floor(quantity / 10) * 5;
  if (quantity >= 50) bonus += Math.floor(quantity / 50) * 10;
  
  return Math.floor(basePoints + bonus);
}

module.exports = router; 