const express = require("express");
const router = express.Router();
const User = require("../models/User");
const { auth } = require("../middleware/auth");
const { requireRole } = require("../middleware/roleAuth");
const {
  formatResponse,
  getPaginationParams,
  buildSortObject,
  validateKenyaPhone,
  formatKenyaPhone,
} = require("../utils/helpers");

// @route   GET /api/users/profile
// @desc    Get current user profile
// @access  Private -> works
router.get("/profile", auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select("-password");
    res.json(formatResponse(true, user, "Profile retrieved successfully"));
  } catch (error) {
    console.error("Error fetching profile:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put("/profile", auth, async (req, res) => {
  try {
    const {
      name,
      phone,
      bio,
      address,
      location,
      coordinates,
      profilePicture,
      additionalData,
    } = req.body;

    // Validate phone number if provided
    if (phone && !validateKenyaPhone(phone)) {
      return res
        .status(400)
        .json(formatResponse(false, null, "Invalid Kenya phone number format"));
    }

    // Build update object
    const updateData = {};
    if (name) updateData.name = name;
    if (phone) updateData.phone = formatKenyaPhone(phone);
    if (bio !== undefined) updateData.bio = bio;
    if (address !== undefined) updateData.address = address;
    if (location !== undefined) updateData.location = location;
    if (coordinates) updateData.coordinates = coordinates;
    if (profilePicture !== undefined)
      updateData.profilePicture = profilePicture;
    if (additionalData)
      updateData.additionalData = {
        ...req.user.additionalData,
        ...additionalData,
      };

    const updatedUser = await User.findByIdAndUpdate(req.user.id, updateData, {
      new: true,
      runValidators: true,
    }).select("-password");

    res.json(formatResponse(true, updatedUser, "Profile updated successfully"));
  } catch (error) {
    console.error("Error updating profile:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   GET /api/users
// @desc    Get all users (Admin only)
// @access  Private (Admin) - works
router.get("/", [auth, requireRole(["admin"])], async (req, res) => {
  try {
    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);

    // Build filter
    let filter = {};
    if (req.query.role) filter.role = req.query.role;
    if (req.query.isActive !== undefined)
      filter.isActive = req.query.isActive === "true";
    if (req.query.isVerified !== undefined)
      filter.isVerified = req.query.isVerified === "true";

    // Search functionality
    if (req.query.search) {
      const searchRegex = new RegExp(req.query.search, "i");
      filter.$or = [
        { name: searchRegex },
        { email: searchRegex },
        { phone: searchRegex },
      ];
    }

    const users = await User.find(filter)
      .select("-password")
      .sort(sortObj)
      .skip(skip)
      .limit(limit);

    const totalUsers = await User.countDocuments(filter);

    res.json(
      formatResponse(
        true,
        {
          users,
          pagination: {
            currentPage: page,
            totalPages: Math.ceil(totalUsers / limit),
            totalUsers,
          },
        },
        "Users retrieved successfully"
      )
    );
  } catch (error) {
    console.error("Error fetching users:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   GET /api/users/:id
// @desc    Get user by ID
// @access  Private (Admin or self) -> works
router.get("/:id", auth, async (req, res) => {
  try {
    // Only allow admins or user themselves to view profile
    if (req.user.role !== "admin" && req.user.id !== req.params.id) {
      return res.status(403).json(formatResponse(false, null, "Access denied"));
    }

    const user = await User.findById(req.params.id).select("-password");

    if (!user) {
      return res
        .status(404)
        .json(formatResponse(false, null, "User not found"));
    }

    res.json(formatResponse(true, user, "User retrieved successfully"));
  } catch (error) {
    console.error("Error fetching user:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   POST /api/users
// @desc    Create new user (Admin only)
// @access  Private (Admin) -> works
router.post("/", [auth, requireRole(["admin"])], async (req, res) => {
  try {
    const {
      name,
      email,
      phone,
      password,
      role,
      bio,
      address,
      location,
      coordinates,
      additionalData,
    } = req.body;

    // Validate required fields
    if (!name || !email || !phone || !password || !role) {
      return res
        .status(400)
        .json(formatResponse(false, null, "Missing required fields"));
    }

    // Validate phone number
    if (!validateKenyaPhone(phone)) {
      return res
        .status(400)
        .json(formatResponse(false, null, "Invalid Kenya phone number format"));
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { phone: formatKenyaPhone(phone) }],
    });

    if (existingUser) {
      return res
        .status(400)
        .json(
          formatResponse(
            false,
            null,
            "User with this email or phone already exists"
          )
        );
    }

    // Create user
    const userData = {
      name,
      email,
      phone: formatKenyaPhone(phone),
      password,
      role,
      bio: bio || "",
      address: address || "",
      location: location || "",
      coordinates,
      additionalData: additionalData || {},
      isVerified: true, // Admin-created users are auto-verified
    };

    const user = new User(userData);
    await user.save();

    const userResponse = await User.findById(user._id).select("-password");
    res
      .status(201)
      .json(formatResponse(true, userResponse, "User created successfully"));
  } catch (error) {
    console.error("Error creating user:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   PUT /api/users/:id
// @desc    Update user (Admin only)
// @access  Private (Admin) -> works
router.put("/:id", [auth, requireRole(["admin"])], async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res
        .status(404)
        .json(formatResponse(false, null, "User not found"));
    }

    const {
      name,
      email,
      phone,
      role,
      bio,
      address,
      location,
      coordinates,
      isActive,
      isVerified,
      additionalData,
    } = req.body;

    // Build update object
    const updateData = {};
    if (name) updateData.name = name;
    if (email) updateData.email = email;
    if (phone) {
      if (!validateKenyaPhone(phone)) {
        return res
          .status(400)
          .json(
            formatResponse(false, null, "Invalid Kenya phone number format")
          );
      }
      updateData.phone = formatKenyaPhone(phone);
    }
    if (role) updateData.role = role;
    if (bio !== undefined) updateData.bio = bio;
    if (address !== undefined) updateData.address = address;
    if (location !== undefined) updateData.location = location;
    if (coordinates) updateData.coordinates = coordinates;
    if (isActive !== undefined) updateData.isActive = isActive;
    if (isVerified !== undefined) updateData.isVerified = isVerified;
    if (additionalData)
      updateData.additionalData = { ...user.additionalData, ...additionalData };

    const updatedUser = await User.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).select("-password");

    res.json(formatResponse(true, updatedUser, "User updated successfully"));
  } catch (error) {
    console.error("Error updating user:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   DELETE /api/users/:id
// @desc    Delete user (Admin only)
// @access  Private (Admin) -> works
router.delete("/:id", [auth, requireRole(["admin"])], async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res
        .status(404)
        .json(formatResponse(false, null, "User not found"));
    }

    // Don't allow deleting admin users
    if (user.role === "admin") {
      return res
        .status(400)
        .json(formatResponse(false, null, "Cannot delete admin users"));
    }

    await User.findByIdAndDelete(req.params.id);

    res.json(formatResponse(true, null, "User deleted successfully"));
  } catch (error) {
    console.error("Error deleting user:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   POST /api/users/:id/toggle-status
// @desc    Toggle user active status (Admin only)
// @access  Private (Admin) -> works
router.post(
  "/:id/toggle-status",
  [auth, requireRole(["admin"])],
  async (req, res) => {
    try {
      const user = await User.findById(req.params.id);

      if (!user) {
        return res
          .status(404)
          .json(formatResponse(false, null, "User not found"));
      }

      user.isActive = !user.isActive;
      await user.save();

      res.json(
        formatResponse(
          true,
          { isActive: user.isActive },
          `User ${user.isActive ? "activated" : "deactivated"} successfully`
        )
      );
    } catch (error) {
      console.error("Error toggling user status:", error);
      res
        .status(500)
        .json(formatResponse(false, null, "Server error", error.message));
    }
  }
);

// @route   GET /api/users/role/:role
// @desc    Get users by role
// @access  Private (Admin, VendorAdmin for vendors) -> works
router.get("/role/:role", auth, async (req, res) => {
  try {
    const requestedRole = req.params.role;

    // Check permissions
    if (req.user.role !== "admin") {
      if (req.user.role === "vendorAdmin" && requestedRole !== "vendor") {
        return res
          .status(403)
          .json(formatResponse(false, null, "Access denied"));
      } else if (req.user.role !== "vendorAdmin") {
        return res
          .status(403)
          .json(formatResponse(false, null, "Access denied"));
      }
    }

    const { page, limit, skip } = getPaginationParams(req.query);
    const sortObj = buildSortObject(req.query.sortBy, req.query.order);

    let filter = { role: requestedRole, isActive: true };

    const users = await User.find(filter)
      .select("-password")
      .sort(sortObj)
      .skip(skip)
      .limit(limit);

    const totalUsers = await User.countDocuments(filter);

    res.json(
      formatResponse(
        true,
        {
          users,
          pagination: {
            currentPage: page,
            totalPages: Math.ceil(totalUsers / limit),
            totalUsers,
          },
        },
        `${requestedRole}s retrieved successfully`
      )
    );
  } catch (error) {
    console.error("Error fetching users by role:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

// @route   PUT /api/users/eco-points/award
// @desc    Award eco points to user (Connector only)
// @access  Private (Connector) --> needs to be checked
router.put(
  "/eco-points/award",
  [auth, requireRole(["connector"])],
  async (req, res) => {
    try {
      const { vendorId, points, reason } = req.body;

      if (!vendorId || !points || !reason) {
        return res
          .status(400)
          .json(formatResponse(false, null, "Missing required fields"));
      }

      const vendor = await User.findById(vendorId);
      if (!vendor || vendor.role !== "vendor") {
        return res
          .status(404)
          .json(formatResponse(false, null, "Vendor not found"));
      }

      // Update vendor eco points
      const updatedVendor = await User.findByIdAndUpdate(
        vendorId,
        {
          $inc: {
            ecoPoints: points,
            totalEcoPointsEarned: points,
          },
          $push: {
            "additionalData.ecoPointsHistory": {
              points,
              reason,
              awardedBy: req.user.id,
              awardedAt: new Date(),
            },
          },
        },
        { new: true }
      ).select("-password");

      res.json(
        formatResponse(true, updatedVendor, "Eco points awarded successfully")
      );
    } catch (error) {
      console.error("Error awarding eco points:", error);
      res
        .status(500)
        .json(formatResponse(false, null, "Server error", error.message));
    }
  }
);

// @route   GET /api/users/stats/summary
// @desc    Get user statistics summary
// @access  Private (Admin) -- works
router.get(
  "/stats/summary",
  [auth, requireRole(["admin"])],
  async (req, res) => {
    try {
      const stats = await User.aggregate([
        {
          $group: {
            _id: "$role",
            count: { $sum: 1 },
            active: { $sum: { $cond: ["$isActive", 1, 0] } },
            verified: { $sum: { $cond: ["$isVerified", 1, 0] } },
          },
        },
      ]);

      const totalUsers = await User.countDocuments();
      const activeUsers = await User.countDocuments({ isActive: true });
      const verifiedUsers = await User.countDocuments({ isVerified: true });

      const summary = {
        totalUsers,
        activeUsers,
        verifiedUsers,
        roleBreakdown: stats,
      };

      res.json(
        formatResponse(true, summary, "User statistics retrieved successfully")
      );
    } catch (error) {
      console.error("Error fetching user stats:", error);
      res
        .status(500)
        .json(formatResponse(false, null, "Server error", error.message));
    }
  }
);

// @route   GET /api/users/nearby/:role
// @desc    Get nearby users by role (for riders, connectors, vendors)
// @access  Private
router.get("/nearby/:role", auth, async (req, res) => {
  try {
    const { latitude, longitude, radius = 10 } = req.query; // radius in km
    const targetRole = req.params.role;

    if (!latitude || !longitude) {
      return res
        .status(400)
        .json(
          formatResponse(false, null, "Latitude and longitude are required")
        );
    }

    // Convert to numbers
    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);
    const radiusInMeters = parseFloat(radius) * 1000;

    const users = await User.find({
      role: targetRole,
      isActive: true,
      "coordinates.latitude": { $exists: true },
      "coordinates.longitude": { $exists: true },
      $expr: {
        $lte: [
          {
            $multiply: [
              6371000, // Earth radius in meters
              {
                $acos: {
                  $add: [
                    {
                      $multiply: [
                        {
                          $sin: {
                            $multiply: [
                              { $degreesToRadians: "$coordinates.latitude" },
                              1,
                            ],
                          },
                        },
                        {
                          $sin: { $multiply: [{ $degreesToRadians: lat }, 1] },
                        },
                      ],
                    },
                    {
                      $multiply: [
                        {
                          $cos: {
                            $multiply: [
                              { $degreesToRadians: "$coordinates.latitude" },
                              1,
                            ],
                          },
                        },
                        {
                          $cos: { $multiply: [{ $degreesToRadians: lat }, 1] },
                        },
                        {
                          $cos: {
                            $multiply: [
                              {
                                $degreesToRadians: {
                                  $subtract: ["$coordinates.longitude", lng],
                                },
                              },
                              1,
                            ],
                          },
                        },
                      ],
                    },
                  ],
                },
              },
            ],
          },
          radiusInMeters,
        ],
      },
    })
      .select("name phone email rating coordinates location profilePicture")
      .limit(20);

    res.json(
      formatResponse(
        true,
        users,
        `Nearby ${targetRole}s retrieved successfully`
      )
    );
  } catch (error) {
    console.error("Error fetching nearby users:", error);
    res
      .status(500)
      .json(formatResponse(false, null, "Server error", error.message));
  }
});

module.exports = router;
