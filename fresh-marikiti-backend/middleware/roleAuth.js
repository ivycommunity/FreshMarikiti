const { formatResponse } = require('../utils/helpers');

/**
 * Role-based authorization middleware
 * @param {Array} allowedRoles - Array of roles that are allowed to access the route
 * @returns {Function} Express middleware function
 */
const requireRole = (allowedRoles) => {
  return (req, res, next) => {
    try {
      // Check if user is authenticated (should be set by auth middleware)
      if (!req.user) {
        return res.status(401).json(formatResponse(false, null, 'Authentication required'));
      }

      // Check if user's role is in the allowed roles
      if (!allowedRoles.includes(req.user.role)) {
        return res.status(403).json(formatResponse(false, null, 'Access denied. Insufficient permissions.'));
      }

      // User has required role, proceed to next middleware
      next();
    } catch (error) {
      console.error('Role authorization error:', error);
      return res.status(500).json(formatResponse(false, null, 'Server error during authorization'));
    }
  };
};

/**
 * Check if user is admin
 */
const requireAdmin = requireRole(['admin']);

/**
 * Check if user is vendor or vendor admin
 */
const requireVendorAccess = requireRole(['vendor', 'vendorAdmin', 'admin']);

/**
 * Check if user is customer
 */
const requireCustomer = requireRole(['customer']);

/**
 * Check if user is rider
 */
const requireRider = requireRole(['rider']);

/**
 * Check if user is connector
 */
const requireConnector = requireRole(['connector']);

/**
 * Check if user owns the resource or is admin
 * @param {String} resourceUserField - Field name in the resource that contains the user ID
 */
const requireOwnershipOrAdmin = (resourceUserField = 'user') => {
  return (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json(formatResponse(false, null, 'Authentication required'));
      }

      // Admin can access anything
      if (req.user.role === 'admin') {
        return next();
      }

      // Check if user owns the resource
      const resourceUserId = req.resource && req.resource[resourceUserField];
      if (resourceUserId && resourceUserId.toString() === req.user.id) {
        return next();
      }

      // Check if the user ID is in the URL params
      if (req.params.userId && req.params.userId === req.user.id) {
        return next();
      }

      return res.status(403).json(formatResponse(false, null, 'Access denied. You can only access your own resources.'));
    } catch (error) {
      console.error('Ownership authorization error:', error);
      return res.status(500).json(formatResponse(false, null, 'Server error during authorization'));
    }
  };
};

/**
 * Conditional role check - allows access if user has any of the specified roles OR meets a condition
 * @param {Array} allowedRoles - Array of roles that are allowed
 * @param {Function} conditionFn - Function that returns true if access should be granted
 */
const requireRoleOrCondition = (allowedRoles, conditionFn) => {
  return (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json(formatResponse(false, null, 'Authentication required'));
      }

      // Check role first
      if (allowedRoles.includes(req.user.role)) {
        return next();
      }

      // Check condition
      if (conditionFn && conditionFn(req)) {
        return next();
      }

      return res.status(403).json(formatResponse(false, null, 'Access denied. Insufficient permissions.'));
    } catch (error) {
      console.error('Conditional authorization error:', error);
      return res.status(500).json(formatResponse(false, null, 'Server error during authorization'));
    }
  };
};

module.exports = {
  requireRole,
  requireAdmin,
  requireVendorAccess,
  requireCustomer,
  requireRider,
  requireConnector,
  requireOwnershipOrAdmin,
  requireRoleOrCondition
}; 