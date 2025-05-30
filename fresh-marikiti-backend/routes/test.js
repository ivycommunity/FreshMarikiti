const express = require('express');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

const router = express.Router();

router.get('/vendor-area', authMiddleware, roleMiddleware(['vendor', 'vendorAdmin']), (req, res) => {
  res.json({ message: `Welcome ${req.user.name}, you are a vendor!` });
});

module.exports = router;
