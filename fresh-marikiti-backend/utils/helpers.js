const crypto = require('crypto');

/**
 * Generate unique order ID
 */
const generateOrderId = () => {
  const prefix = 'FM';
  const timestamp = Date.now().toString().slice(-6);
  const random = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `${prefix}${timestamp}${random}`;
};

/**
 * Generate unique product SKU
 */
const generateProductSku = (vendorId, productName) => {
  const vendorPrefix = vendorId.toString().slice(-4);
  const namePrefix = productName.substring(0, 3).toUpperCase();
  const random = Math.random().toString(36).substring(2, 4).toUpperCase();
  return `${namePrefix}${vendorPrefix}${random}`;
};

/**
 * Calculate distance between two coordinates using Haversine formula
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Radius of Earth in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // Distance in kilometers
};

/**
 * Calculate delivery fee based on distance
 */
const calculateDeliveryFee = (distance) => {
  const baseFee = 50; // Base fee in KES
  const ratePerKm = 20; // Rate per km in KES
  const maxFee = 500; // Maximum delivery fee
  
  if (distance <= 2) return baseFee;
  
  const fee = baseFee + ((distance - 2) * ratePerKm);
  return Math.min(fee, maxFee);
};

/**
 * Calculate eco points based on order value and items
 */
const calculateEcoPoints = (orderValue, items) => {
  let basePoints = Math.floor(orderValue / 100); // 1 point per 100 KES
  
  // Bonus points for organic/eco-friendly items
  const ecoBonus = items.reduce((total, item) => {
    return total + (item.ecoPointsReward || 0) * item.quantity;
  }, 0);
  
  return basePoints + ecoBonus;
};

/**
 * Generate verification code (6 digits)
 */
const generateVerificationCode = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Generate reset token
 */
const generateResetToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

/**
 * Format price for display
 */
const formatPrice = (price, currency = 'KES') => {
  return `${currency} ${price.toLocaleString()}`;
};

/**
 * Sanitize search query
 */
const sanitizeSearchQuery = (query) => {
  return query
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s]/gi, '')
    .replace(/\s+/g, ' ');
};

/**
 * Generate search keywords from product data
 */
const generateSearchKeywords = (product) => {
  const keywords = new Set();
  
  // Add name words
  product.name.toLowerCase().split(' ').forEach(word => {
    if (word.length > 2) keywords.add(word);
  });
  
  // Add category and subcategory
  keywords.add(product.category.toLowerCase());
  if (product.subcategory) {
    keywords.add(product.subcategory.toLowerCase());
  }
  
  // Add vendor name
  product.vendorName.toLowerCase().split(' ').forEach(word => {
    if (word.length > 2) keywords.add(word);
  });
  
  // Add tags
  if (product.tags && product.tags.length > 0) {
    product.tags.forEach(tag => keywords.add(tag.toLowerCase()));
  }
  
  return Array.from(keywords);
};

/**
 * Validate Kenya phone number
 */
const validateKenyaPhone = (phone) => {
  const kenyaPhoneRegex = /^(\+254|254|0)(7|1)\d{8}$/;
  return kenyaPhoneRegex.test(phone);
};

/**
 * Format Kenya phone number to international format
 */
const formatKenyaPhone = (phone) => {
  // Remove any spaces or special characters
  phone = phone.replace(/[\s\-\(\)]/g, '');
  
  // Convert to international format
  if (phone.startsWith('0')) {
    return '+254' + phone.substring(1);
  } else if (phone.startsWith('254')) {
    return '+' + phone;
  } else if (phone.startsWith('+254')) {
    return phone;
  }
  
  return phone; // Return as is if format not recognized
};

/**
 * Calculate order commission for different roles
 */
const calculateCommissions = (orderTotal) => {
  const platformRate = 0.05; // 5% platform commission
  const riderRate = 0.15; // 15% of delivery fee
  const connectorRate = 0.10; // 10% of subtotal for connector
  
  return {
    platform: orderTotal * platformRate,
    rider: (orderTotal * 0.1) * riderRate, // Assuming delivery fee is ~10% of order
    connector: orderTotal * connectorRate
  };
};

/**
 * Generate time-based slots for delivery scheduling
 */
const generateDeliverySlots = (startDate = new Date()) => {
  const slots = [];
  const start = new Date(startDate);
  start.setHours(8, 0, 0, 0); // Start at 8 AM
  
  for (let i = 0; i < 12; i++) { // 12 slots (8 AM to 8 PM)
    const slotStart = new Date(start.getTime() + (i * 60 * 60 * 1000));
    const slotEnd = new Date(slotStart.getTime() + (60 * 60 * 1000));
    
    if (slotStart.getHours() >= 20) break; // Stop at 8 PM
    
    slots.push({
      id: i + 1,
      startTime: slotStart,
      endTime: slotEnd,
      label: `${slotStart.getHours()}:00 - ${slotEnd.getHours()}:00`,
      available: true
    });
  }
  
  return slots;
};

/**
 * Check if coordinates are within Kenya bounds (rough approximation)
 */
const isWithinKenya = (latitude, longitude) => {
  const kenyaBounds = {
    north: 5.0,
    south: -4.5,
    east: 42.0,
    west: 33.5
  };
  
  return (
    latitude >= kenyaBounds.south &&
    latitude <= kenyaBounds.north &&
    longitude >= kenyaBounds.west &&
    longitude <= kenyaBounds.east
  );
};

/**
 * Format response object
 */
const formatResponse = (success, data = null, message = '', error = null) => {
  const response = {
    success,
    timestamp: new Date().toISOString()
  };
  
  if (message) response.message = message;
  if (data) response.data = data;
  if (error) response.error = error;
  
  return response;
};

/**
 * Pagination helper
 */
const getPaginationParams = (query) => {
  const page = parseInt(query.page) || 1;
  const limit = parseInt(query.limit) || 10;
  const skip = (page - 1) * limit;
  
  return { page, limit, skip };
};

/**
 * Build sort object from query
 */
const buildSortObject = (sortBy, order = 'desc') => {
  const sortObj = {};
  if (sortBy) {
    sortObj[sortBy] = order === 'asc' ? 1 : -1;
  } else {
    sortObj.createdAt = -1; // Default sort by creation date
  }
  return sortObj;
};

module.exports = {
  generateOrderId,
  generateProductSku,
  calculateDistance,
  calculateDeliveryFee,
  calculateEcoPoints,
  generateVerificationCode,
  generateResetToken,
  formatPrice,
  sanitizeSearchQuery,
  generateSearchKeywords,
  validateKenyaPhone,
  formatKenyaPhone,
  calculateCommissions,
  generateDeliverySlots,
  isWithinKenya,
  formatResponse,
  getPaginationParams,
  buildSortObject
}; 