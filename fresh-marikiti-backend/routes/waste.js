const express = require('express');
const WasteLog = require('../models/WasteLog');
const User = require('../models/User');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

const router = express.Router();

router.use(authMiddleware);

// Connector logs waste collected
router.post('/log', roleMiddleware('connector'), async (req, res) => {
  try {
    const { vendorId, wasteType, quantityKg } = req.body;
    if (!vendorId || !wasteType || !quantityKg) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Example: 1kg waste = 10 eco points (adjust logic as needed)
    const ecoPointsAwarded = quantityKg * 10;

    const wasteLog = new WasteLog({
      vendor: vendorId,
      connector: req.user._id,
      wasteType,
      quantityKg,
      ecoPointsAwarded,
    });

    await wasteLog.save();

    // Update vendor's ecoPoints
    const vendor = await User.findById(vendorId);
    if (vendor) {
      vendor.ecoPoints += ecoPointsAwarded;
      await vendor.save();
    }

    res.json({ message: 'Waste logged successfully', wasteLog });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Vendors get their total eco points
router.get('/vendor/points', roleMiddleware('vendor'), async (req, res) => {
  try {
    const vendor = await User.findById(req.user._id);
    res.json({ ecoPoints: vendor.ecoPoints || 0 });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
