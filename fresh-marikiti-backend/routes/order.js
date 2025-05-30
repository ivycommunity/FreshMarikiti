const router = require("express").Router(),
  authMiddleware = require("./../middleware/authMiddleware"),
  orderSchema = require("./../models/Order");

//Create order request
router.post("/", authMiddleware, (request, response) => {});

module.exports = router;
