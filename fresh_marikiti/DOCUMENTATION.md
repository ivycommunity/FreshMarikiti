# 📱 Fresh Marikiti Flutter App Documentation

## 🌟 Overview

Fresh Marikiti Flutter app is a **Connector-centric marketplace application** built with Flutter 3.19+ that revolutionizes fresh produce delivery through human intermediaries who physically shop in markets, ensuring quality and bridging traditional vendors with digital customers.

## 📋 Table of Contents

- [🏗️ App Architecture](#️-app-architecture)
- [🔄 Connector-Centric Model](#-connector-centric-model)
- [📁 Project Structure](#-project-structure)
- [🔧 Implementation Status](#-implementation-status)
- [⚠️ Critical Integration Issues](#️-critical-integration-issues)
- [🚀 Priority Fixes Needed](#-priority-fixes-needed)
- [🎯 State Management](#-state-management)
- [🌐 API Integration](#-api-integration)
- [📱 User Interfaces](#-user-interfaces)
- [⚙️ Configuration](#️-configuration)
- [🐛 Known Issues & Debugging](#-known-issues--debugging)
- [🔮 Integration Roadmap](#-integration-roadmap)

## 🏗️ App Architecture

### **Clean Architecture Pattern**
```
lib/
├── presentation/          # UI Layer (6 Role Interfaces)
├── core/
│   ├── providers/        # State Management (9 Providers - sync issues)
│   ├── services/         # Business Logic (26 services - integration gaps)
│   ├── models/          # Data Models (complete)
│   ├── config/          # App Configuration (needs demo/live split)
│   ├── constants/       # App Constants
│   └── utils/           # Helper Functions
└── main.dart            # App Entry Point
```

### **Current Data Flow Issues**
```
❌ BROKEN FLOW:
User Interaction → Provider → Service → Demo Data/API (inconsistent)
    ↓
UI Updates Sometimes, State Sync Fails

✅ INTENDED FLOW:
User Interaction → Provider → Service → Real API → Database
    ↓
Synchronized State Updates → Real-time UI Refresh
```

## 🔄 Connector-Centric Model

### **What Makes This App Unique**
Unlike traditional delivery apps (Customer → Restaurant → Rider), Fresh Marikiti introduces **Connectors**:

```
Traditional:  Customer → Vendor → Rider → Customer
Fresh Marikiti: Customer → Connector → Market/Vendor → Rider → Customer
                            ↓
                    Quality Check + Waste Management
```

### **Connector Workflow (Needs Integration)**
```dart
// Current Status: Screens exist, logic incomplete
1. Receive Order Assignment ✅ UI exists ❌ Logic broken
2. Chat with Customer ✅ UI exists ❌ Socket events mismatched  
3. Navigate to Market ✅ Maps work ❌ Route optimization incomplete
4. Shop & Quality Check ✅ UI exists ❌ Business logic missing
5. Log Vendor Waste ✅ UI exists ❌ Eco-points calculation broken
6. Hand to Rider ✅ UI exists ❌ Status synchronization fails
7. Track Completion ✅ UI exists ❌ Real-time updates broken
```

## 📁 Project Structure

### **🎯 Providers (State Management) - INTEGRATION ISSUES**
```dart
lib/core/providers/
├── auth_provider.dart           # ✅ Works, but role switching incomplete
├── cart_provider.dart           # 🟡 Basic cart works, multi-vendor splitting broken
├── chat_provider.dart           # ❌ Socket events don't match backend
├── location_provider.dart       # 🟡 GPS works, real-time tracking broken
├── notification_provider.dart   # 🟡 Firebase setup works, message sync issues
├── order_provider.dart          # ❌ Status updates don't sync across roles
├── product_provider.dart        # 🟡 Basic loading works, filtering broken
├── rating_provider.dart         # ✅ Basic functionality works
└── theme_provider.dart          # ✅ Works perfectly
```

### **🌐 Services (Business Logic) - NEEDS INTEGRATION**
```dart
lib/core/services/
├── api_service.dart             # 🟡 HTTP client works, error handling incomplete
├── auth_service.dart            # ✅ Login/logout works, role validation incomplete
├── cart_service.dart            # 🟡 Add/remove works, checkout integration broken
├── chat_service.dart            # ❌ Socket.io setup exists, events mismatched
├── connector_service.dart       # ❌ Framework exists, business logic missing
├── eco_points_service.dart      # ❌ Models exist, calculation logic incomplete
├── location_service.dart        # 🟡 GPS works, route optimization incomplete
├── notification_service.dart    # 🟡 Firebase works, real-time sync issues
├── order_service.dart           # ❌ CRUD exists, status workflow broken
├── payment_service.dart         # ❌ M-Pesa framework exists, webhook missing
├── product_service.dart         # 🟡 Basic CRUD works, advanced features broken
├── rating_service.dart          # ✅ Basic functionality complete
├── user_service.dart            # 🟡 Profile management works, role switching incomplete
└── waste_service.dart           # ❌ UI exists, backend integration missing
```

### **📱 Presentation Issues by Role**
```dart
lib/presentation/screens/
├── customer/               # 🟡 Core screens work, checkout payment broken
├── connector/              # ❌ All screens exist, workflow logic incomplete
├── vendor/                 # 🟡 Product management works, analytics broken
├── rider/                  # ❌ Basic UI exists, delivery workflow broken
├── admin/                  # ❌ UI exists, backend functions don't work
└── shared/                 # 🟡 Chat/maps work partially
```

## 🔧 Implementation Status

### **🟢 WORKING FEATURES**
```dart
✅ User authentication and role detection
✅ Basic product browsing and display
✅ Shopping cart add/remove functionality
✅ User profile management
✅ Google Maps integration and GPS
✅ Firebase push notification setup
✅ Real-time chat UI (Socket.io connection works)
✅ Basic order creation
✅ Theme switching and UI navigation
```

### **🟡 PARTIALLY WORKING (Need Integration)**
```dart
🟡 Multi-vendor cart (logic exists, checkout broken)
🟡 Order status tracking (updates work, sync across roles broken)
🟡 Product filtering (basic search works, advanced broken)
🟡 Location services (GPS works, real-time tracking broken)
🟡 Payment flow (M-Pesa setup exists, confirmation webhook missing)
🟡 Notification system (Firebase works, real-time sync issues)
🟡 Vendor analytics (UI exists, data aggregation broken)
```

### **🔴 BROKEN/INCOMPLETE (Priority Fixes)**
```dart
❌ Customer ↔ Connector chat (Socket events don't match backend)
❌ Complete checkout flow (payment confirmation fails)
❌ Real-time order tracking across all roles
❌ Connector shopping workflow (UI exists, business logic missing)
❌ Rider delivery navigation (maps work, status updates fail)
❌ Waste logging → eco-points pipeline
❌ Admin panel functions (UI exists, API endpoints fail)
❌ Demo data cleanup (mixed with real API calls)
```

## ⚠️ Critical Integration Issues

### **1. State Management Synchronization**
```dart
// PROBLEM: Providers don't sync properly
class OrderProvider extends ChangeNotifier {
  // Issue: Status updates in one provider don't reflect in others
  void updateOrderStatus(String orderId, String status) {
    // Updates local state but doesn't sync with:
    // - ChatProvider (for notifications)
    // - LocationProvider (for tracking)
    // - NotificationProvider (for alerts)
  }
}

// FIX NEEDED: Cross-provider communication system
```

### **2. Socket.io Event Mismatches**
```dart
// PROBLEM: Frontend-backend socket events don't match
// Frontend sends:
socket.emit('send_message', messageData);

// Backend expects different event names/structure
// Need to standardize socket event contracts
```

### **3. Demo Data vs Real API Inconsistency**  
```dart
// PROBLEM: App randomly switches between demo and real data
class ProductService {
  Future<List<Product>> getProducts() {
    if (AppConfig.useDemo) {
      return DemoData.products; // Sometimes this
    } else {
      return ApiService.get('/products'); // Sometimes this
    }
  }
}

// FIX NEEDED: Clean separation and proper environment switching
```

### **4. Payment Integration Breakdown**
```dart
// PROBLEM: Checkout process fails at payment confirmation
class PaymentService {
  Future<bool> processMpesaPayment(PaymentData data) {
    // Framework exists but webhook confirmation missing
    // Order gets created but payment status never updates
  }
}
```

## 🚀 Priority Fixes Needed

### **🔥 TOP 5 CRITICAL MOBILE APP FIXES**

#### **1. Fix Checkout + Payment Flow**
```dart
// Files to fix:
- lib/presentation/screens/customer/checkout_screen.dart
- lib/core/services/payment_service.dart  
- lib/core/providers/cart_provider.dart

// Issues:
❌ Payment confirmation doesn't trigger order completion
❌ Cart doesn't clear after successful payment
❌ Error handling shows generic messages

// FIX: Implement proper payment webhook handling
```

#### **2. Customer ↔ Connector Chat Integration**
```dart
// Files to fix:
- lib/core/services/chat_service.dart
- lib/core/providers/chat_provider.dart
- lib/presentation/screens/shared/chat_screen.dart

// Issues:
❌ Socket event names don't match backend
❌ Messages send but don't persist in database
❌ Real-time sync only works sometimes

// FIX: Standardize socket events, fix message persistence
```

#### **3. Real-time Order Status Sync**
```dart
// Files to fix:
- lib/core/providers/order_provider.dart
- lib/core/services/order_service.dart
- All role-specific order screens

// Issues:
❌ Status updates don't reflect across all user roles
❌ Real-time notifications inconsistent
❌ Order timeline shows incorrect information

// FIX: Implement proper real-time status broadcasting
```

#### **4. Product Browsing & Advanced Filtering**
```dart
// Files to fix:
- lib/presentation/screens/customer/product_list_screen.dart
- lib/core/services/product_service.dart
- lib/core/providers/product_provider.dart

// Issues:
❌ Category filtering broken
❌ Location-based search incomplete
❌ Price range filters don't work
❌ Search results inconsistent

// FIX: Complete filter implementation, fix API integration
```

#### **5. Rider Delivery Workflow**
```dart
// Files to fix:
- lib/presentation/screens/rider/delivery_screen.dart
- lib/core/services/location_service.dart
- lib/core/providers/location_provider.dart

// Issues:
❌ Navigation routing incomplete
❌ Status updates don't sync with order system
❌ Real-time location tracking broken
❌ Delivery completion flow fails

// FIX: Complete pickup → delivery → completion workflow
```

## 🎯 State Management

### **Provider Integration Issues**
```dart
// CURRENT BROKEN SETUP:
MultiProvider(
  providers: [
    // Each provider works independently
    // No cross-provider communication
    // State updates don't sync
  ],
)

// NEEDED FIX:
// Implement provider communication system
// Add state synchronization
// Fix cross-cutting concerns (notifications, real-time updates)
```

### **Critical State Sync Problems**
```dart
// 1. Cart state doesn't persist across app restarts
// 2. Order status updates don't trigger related provider updates
// 3. Chat messages don't sync with notification state
// 4. Location updates don't trigger in dependent screens
// 5. User role switching doesn't update relevant providers
```

## 🌐 API Integration

### **HTTP Client Issues**
```dart
// PROBLEM: Inconsistent API base URL switching
class ApiService {
  static String get baseUrl {
    // Sometimes points to emulator (10.0.2.2:5000)
    // Sometimes points to device IP
    // Sometimes uses demo data instead
    // Need proper environment management
  }
}
```

### **Authentication Flow Problems**
```dart
// PROBLEM: Token refresh doesn't work properly
class AuthService {
  Future<void> refreshToken() {
    // Token refresh exists but doesn't update all services
    // Some API calls still use expired tokens
    // Need centralized token management
  }
}
```

### **Error Handling Gaps**
```dart
// PROBLEM: Poor error handling and user feedback
try {
  await ApiService.get('/products');
} catch (e) {
  // Shows generic "Something went wrong" message
  // No specific error handling for different scenarios
  // Users don't know what actually failed
}
```

## 📱 User Interfaces

### **🛍️ Customer App Status**
```dart
// WORKING:
✅ Product browsing (basic)
✅ Shopping cart (add/remove)
✅ User profile management
✅ Basic order history

// BROKEN:
❌ Checkout payment confirmation
❌ Advanced product filtering
❌ Real-time order tracking
❌ Chat with connectors (messages don't sync)
❌ Eco-points display (calculation broken)
```

### **🔗 Connector App Status (UNIQUE ROLE)**
```dart
// WORKING:
✅ Order assignment UI
✅ Basic chat interface
✅ Product shopping screens

// BROKEN:
❌ Market navigation workflow
❌ Quality check process (business logic missing)
❌ Waste logging integration
❌ Eco-points calculation for vendors
❌ Rider handoff process
❌ Connector commission tracking
```

### **🏪 Vendor App Status**
```dart
// WORKING:
✅ Product management (CRUD operations)
✅ Basic order receiving
✅ Profile management

// BROKEN:
❌ Analytics dashboard (data aggregation fails)
❌ Inventory tracking integration
❌ Waste management (eco-points pipeline missing)
❌ Revenue tracking (commission calculations incorrect)
```

### **🚴 Rider App Status**
```dart
// WORKING:
✅ Available deliveries list
✅ Basic navigation integration

// BROKEN:
❌ Complete pickup → delivery → completion flow
❌ Real-time location sharing
❌ Status update synchronization
❌ Earnings tracking (payment calculations wrong)
❌ Customer communication during delivery
```

### **👨‍💼 Admin App Status**
```dart
// WORKING:
✅ Dashboard UI layout
✅ Basic user listing

// BROKEN:
❌ User management functions (API endpoints fail)
❌ Platform analytics (data aggregation broken)
❌ System configuration (settings don't save)
❌ Content management (updates don't persist)
```

## ⚙️ Configuration

### **Environment Issues**
```dart
// PROBLEM: No clear demo vs production separation
class AppConfig {
  static bool get useDemo => dotenv.env['USE_DEMO'] == 'true';
  
  // Issue: USE_DEMO flag inconsistently applied
  // Some services check it, others don't
  // Results in mixed demo/real data
}
```

### **Device Configuration Problems**
```bash
# WORKING: Network configuration
./scripts/switch_device_config.sh auto  # Sets correct IP

# MISSING: Data mode switching
./scripts/switch_device_config.sh demo  # Should enable demo mode
./scripts/switch_device_config.sh live  # Should enable production API
```

## 🐛 Known Issues & Debugging

### **Critical Frontend Issues**

#### **1. Payment Flow Debugging**
```dart
// Debug Steps:
1. Check payment_service.dart line 45 - webhook URL
2. Monitor network tab for failed M-Pesa requests
3. Check cart_provider.dart clearCart() method
4. Verify payment confirmation socket events

// Common Error:
"Payment initiated but confirmation timeout"
// Root Cause: Backend webhook endpoint not implemented
```

#### **2. Chat System Debugging**
```dart
// Debug Steps:  
1. Open browser dev tools → Network → WebSocket
2. Check socket event names: send_message vs sendMessage
3. Monitor chat_provider.dart state updates
4. Verify backend socket handler methods

// Common Error:
"Message sent but not appearing in chat"
// Root Cause: Event name mismatch frontend ↔ backend
```

#### **3. Order Status Debugging**
```dart
// Debug Steps:
1. Check order_provider.dart _updateStatus method
2. Monitor real-time socket events for status changes
3. Verify all role screens listen to same provider
4. Check database for status update timestamps

// Common Error:
"Status updated for vendor but rider doesn't see it"
// Root Cause: Cross-role state synchronization missing
```

### **State Management Debugging**
```dart
// Add debug logging to providers:
class OrderProvider extends ChangeNotifier {
  void updateOrder(Order order) {
    print('DEBUG: Updating order ${order.id} status: ${order.status}');
    // Check if notifyListeners() is called
    // Verify dependent providers are updated
  }
}
```

### **Demo Data Issues**
```dart
// Files containing demo data that needs cleanup:
- lib/core/services/demo_product_service.dart (remove)
- lib/core/models/demo_data.dart (remove)
- lib/core/config/demo_config.dart (proper demo mode)

// Replace hardcoded data with proper API integration
```

## 🔮 Integration Roadmap

### **Phase 1: Critical Fixes (1-2 weeks)**
```dart
🔥 WEEK 1:
- Fix checkout payment confirmation flow
- Standardize socket events for chat system
- Implement cross-provider state synchronization
- Complete order status real-time updates

🔥 WEEK 2:  
- Fix product filtering and search
- Complete rider delivery workflow
- Implement proper error handling
- Clean up demo data throughout app
```

### **Phase 2: Connector Workflow (2-3 weeks)**
```dart
🔄 Connector-specific fixes:
- Complete market shopping workflow
- Implement waste logging business logic
- Build eco-points calculation pipeline
- Fix connector-rider handoff process
- Implement connector commission tracking
```

### **Phase 3: Admin & Analytics (1 week)**
```dart
✨ Final integration:
- Fix admin panel API endpoints
- Implement vendor analytics data aggregation
- Complete platform monitoring features
- Performance optimization
- Production readiness testing
```

### **Phase 4: Polish & Testing (1 week)**
```dart
🚀 Production preparation:
- Comprehensive testing across all user roles
- Error handling and user feedback improvements
- Performance optimization
- Final demo data cleanup
- Documentation updates
```

---

## 📞 Mobile App Development Support

### **Immediate Debugging Checklist**
1. ✅ Check Socket.io connection in browser dev tools
2. ✅ Verify API base URL matches backend server
3. ✅ Test payment flow end-to-end
4. ✅ Monitor provider state changes in debug mode
5. ✅ Check demo data vs real API inconsistencies

### **Critical Integration Priorities**
1. **Payment confirmation** - Blocks basic app functionality
2. **Chat system** - Essential for connector communication  
3. **Order tracking** - Core to business model
4. **State synchronization** - Needed for all features
5. **Demo data cleanup** - Required for production readiness

**Fresh Marikiti Flutter App** - Connecting the pieces to revolutionize Kenya's fresh produce markets! 🇰🇪

---

*Last Updated: January 2025*
*Status: Integration Phase - Fixing Core Workflows*
*Priority: Make Existing Features Work Together* 