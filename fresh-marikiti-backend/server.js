const express = require('express');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const cors = require('cors');

dotenv.config();
connectDB();

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.send('Fresh Marikiti API is running...');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

const authRoutes = require('./routes/auth');
app.use('/api/auth', authRoutes);

const testRoutes = require('./routes/test');
app.use('/api/test', testRoutes);

const productRoutes = require('./routes/products');
app.use('/api/products', productRoutes);

const orderRoutes = require('./routes/orders');
app.use('/api/orders', orderRoutes);

const paymentRoutes = require('./routes/payments');
app.use('/api/payments', paymentRoutes);

const adminRoutes = require('./routes/admin');
app.use('/api/admin', adminRoutes);

const usersRoutes = require('./routes/users');
app.use('/api/users', usersRoutes);

const wasteRoutes = require('./routes/waste');
app.use('/api/waste', wasteRoutes);
