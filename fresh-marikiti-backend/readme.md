# 🥬 Fresh Marikiti Backend

**Fresh Marikiti** is a Node.js/Express/MongoDB backend powering a multi-role fresh produce marketplace for customers, vendors, connectors, riders, and admins.

---

## 🚀 Features

- JWT Authentication
- Role-based Access: `customer`, `vendor`, `connector`, `rider`, `admin`, `vendorAdmin`
- Product & Order Management
- M-Pesa STK Push Payments
- Waste logging & Eco points
- Admin and Vendor management

---

## 📁 Project Structure

```
fresh-marikiti-backend/
├── config/         # DB config
├── controllers/    # Route logic
├── middleware/     # Auth/role checks
├── models/         # Mongoose schemas
├── routes/         # API endpoints
├── utils/          # M-Pesa, helpers
├── .env            # Environment variables
├── server.js       # Main server
```

---

## ⚙️ Setup

1. **Clone & Install**
  clone then
   ```bash
   cd fresh-marikiti-backend
   npm install
   ```

2. **.env Example**
   ```
   PORT=5000
   MONGO_URI=mongodb://127.0.0.1:27017/freshmarikiti
   JWT_SECRET=your_jwt_secret
   JWT_EXPIRES_IN=7d

   # M-Pesa
   MPESA_CONSUMER_KEY=your_consumer_key
   MPESA_CONSUMER_SECRET=your_consumer_secret
   MPESA_SHORTCODE=your_shortcode
   MPESA_PASSKEY=your_passkey
   MPESA_CALLBACK_URL=https://yourdomain.com/api/payments/mpesa/callback
   ```

3. **Run Dev Server**
   ```bash
   npm run dev
   ```
   > Runs on `http://localhost:5000`

---

## 🔐 Authentication

- `POST /api/auth/register` – Register (name, email, phone, password, role)
- `POST /api/auth/login` – Login (email, password)
- Returns: `{ token, user }`
- Use `Authorization: Bearer <token>` for protected routes

---

## 📦 API Endpoints

| Module      | Path Prefix        | Description                        |
|-------------|-------------------|------------------------------------|
| Auth        | `/api/auth`       | Register, login                    |
| Products    | `/api/products`   | CRUD, vendor-only for POST/PUT/DEL |
| Orders      | `/api/orders`     | Order placement, status            |
| Payments    | `/api/payments`   | M-Pesa STK push, callbacks         |
| Waste/Eco   | `/api/waste`      | Waste logging, eco points          |
| Admin Ops   | `/api/admin`      | User management (admin only)       |
| Test        | `/api/test`       | Role-based test endpoints          |

---

## 🧪 Example Endpoints

### Auth
- `POST /api/auth/register`  
  `{ name, email, phone, password, role }`
- `POST /api/auth/login`  
  `{ email, password }`

### Products
- `GET /api/products`  
  List all products
- `POST /api/products`  
  (Vendor only) Add product
- `PUT /api/products/:id`  
  (Vendor only) Update product
- `DELETE /api/products/:id`  
  (Vendor only) Delete product

### Orders
- `POST /api/orders`  
  Place order (customer)
- `GET /api/orders`  
  List orders (role-based)

### Payments
- `POST /api/payments/mpesa/pay`  
  Initiate M-Pesa STK push
- `POST /api/payments/mpesa/callback`  
  M-Pesa callback handler

### Waste/Eco
- `POST /api/waste/log`  
  (Connector) Log waste collected
- `GET /api/waste/vendor/points`  
  (Vendor) Get eco points

### Admin
- `GET /api/admin/users`  
  List users (admin)
- `PUT /api/admin/users/:id`  
  Update user (admin)

---

## 📝 Notes

- All protected routes require JWT in `Authorization` header.
- Role-based access enforced via middleware.
- Payments use Safaricom M-Pesa STK Push.
- Use Postman or Curl for testing.

---

## 📫 Contact

Built with ❤️ by the Fresh Marikiti dev team.
