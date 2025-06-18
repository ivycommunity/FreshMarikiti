# 🔌 Fresh Marikiti Backend API Documentation

## 🌟 Overview

Fresh Marikiti Backend is a **Connector-centric Node.js API server** built with Express.js that powers a unique marketplace platform. Unlike traditional delivery apps, it implements a **human intermediary model** where Connectors physically shop in markets, ensuring quality and bridging traditional vendors with digital customers.

## 📋 Table of Contents

- [🏗️ Server Architecture](#️-server-architecture)
- [🔄 Connector-Centric Business Model](#-connector-centric-business-model)
- [📁 Project Structure](#-project-structure)
- [⚠️ Current Integration Issues](#️-current-integration-issues)
- [🚀 Priority API Fixes](#-priority-api-fixes)
- [🔐 Authentication System](#-authentication-system)
- [🌐 API Endpoints Status](#-api-endpoints-status)
- [🗄️ Database Models](#️-database-models)
- [💼 Business Logic Implementation](#-business-logic-implementation)
- [🔄 Real-time Features](#-real-time-features)
- [⚙️ Configuration](#️-configuration)
- [🐛 Known Issues & Debugging](#-known-issues--debugging)
- [🔮 Integration Roadmap](#-integration-roadmap)

## 🏗️ Server Architecture

### **Technology Stack**
```
Runtime:     Node.js 18+
Framework:   Express.js 4.18+
Database:    MongoDB 6.0+ with Mongoose ODM
Real-time:   Socket.io 4.7+ (integration issues)
Auth:        JSON Web Tokens (JWT) - working
Security:    bcryptjs, CORS, helmet
Environment: dotenv for configuration
Payments:    M-Pesa integration (incomplete)
```

### **Current Architecture Issues**
```
❌ BROKEN FLOW:
Client Request → Express Router → Middleware → Controller → 
Mixed Demo/Real Data → Inconsistent Responses

✅ INTENDED FLOW:
Client Request → Express Router → Middleware → Business Logic → 
MongoDB Operations → Standardized Response
```

## 🔄 Connector-Centric Business Model

### **What Makes This API Different**
This isn't a standard marketplace API. It implements a **unique business model**:

```
Traditional:  Customer API → Vendor API → Rider API
Fresh Marikiti: Customer API → Connector API → Market/Vendor API → Rider API
                                ↓
                        Quality + Waste Management APIs
```

### **Connector Workflow API (Needs Implementation)**
```javascript
// Current Status: Routes exist, business logic incomplete

1. POST /api/orders/assign-connector     ✅ Route exists ❌ Logic incomplete
2. PUT  /api/connectors/accept-order     ✅ Route exists ❌ Business rules missing
3. POST /api/connectors/chat-customer    ✅ Socket exists ❌ Events mismatched
4. PUT  /api/connectors/shop-status      ❌ Route missing ❌ Logic missing  
5. POST /api/connectors/log-waste        ✅ Route exists ❌ Eco-points calc broken
6. PUT  /api/connectors/handoff-rider    ✅ Route exists ❌ Status sync broken
7. PUT  /api/orders/connector-complete   ✅ Route exists ❌ Commission calc wrong
```

### **Key Business Differentiators**
- **Connector Commission**: 15% of order value (vs typical 5% platform fee)
- **Waste-to-Eco-Points**: Converts vendor waste into platform currency  
- **Quality Assurance**: Physical inspection before purchase confirmation
- **Multi-Role Communication**: Customer ↔ Connector ↔ Vendor ↔ Rider workflow

## 📁 Project Structure

```
fresh-marikiti-backend/
├── server.js                   # Main server (Socket.io integration broken)
├── config/
│   └── db.js                  # MongoDB connection (working)
├── models/                     # Database models (complete, relationships need fixes)
│   ├── User.js                # ✅ Multi-role model complete
│   ├── Product.js             # ✅ Complete with vendor relations
│   ├── Order.js               # 🟡 Complete but status workflow broken
│   ├── Chat.js                # ❌ Model exists, Socket events broken
│   ├── Rating.js              # ✅ Complete functionality
│   └── Notification.js        # 🟡 Model works, real-time sync issues
├── routes/                     # API routes (mixed working/broken)
│   ├── auth.js                # ✅ Authentication works
│   ├── users.js               # 🟡 Basic CRUD works, role switching incomplete
│   ├── products.js            # 🟡 Basic CRUD works, filtering broken
│   ├── orders.js              # ❌ CRUD exists, status workflow broken
│   ├── chat.js                # ❌ Routes exist, Socket integration broken
│   ├── ratings.js             # ✅ Complete functionality
│   ├── waste.js               # ❌ Routes exist, business logic missing
│   ├── notifications.js       # 🟡 Basic routes work, real-time broken
│   └── payments.js            # ❌ Framework exists, M-Pesa webhook missing
├── middleware/                 # Middleware (working but incomplete)
│   ├── auth.js                # ✅ JWT authentication works
│   ├── roleCheck.js           # 🟡 Basic roles work, permission matrix incomplete
│   └── validation.js          # 🟡 Basic validation, business rules missing
└── scripts/                    # Database utilities (mixed demo/real data)
    ├── seed-users.js          # 🟡 Creates sample data, mixed with real users
    └── clear-database.js      # ✅ Works for testing
```

## ⚠️ Current Integration Issues

### **1. Demo Data Mixed with Real Implementation**
```javascript
// PROBLEM: Routes inconsistently return demo vs real data
app.get('/api/products', async (req, res) => {
  if (process.env.USE_DEMO === 'true') {
    return res.json(demoProducts); // Sometimes this
  } else {
    const products = await Product.find(); // Sometimes this
    return res.json(products);
  }
  // No clear separation leads to inconsistent behavior
});
```

### **2. Socket.io Events Don't Match Frontend**
```javascript
// PROBLEM: Backend socket events don't match frontend expectations
// Backend:
socket.on('sendMessage', (data) => { ... });

// Frontend expects:
socket.emit('send_message', data);

// Result: Messages send but don't persist or sync
```

### **3. Business Logic Scattered Across Routes**
```javascript
// PROBLEM: No centralized business logic
// Commission calculations in multiple places:
- routes/orders.js line 45 (wrong calculation)
- routes/payments.js line 23 (different calculation)  
- models/Order.js pre-save hook (another calculation)

// Result: Inconsistent commission values across platform
```

### **4. M-Pesa Integration Incomplete**
```javascript
// PROBLEM: Payment framework exists but webhook missing
app.post('/api/payments/mpesa', async (req, res) => {
  // Initiates payment successfully
  // But webhook endpoint for confirmation doesn't exist
  // Orders get created but payment status never updates
});
```

## 🚀 Priority API Fixes

### **🔥 TOP 5 CRITICAL BACKEND FIXES**

#### **1. Complete M-Pesa Payment Integration**
```javascript
// Files to fix:
- routes/payments.js (webhook endpoint missing)
- models/Order.js (payment status workflow)
- middleware/mpesa.js (create webhook validation)

// Current Issues:
❌ POST /api/payments/mpesa works but no confirmation webhook
❌ Payment status never updates from 'pending' to 'paid'
❌ Orders created but checkout process fails

// FIX NEEDED:
POST /api/payments/mpesa/webhook    // Handle M-Pesa confirmations
PUT  /api/orders/:id/payment-status // Update payment status
```

#### **2. Fix Socket.io Chat Integration**
```javascript
// Files to fix:
- server.js (Socket.io event handlers)
- routes/chat.js (message persistence)
- models/Chat.js (relationship fixes)

// Current Issues:
❌ Socket event names don't match frontend
❌ Messages send but don't persist in database
❌ Real-time sync only works sometimes

// FIX NEEDED:
// Standardize socket events:
socket.on('send_message', ...)     // Match frontend
socket.on('join_conversation', ...)
socket.on('typing_indicator', ...)
```

#### **3. Fix Order Status Synchronization**
```javascript
// Files to fix:
- routes/orders.js (status update endpoint)
- models/Order.js (status workflow validation)  
- Socket.io handlers (real-time status broadcasting)

// Current Issues:
❌ PUT /api/orders/:id/status doesn't sync across all roles
❌ Status updates don't trigger real-time notifications
❌ Order timeline shows incorrect timestamps

// FIX NEEDED:
// Implement proper status broadcasting:
io.to(`order_${orderId}`).emit('status_updated', orderData);
// Validate status transitions
// Update all related users (customer, vendor, rider, connector)
```

#### **4. Implement Connector Business Logic**
```javascript
// Files to fix:
- routes/connectors.js (create new route file)
- routes/orders.js (connector assignment logic)
- routes/waste.js (eco-points calculation)

// Current Issues:
❌ Connector workflow routes missing
❌ Waste logging doesn't calculate eco-points
❌ Connector commission calculations wrong
❌ Quality check process not implemented

// FIX NEEDED:
POST /api/connectors/accept-order
PUT  /api/connectors/update-shopping-status  
POST /api/connectors/log-waste
PUT  /api/connectors/handoff-to-rider
```

#### **5. Fix Product Filtering and Search**
```javascript
// Files to fix:
- routes/products.js (search and filter endpoints)
- models/Product.js (index optimization)
- middleware/validation.js (search validation)

// Current Issues:
❌ GET /api/products?category=... returns all products
❌ Location-based search broken
❌ Price range filtering doesn't work
❌ Search results inconsistent

// FIX NEEDED:
// Implement proper MongoDB aggregation pipeline
// Add geospatial indexing for location search  
// Fix category and price filtering logic
```

## 🔐 Authentication System

### **JWT Authentication (Working)**
```javascript
// Current implementation works correctly
const generateToken = (userId, role) => {
  return jwt.sign(
    { user: { id: userId, role: role } },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );
};

// Authentication middleware works
const auth = async (req, res, next) => {
  // Properly validates JWT tokens
  // Issue: Role switching validation incomplete
};
```

### **Role-Based Access Control (Needs Fixes)**
```javascript
// WORKING: Basic role detection
const ROLES = {
  CUSTOMER: 'customer',           
  VENDOR: 'vendor',              
  RIDER: 'rider',                
  CONNECTOR: 'connector',        // Unique role - needs business logic
  VENDOR_ADMIN: 'vendorAdmin',   
  ADMIN: 'admin'                 
};

// BROKEN: Permission matrix incomplete
const checkPermission = (role, action) => {
  // Basic permissions work
  // Complex connector permissions missing
  // Cross-role interactions not properly validated
};
```

## 🌐 API Endpoints Status

### **🟢 WORKING ENDPOINTS**
```javascript
✅ POST /api/auth/login          # Authentication works
✅ POST /api/auth/register       # User registration works  
✅ GET  /api/users/profile       # User profile retrieval
✅ GET  /api/products            # Basic product list (no filtering)
✅ POST /api/products            # Product creation (vendors)
✅ POST /api/orders              # Basic order creation
✅ GET  /api/orders              # Order history retrieval
✅ POST /api/ratings             # Rating creation
✅ GET  /api/ratings/:id         # Rating retrieval
```

### **🟡 PARTIALLY WORKING (Need Fixes)**
```javascript
🟡 PUT  /api/users/profile       # Updates profile, role switching broken
🟡 GET  /api/products?filters    # Basic list works, filtering broken
🟡 PUT  /api/products/:id        # Updates work, validation incomplete
🟡 PUT  /api/orders/:id/status   # Status updates, sync across roles broken
🟡 GET  /api/notifications       # Basic retrieval, real-time sync issues
🟡 PUT  /api/notifications/:id   # Mark as read, broadcasting broken
```

### **🔴 BROKEN/MISSING ENDPOINTS (Priority Fixes)**
```javascript
❌ POST /api/payments/mpesa/webhook    # M-Pesa confirmation missing
❌ PUT  /api/orders/:id/payment-status # Payment status updates fail
❌ POST /api/chat/messages             # Message persistence broken
❌ PUT  /api/chat/messages/:id/read    # Read status updates fail
❌ POST /api/connectors/accept-order   # Connector workflow missing
❌ PUT  /api/connectors/shopping-status # Shopping status updates missing
❌ POST /api/waste/log                 # Waste logging broken
❌ PUT  /api/waste/calculate-ecopoints # Eco-points calculation missing
❌ GET  /api/analytics/*               # Analytics aggregation broken
❌ PUT  /api/admin/users/:id           # Admin user management fails
```

## 🗄️ Database Models

### **📦 Order Model (Needs Business Logic Fixes)**
```javascript
// WORKING: Basic CRUD operations
const orderSchema = new mongoose.Schema({
  orderId: { type: String, unique: true },    // ✅ Auto-generation works
  customer: { type: ObjectId, ref: 'User' },  // ✅ Relationships work
  items: [{ /* product details */ }],         // ✅ Multi-vendor support
  status: { type: String, enum: [...] },      // 🟡 Enum works, workflow broken
  
  // BROKEN: Business logic calculations
  platformCommission: { type: Number },       // ❌ Wrong calculation
  riderCommission: { type: Number },          // ❌ Wrong calculation  
  connectorCommission: { type: Number },      // ❌ Missing for new orders
  vendorEarnings: { type: Number },           // ❌ Inconsistent calculation
});

// FIX NEEDED: Proper commission calculation
orderSchema.pre('save', function(next) {
  // Current calculation wrong for connector model
  this.connectorCommission = this.totalAmount * 0.15; // Should be 15%
  this.platformCommission = this.totalAmount * 0.05;  // 5% platform fee
  this.vendorEarnings = this.subtotal - this.platformCommission - this.connectorCommission;
  next();
});
```

### **💬 Chat Model (Socket Integration Broken)**
```javascript
// WORKING: Message storage
const chatSchema = new mongoose.Schema({
  conversation: { type: ObjectId, ref: 'Conversation' }, // ✅ Relationships work
  sender: { type: ObjectId, ref: 'User' },               // ✅ User references work
  content: { type: String, required: true },             // ✅ Basic storage works
  timestamp: { type: Date, default: Date.now },          // ✅ Timestamps work
  
  // BROKEN: Real-time features
  isRead: { type: Boolean, default: false },             // ❌ Read status not syncing
  messageType: { type: String, enum: [...] },            // ✅ Types work
});

// FIX NEEDED: Socket.io integration
// Messages save to database but don't broadcast to connected users
```

### **♻️ Waste Tracking Model (Business Logic Missing)**
```javascript
// WORKING: Basic data structure
const wasteSchema = new mongoose.Schema({
  vendor: { type: ObjectId, ref: 'User' },       // ✅ Vendor relationship works
  connector: { type: ObjectId, ref: 'User' },    // ✅ Connector relationship works
  wasteType: { type: String, required: true },   // ✅ Categorization works
  quantity: { type: Number, required: true },    // ✅ Quantity tracking works
  
  // BROKEN: Eco-points calculation
  ecoPointsAwarded: { type: Number, default: 0 }, // ❌ Always stays 0
  calculationFormula: String,                      // ❌ No formula implementation
});

// FIX NEEDED: Implement eco-points calculation logic
wasteSchema.pre('save', function(next) {
  // Calculate eco-points based on waste type and quantity
  this.ecoPointsAwarded = calculateEcoPoints(this.wasteType, this.quantity);
  next();
});
```

## 💼 Business Logic Implementation

### **Commission Structure (Needs Fixes)**
```javascript
// CURRENT BROKEN CALCULATION:
const calculateCommissions = (order) => {
  return {
    platformCommission: order.totalAmount * 0.05,        // ✅ Correct: 5%
    riderCommission: Math.max(order.deliveryFee * 0.8, 50), // ✅ Correct
    connectorCommission: order.totalAmount * 0.02,       // ❌ WRONG: Should be 15%
    vendorEarnings: order.subtotal - (order.totalAmount * 0.05) // ❌ WRONG: Missing connector cut
  };
};

// FIXED CALCULATION NEEDED:
const calculateCommissionsFixed = (order) => {
  const platformFee = order.totalAmount * 0.05;          // 5% platform fee
  const connectorFee = order.totalAmount * 0.15;         // 15% connector fee (UNIQUE)
  const riderFee = Math.max(order.deliveryFee * 0.8, 50); // 80% delivery or min 50 KES
  const vendorEarnings = order.subtotal - platformFee - connectorFee;
  
  return { platformFee, connectorFee, riderFee, vendorEarnings };
};
```

### **Eco-Points System (Incomplete Implementation)**
```javascript
// CURRENT BROKEN CALCULATION:
const calculateEcoPoints = (orderAmount) => {
  return Math.floor(orderAmount / 100); // Basic: 1 point per 100 KES
  // Missing: Waste bonus, connector logging, vendor rewards
};

// COMPLETE IMPLEMENTATION NEEDED:
const calculateEcoPointsComplete = (orderAmount, wasteLogged = 0, isOrganic = false) => {
  let basePoints = Math.floor(orderAmount / 100);           // 1 point per 100 KES
  let wasteBonus = wasteLogged * 5;                         // 5 points per kg waste
  let organicBonus = isOrganic ? basePoints * 0.1 : 0;      // 10% bonus for organic
  
  return Math.floor(basePoints + wasteBonus + organicBonus);
};
```

### **Order Status Workflow (Broken Transitions)**
```javascript
// CURRENT ISSUE: Status transitions not properly validated
const updateOrderStatus = async (orderId, newStatus) => {
  // Just updates without validation
  await Order.findByIdAndUpdate(orderId, { status: newStatus });
  // Missing: Role permission check, transition validation, real-time sync
};

// PROPER IMPLEMENTATION NEEDED:
const updateOrderStatusFixed = async (orderId, newStatus, userRole) => {
  const order = await Order.findById(orderId);
  
  // Validate status transition
  if (!canTransitionStatus(order.status, newStatus, userRole)) {
    throw new Error('Invalid status transition');
  }
  
  // Update with timestamp
  order.status = newStatus;
  order[`${newStatus}At`] = new Date();
  await order.save();
  
  // Broadcast to all stakeholders
  io.to(`order_${orderId}`).emit('status_updated', order);
  
  // Send push notifications
  await sendStatusNotification(order);
};
```

## 🔄 Real-time Features

### **Socket.io Setup (Broken Integration)**
```javascript
// CURRENT BROKEN SETUP:
io.on('connection', (socket) => {
  // Basic connection works
  console.log('User connected:', socket.id);
  
  // BROKEN: Event handlers don't match frontend
  socket.on('sendMessage', (data) => {
    // Frontend sends 'send_message' (underscore)
    // Backend listens for 'sendMessage' (camelCase)
    // Result: Events never trigger
  });
  
  // BROKEN: Message persistence fails
  socket.on('send_message', async (data) => {
    try {
      const message = await Chat.create(data);
      socket.broadcast.emit('new_message', message); // Only broadcasts, doesn't save properly
    } catch (error) {
      // Error handling incomplete
    }
  });
});

// FIXED IMPLEMENTATION NEEDED:
io.on('connection', (socket) => {
  socket.on('send_message', async (data) => {
    try {
      // Save to database first
      const message = new Chat({
        conversation: data.conversationId,
        sender: data.senderId,
        content: data.content,
        timestamp: new Date()
      });
      await message.save();
      
      // Then broadcast to conversation participants
      socket.to(`conversation_${data.conversationId}`).emit('message_received', message);
      
      // Update conversation last message
      await updateConversationLastMessage(data.conversationId, message);
      
    } catch (error) {
      socket.emit('message_error', { error: error.message });
    }
  });
});
```

### **Real-time Notifications (Partial Implementation)**
```javascript
// WORKING: Basic Firebase setup
const sendPushNotification = async (userId, notification) => {
  // Firebase messaging works
  await admin.messaging().send({
    token: user.fcmToken,
    notification: notification
  });
  
  // BROKEN: Database sync
  // Notification sent but not saved to database properly
  // Real-time UI updates don't sync
};

// FIX NEEDED: Complete notification pipeline
```

## ⚙️ Configuration

### **Environment Issues**
```bash
# CURRENT .env (Inconsistent usage)
NODE_ENV=development
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/fresh_marikiti
JWT_SECRET=your-jwt-secret
USE_DEMO=true  # ❌ Inconsistently applied across routes

# MISSING M-Pesa configuration
MPESA_CONSUMER_KEY=     # ❌ Needed for webhook
MPESA_CONSUMER_SECRET=  # ❌ Needed for webhook
MPESA_SHORTCODE=        # ❌ Needed for validation

# FIX NEEDED: Proper environment separation
DEMO_MODE=false         # Clear demo vs production separation
```

### **Database Connection (Working)**
```javascript
// MongoDB connection works correctly
const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    await setupIndexes(); // ✅ Database indexes work
  } catch (error) {
    console.error('Database connection error:', error);
    process.exit(1);
  }
};
```

## 🐛 Known Issues & Debugging

### **Critical Backend Issues**

#### **1. Payment Webhook Missing**
```bash
# Debug Steps:
1. Check routes/payments.js for webhook endpoint
2. Verify M-Pesa configuration in .env
3. Test webhook with ngrok for local development
4. Monitor payment status updates in database

# Common Error:
"Payment initiated but order status never updates"
# Root Cause: No webhook endpoint to receive M-Pesa confirmations
```

#### **2. Socket.io Event Mismatch**
```bash
# Debug Steps:
1. Check server.js Socket.io event names
2. Compare with frontend socket events
3. Monitor Socket.io admin panel for connections
4. Check database for message persistence

# Common Error:
"Socket connected but messages don't save"
# Root Cause: Event name mismatch and persistence logic issues
```

#### **3. Order Status Sync Issues**  
```bash
# Debug Steps:
1. Monitor PUT /api/orders/:id/status endpoint
2. Check if Socket.io broadcasts status updates
3. Verify all role users receive notifications
4. Check database for proper timestamp updates

# Common Error:
"Status updated for one user but others don't see it"
# Root Cause: Missing real-time broadcasting to all stakeholders
```

### **Database Debugging**
```bash
# Check for common issues:
mongosh mongodb://localhost:27017/fresh_marikiti

# Verify data consistency:
db.orders.find({ status: 'pending', paymentStatus: 'paid' }) # Should be empty
db.chats.find({ isRead: false }).count() # Check unread messages sync
db.users.find({ role: 'connector' }).count() # Verify connector accounts exist

# Check commission calculations:
db.orders.aggregate([
  { $group: { _id: null, 
    avgPlatformCommission: { $avg: "$platformCommission" },
    avgConnectorCommission: { $avg: "$connectorCommission" }
  }}
])
```

### **API Testing Commands**
```bash
# Test working endpoints:
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Test broken endpoints:
curl -X POST http://localhost:5000/api/payments/mpesa/webhook  # Should fail
curl -X PUT http://localhost:5000/api/orders/123/status \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status":"confirmed"}'  # Check if status syncs across users

# Test Socket.io connection:
# Use browser developer tools → Network → WebSocket
# Verify events match between frontend and backend
```

## 🔮 Integration Roadmap

### **Phase 1: Critical API Fixes (1-2 weeks)**
```javascript
🔥 WEEK 1:
- Implement M-Pesa webhook endpoint
- Fix Socket.io event name standardization
- Complete order status real-time broadcasting
- Implement cross-role status synchronization

🔥 WEEK 2:
- Fix product filtering and search endpoints
- Complete chat message persistence
- Implement proper error handling across all routes
- Clean up demo data mixed with real implementations
```

### **Phase 2: Connector Business Logic (2-3 weeks)**
```javascript
🔄 Connector-specific backend implementation:
- Create connector workflow routes
- Implement waste logging → eco-points calculation pipeline
- Fix connector commission calculations (15% of order value)
- Build connector-rider handoff process
- Implement quality check validation logic
```

### **Phase 3: Admin & Analytics (1 week)**
```javascript
✨ Admin panel backend fixes:
- Fix admin user management endpoints
- Implement analytics data aggregation
- Complete platform monitoring APIs
- Fix notification broadcasting system
- Implement proper audit logging
```

### **Phase 4: Production Readiness (1 week)**
```javascript
🚀 Production preparation:
- Complete error handling and logging
- Implement rate limiting and security headers
- Optimize database queries and indexing
- Add comprehensive API testing
- Documentation updates and API versioning
```

---

## 📞 Backend Development Support

### **Immediate Debugging Checklist**
1. ✅ Test M-Pesa webhook endpoint creation
2. ✅ Verify Socket.io event names match frontend
3. ✅ Check order status updates broadcast to all users
4. ✅ Monitor commission calculations in database
5. ✅ Test product filtering endpoints

### **Critical Integration Priorities**
1. **M-Pesa webhook** - Blocks payment completion
2. **Socket.io standardization** - Essential for real-time features
3. **Order status sync** - Core to business model
4. **Connector workflow** - Unique business differentiator  
5. **Demo data cleanup** - Required for production deployment

**Fresh Marikiti Backend API** - Building the server infrastructure to revolutionize Kenya's fresh produce markets! 🇰🇪

---

*Last Updated: January 2025*
*Status: Integration Phase - Fixing Core API Workflows*
*Priority: Make Backend Support Frontend Integration* 