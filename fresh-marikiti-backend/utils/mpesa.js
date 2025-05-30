const axios = require('axios');
const moment = require('moment');
require('dotenv').config();

const consumerKey = process.env.MPESA_CONSUMER_KEY;
const consumerSecret = process.env.MPESA_CONSUMER_SECRET;
const shortcode = process.env.MPESA_SHORTCODE;
const passkey = process.env.MPESA_PASSKEY;
const lipaNaMpesaUrl = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';

let accessToken = null;

// Get OAuth token
async function getAccessToken() {
  const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');
  const { data } = await axios.get(
    'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
    { headers: { Authorization: `Basic ${auth}` } }
  );
  accessToken = data.access_token;
  return accessToken;
}

// Generate password for STK push
function generatePassword() {
  const timestamp = moment().format('YYYYMMDDHHmmss');
  const password = Buffer.from(shortcode + passkey + timestamp).toString('base64');
  return { password, timestamp };
}

// Initiate STK Push
async function lipaNaMpesa(phoneNumber, amount, accountReference, transactionDesc, callbackUrl) {
  if (!accessToken) {
    await getAccessToken();
  }

  const { password, timestamp } = generatePassword();

  const payload = {
    BusinessShortCode: shortcode,
    Password: password,
    Timestamp: timestamp,
    TransactionType: 'CustomerPayBillOnline',
    Amount: amount,
    PartyA: phoneNumber, // customer's phone number, e.g., 2547XXXXXXXX
    PartyB: shortcode,
    PhoneNumber: phoneNumber,
    CallBackURL: callbackUrl,
    AccountReference: accountReference,
    TransactionDesc: transactionDesc,
  };

  const response = await axios.post(lipaNaMpesaUrl, payload, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  return response.data;
}

module.exports = {
  lipaNaMpesa,
};
