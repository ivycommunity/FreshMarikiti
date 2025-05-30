const express = require("express");
const dotenv = require("dotenv");
const connectDB = require("./config/db");
const cors = require("cors");

dotenv.config();
connectDB();

const app = express(),
  PORT = process.env.PORT || 6000;

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Fresh Marikiti API is running...");
});

const authRoutes = require("./routes/auth"),
  wasteRoutes = require("./routes/waste"),
  adminRoutes = require("./routes/admin"),
  paymentRoutes = require("./routes/payments"),
  productRoutes = require("./routes/products"),
  testRoutes = require("./routes/test");

app.use("/api/auth", authRoutes);
app.use("/api/test", testRoutes);
app.use("/api/products", productRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/waste", wasteRoutes);

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
