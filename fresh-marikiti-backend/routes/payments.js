const express = require('express');
const { lipaNaMpesa } = require('../utils/mpesa');
const authMiddleware = require('../middleware/authMiddleware');
const Order = require('../models/Order');

const router = express.Router();

// Initiate Mpesa payment (STK Push)
router.post('/mpesa/pay', authMiddleware, async (req, res) => {
  try {
    const { phoneNumber, amount, orderId } = req.body;

    if (!phoneNumber || !amount || !orderId) {
      return res.status(400).json({ message: 'Missing parameters' });
    }

    const callbackUrl = 'https://yourdomain.com/api/payment/mpesa/callback';

    const response = await lipaNaMpesa(
      phoneNumber,
      amount,
      `Order${orderId}`,
      'Fresh Marikiti Payment',
      callbackUrl
    );

    if (response.ResponseCode !== '0') {
      return res.status(400).json({ message: 'Mpesa payment request failed', details: response });
    }

    // Save CheckoutRequestID to order for tracking payment callback
    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ message: 'Order not found' });

    order.checkoutRequestID = response.CheckoutRequestID;
    order.paymentStatus = 'pending'; // mark payment as pending until confirmed
    await order.save();

    res.json({ message: 'Payment initiated', response });
  } catch (err) {
    res.status(500).json({ message: 'Mpesa payment error', error: err.message });
  }
});

// Handle Mpesa payment callback notifications
router.post('/mpesa/callback', async (req, res) => {
  try {
    const callbackData = req.body;

    const resultCode = callbackData.Body?.stkCallback?.ResultCode;
    const resultDesc = callbackData.Body?.stkCallback?.ResultDesc;
    const checkoutRequestID = callbackData.Body?.stkCallback?.CheckoutRequestID;
    const callbackMetadata = callbackData.Body?.stkCallback?.CallbackMetadata;

    if (resultCode === 0) {
      let amount, mpesaReceiptNumber, transactionDate, phoneNumber;

      callbackMetadata?.Item.forEach((item) => {
        switch (item.Name) {
          case 'Amount':
            amount = item.Value;
            break;
          case 'MpesaReceiptNumber':
            mpesaReceiptNumber = item.Value;
            break;
          case 'TransactionDate':
            transactionDate = item.Value;
            break;
          case 'PhoneNumber':
            phoneNumber = item.Value;
            break;
        }
      });

      const order = await Order.findOne({ checkoutRequestID });

      if (!order) {
        console.warn('Order not found for checkoutRequestID:', checkoutRequestID);
        return res.status(404).json({ message: 'Order not found' });
      }

      order.paymentStatus = 'paid';
      await order.save();

      console.log(`Order ${order._id} payment updated to PAID`);

      return res.status(200).json({ message: 'Payment processed successfully' });
    } else {
      console.log('Payment failed or cancelled:', resultDesc);
      return res.status(200).json({ message: 'Payment failed or cancelled' });
    }
  } catch (error) {
    console.error('Error processing Mpesa callback:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
