const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    vendor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },

    name: {
      type: String,
      required: true,
    },

    description: {
      type: String,
    },

    price: {
      type: Number,
      required: true,
    },

    quantityAvailable: {
      type: Number,
      required: true,
      default: 0,
    },

    imageUrl: {
      type: String,
    },

    category: {
      type: String,
      default: 'fresh produce',
    },

    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', productSchema);
