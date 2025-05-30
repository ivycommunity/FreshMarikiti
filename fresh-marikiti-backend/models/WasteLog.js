const mongoose = require('mongoose');

const wasteLogSchema = new mongoose.Schema(
  {
    vendor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    connector: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    wasteType: {
      type: String,
      required: true,
      enum: ['organic', 'plastic', 'paper', 'other'],
    },
    quantityKg: {
      type: Number,
      required: true,
    },
    ecoPointsAwarded: {
      type: Number,
      required: true,
    },
    loggedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('WasteLog', wasteLogSchema);
