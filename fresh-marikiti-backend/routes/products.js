const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const { auth } = require('../middleware/auth');
const { requireRole } = require('../middleware/roleAuth');
const { 
  formatResponse, 
  getPaginationParams, 
  buildSortObject,
  generateProductSku,
  generateSearchKeywords,
  sanitizeSearchQuery
} = require('../utils/helpers');

// @route   GET /api/products
// @desc    Get all products with filtering and pagination
// @access  Public
router.get('/', async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);
    
    // Build filter object
    let filter = { isActive: true, isAvailable: true };
    
    // Category filter
    if (req.query.category) {
      filter.category = req.query.category;
    }
    
    // Subcategory filter
    if (req.query.subcategory) {
      filter.subcategory = req.query.subcategory;
    }
    
    // Vendor filter
    if (req.query.vendor) {
      filter.vendor = req.query.vendor;
    }
    
    // Price range filter
    if (req.query.minPrice || req.query.maxPrice) {
      filter.price = {};
      if (req.query.minPrice) filter.price.$gte = parseFloat(req.query.minPrice);
      if (req.query.maxPrice) filter.price.$lte = parseFloat(req.query.maxPrice);
    }
    
    // Rating filter
    if (req.query.minRating) {
      filter.rating = { $gte: parseFloat(req.query.minRating) };
    }
    
    // Freshness filter
    if (req.query.freshness) {
      filter.freshness = req.query.freshness;
    }
    
    // Organic filter
    if (req.query.organic === 'true') {
      filter.isOrganic = true;
    }
    
    // Local sourcing filter
    if (req.query.locallySourced === 'true') {
      filter.isLocallySourced = true;
    }
    
    // Search functionality
    if (req.query.search) {
      const searchQuery = sanitizeSearchQuery(req.query.search);
      filter.$or = [
        { name: { $regex: searchQuery, $options: 'i' } },
        { description: { $regex: searchQuery, $options: 'i' } },
        { vendorName: { $regex: searchQuery, $options: 'i' } },
        { searchKeywords: { $in: [new RegExp(searchQuery, 'i')] } },
        { tags: { $in: [new RegExp(searchQuery, 'i')] } }
      ];
    }
    
    // Execute query
    const products = await Product.find(filter)
      .populate('vendor', 'name email phone rating isActive')
      .sort(sortObj)
      .skip(skip)
      .limit(limit)
      .lean();
    
    // Get total count for pagination
    const totalProducts = await Product.countDocuments(filter);
    const totalPages = Math.ceil(totalProducts / limit);
    
    res.json(formatResponse(true, {
      products,
      pagination: {
        currentPage: page,
        totalPages,
        totalProducts,
        hasNext: page < totalPages,
        hasPrev: page > 1
      }
    }, 'Products retrieved successfully'));
    
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/products/featured
// @desc    Get featured products
// @access  Public
router.get('/featured', async (req, res) => {
  try {
    const { limit } = getPaginationParams(req.query);
    
    const products = await Product.find({ 
      isActive: true, 
      isAvailable: true, 
      isFeatured: true 
    })
      .populate('vendor', 'name rating')
      .sort({ rating: -1, totalSold: -1 })
      .limit(limit)
      .lean();
    
    res.json(formatResponse(true, products, 'Featured products retrieved successfully'));
  } catch (error) {
    console.error('Error fetching featured products:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/products/categories
// @desc    Get all product categories with counts
// @access  Public
router.get('/categories', async (req, res) => {
  try {
    const categories = await Product.aggregate([
      { $match: { isActive: true, isAvailable: true } },
      {
        $group: {
          _id: '$category',
          count: { $sum: 1 },
          subcategories: { $addToSet: '$subcategory' }
        }
      },
      { $sort: { count: -1 } }
    ]);
    
    res.json(formatResponse(true, categories, 'Categories retrieved successfully'));
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/products/:id
// @desc    Get single product by ID
// @access  Public
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id)
      .populate('vendor', 'name email phone rating totalRatings bio profilePicture location coordinates')
      .lean();
    
    if (!product) {
      return res.status(404).json(formatResponse(false, null, 'Product not found'));
    }
    
    // Increment view count (optional tracking)
    await Product.findByIdAndUpdate(req.params.id, { $inc: { views: 1 } });
    
    res.json(formatResponse(true, product, 'Product retrieved successfully'));
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/products
// @desc    Create new product (Vendor/VendorAdmin only)
// @access  Private
router.post('/', [auth, requireRole(['vendor', 'vendorAdmin'])], async (req, res) => {
  try {
    const {
      name,
      description,
      category,
      subcategory,
      price,
      originalPrice,
      discount,
      unit,
      stock,
      minStock,
      images,
      freshness,
      expiryDate,
      harvestDate,
      origin,
      tags,
      nutrition,
      isOrganic,
      isLocallySourced,
      carbonFootprint,
      ecoPointsReward
    } = req.body;
    
    // For vendor admins, they can specify which vendor this product belongs to
    let vendorId = req.user.id;
    let vendorName = req.user.name;
    
    if (req.user.role === 'vendorAdmin' && req.body.vendorId) {
      vendorId = req.body.vendorId;
      const vendor = await User.findById(vendorId);
      if (!vendor || vendor.role !== 'vendor') {
        return res.status(400).json(formatResponse(false, null, 'Invalid vendor specified'));
      }
      vendorName = vendor.name;
    }
    
    // Generate SKU and search keywords
    const vendorSku = generateProductSku(vendorId, name);
    
    const productData = {
      name,
      description,
      category,
      subcategory,
      vendor: vendorId,
      vendorName,
      price,
      originalPrice: originalPrice || price,
      discount: discount || 0,
      unit,
      stock,
      minStock: minStock || 5,
      images,
      primaryImage: images[0] || '',
      freshness,
      expiryDate,
      harvestDate,
      origin,
      tags: tags || [],
      nutrition,
      isOrganic: isOrganic || false,
      isLocallySourced: isLocallySourced || false,
      carbonFootprint: carbonFootprint || 'medium',
      ecoPointsReward: ecoPointsReward || 1,
      vendorSku
    };
    
    // Generate search keywords
    const tempProduct = { ...productData };
    productData.searchKeywords = generateSearchKeywords(tempProduct);
    
    const product = new Product(productData);
    await product.save();
    
    const populatedProduct = await Product.findById(product._id)
      .populate('vendor', 'name email phone rating');
    
    res.status(201).json(formatResponse(true, populatedProduct, 'Product created successfully'));
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/products/:id
// @desc    Update product (Vendor/VendorAdmin only)
// @access  Private
router.put('/:id', [auth, requireRole(['vendor', 'vendorAdmin'])], async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json(formatResponse(false, null, 'Product not found'));
    }
    
    // Check if user owns this product or is vendor admin
    if (req.user.role === 'vendor' && product.vendor.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Not authorized to update this product'));
    }
    
    // Update fields
    const updateFields = { ...req.body };
    delete updateFields.vendor; // Don't allow changing vendor
    delete updateFields.vendorName; // Don't allow changing vendor name
    
    // Update search keywords if name, category, or tags changed
    if (updateFields.name || updateFields.category || updateFields.tags) {
      const tempProduct = { ...product.toObject(), ...updateFields };
      updateFields.searchKeywords = generateSearchKeywords(tempProduct);
    }
    
    const updatedProduct = await Product.findByIdAndUpdate(
      req.params.id,
      updateFields,
      { new: true, runValidators: true }
    ).populate('vendor', 'name email phone rating');
    
    res.json(formatResponse(true, updatedProduct, 'Product updated successfully'));
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   DELETE /api/products/:id
// @desc    Delete product (Vendor/VendorAdmin only)
// @access  Private
router.delete('/:id', [auth, requireRole(['vendor', 'vendorAdmin'])], async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json(formatResponse(false, null, 'Product not found'));
    }
    
    // Check if user owns this product or is vendor admin
    if (req.user.role === 'vendor' && product.vendor.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Not authorized to delete this product'));
    }
    
    await Product.findByIdAndDelete(req.params.id);
    
    res.json(formatResponse(true, null, 'Product deleted successfully'));
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   PUT /api/products/:id/stock
// @desc    Update product stock
// @access  Private (Vendor/VendorAdmin)
router.put('/:id/stock', [auth, requireRole(['vendor', 'vendorAdmin'])], async (req, res) => {
  try {
    const { stock, operation } = req.body; // operation: 'set', 'add', 'subtract'
    
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json(formatResponse(false, null, 'Product not found'));
    }
    
    // Check authorization
    if (req.user.role === 'vendor' && product.vendor.toString() !== req.user.id) {
      return res.status(403).json(formatResponse(false, null, 'Not authorized'));
    }
    
    let newStock;
    switch (operation) {
      case 'add':
        newStock = product.stock + stock;
        break;
      case 'subtract':
        newStock = Math.max(0, product.stock - stock);
        break;
      default:
        newStock = stock;
    }
    
    const updatedProduct = await Product.findByIdAndUpdate(
      req.params.id,
      { 
        stock: newStock,
        isAvailable: newStock > 0
      },
      { new: true }
    );
    
    res.json(formatResponse(true, updatedProduct, 'Stock updated successfully'));
  } catch (error) {
    console.error('Error updating stock:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   GET /api/products/vendor/:vendorId
// @desc    Get products by vendor
// @access  Public
router.get('/vendor/:vendorId', async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);
    
    const products = await Product.find({ 
      vendor: req.params.vendorId, 
      isActive: true,
      isAvailable: true 
    })
      .populate('vendor', 'name rating location')
      .sort(sortObj)
      .skip(skip)
      .limit(limit);
    
    const totalProducts = await Product.countDocuments({ 
      vendor: req.params.vendorId, 
      isActive: true,
      isAvailable: true 
    });
    
    res.json(formatResponse(true, {
      products,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalProducts / limit),
        totalProducts
      }
    }, 'Vendor products retrieved successfully'));
  } catch (error) {
    console.error('Error fetching vendor products:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

// @route   POST /api/products/:id/toggle-featured
// @desc    Toggle product featured status (Admin only)
// @access  Private
router.post('/:id/toggle-featured', [auth, requireRole(['admin'])], async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    
    if (!product) {
      return res.status(404).json(formatResponse(false, null, 'Product not found'));
    }
    
    product.isFeatured = !product.isFeatured;
    await product.save();
    
    res.json(formatResponse(true, product, `Product ${product.isFeatured ? 'featured' : 'unfeatured'} successfully`));
  } catch (error) {
    console.error('Error toggling featured status:', error);
    res.status(500).json(formatResponse(false, null, 'Server error', error.message));
  }
});

module.exports = router; 