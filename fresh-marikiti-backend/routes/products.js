const express = require('express');
const Product = require('../models/Product');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

const router = express.Router();

// Get all products (public)
router.get('/', async (req, res) => {
  try {
    const products = await Product.find().populate('vendor', 'name email');
    res.json(products);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Vendor adds a product
router.post(
  '/',
  authMiddleware,
  roleMiddleware(['vendor', 'vendorAdmin']),
  async (req, res) => {
    try {
      const { name, description, price, quantityAvailable, imageUrl, category } = req.body;

      const product = new Product({
        vendor: req.user._id,
        name,
        description,
        price,
        quantityAvailable,
        imageUrl,
        category,
      });

      await product.save();
      res.status(201).json(product);
    } catch (err) {
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Vendor updates their product
router.put(
  '/:id',
  authMiddleware,
  roleMiddleware(['vendor', 'vendorAdmin']),
  async (req, res) => {
    try {
      const product = await Product.findById(req.params.id);

      if (!product) {
        return res.status(404).json({ message: 'Product not found' });
      }

      // Only the vendor who owns the product or vendorAdmin can update
      if (
        product.vendor.toString() !== req.user._id.toString() &&
        req.user.role !== 'vendorAdmin'
      ) {
        return res.status(403).json({ message: 'Unauthorized' });
      }

      const updates = req.body;
      Object.assign(product, updates);
      await product.save();

      res.json(product);
    } catch (err) {
      res.status(500).json({ message: 'Server error' });
    }
  }
);

// Vendor deletes their product
router.delete(
  '/:id',
  authMiddleware,
  roleMiddleware(['vendor', 'vendorAdmin']),
  async (req, res) => {
    try {
      const product = await Product.findById(req.params.id);

      if (!product) {
        return res.status(404).json({ message: 'Product not found' });
      }

      if (
        product.vendor.toString() !== req.user._id.toString() &&
        req.user.role !== 'vendorAdmin'
      ) {
        return res.status(403).json({ message: 'Unauthorized' });
      }

      await product.remove();
      res.json({ message: 'Product removed' });
    } catch (err) {
      res.status(500).json({ message: 'Server error' });
    }
  }
);

module.exports = router;
