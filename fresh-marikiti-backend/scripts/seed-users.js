const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('../models/User');

// Load environment variables
dotenv.config();

// Database connection
const connectDB = async () => {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/fresh_marikiti';
    
    const options = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    };

    const conn = await mongoose.connect(mongoURI, options);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
    console.log(`Database: ${conn.connection.name}`);
    
    return conn;
  } catch (error) {
    console.error('Error connecting to MongoDB:', error.message);
    process.exit(1);
  }
};

// Sample locations in Nairobi for realistic data
const nairobiLocations = [
  {
    coordinates: { latitude: -1.2921, longitude: 36.8219 },
    location: 'CBD, Nairobi',
    address: 'Tom Mboya Street, Nairobi CBD'
  },
  {
    coordinates: { latitude: -1.3032, longitude: 36.7073 },
    location: 'Westlands, Nairobi',
    address: 'Waiyaki Way, Westlands'
  },
  {
    coordinates: { latitude: -1.2633, longitude: 36.8063 },
    location: 'Kasarani, Nairobi',
    address: 'Thika Road, Kasarani'
  },
  {
    coordinates: { latitude: -1.3644, longitude: 36.8322 },
    location: 'Karen, Nairobi',
    address: 'Karen Road, Karen'
  },
  {
    coordinates: { latitude: -1.2419, longitude: 36.8856 },
    location: 'Eastlands, Nairobi',
    address: 'Jogoo Road, Eastlands'
  },
  {
    coordinates: { latitude: -1.2558, longitude: 36.7893 },
    location: 'Kilimani, Nairobi',
    address: 'Argwings Kodhek Road, Kilimani'
  }
];

// User seed data with all required fields
const seedUsers = [
  {
    name: 'John Customer',
    email: 'customer@gmail.com',
    phone: '+254700000001',
    password: 'Customer123',
    role: 'customer',
    bio: 'Love fresh produce and supporting local vendors',
    isVerified: true,
    ecoPoints: 150,
    totalEcoPointsEarned: 200,
    ecoPointsUsed: 50,
    walletBalance: 2500,
    ...nairobiLocations[0],
    additionalData: {
      preferences: {
        preferredCategories: ['fruits', 'vegetables'],
        deliveryPreference: 'scheduled',
        paymentMethod: 'mpesa'
      },
      shoppingHistory: {
        totalOrders: 25,
        averageOrderValue: 850,
        lastOrderDate: new Date('2024-01-15')
      }
    }
  },
  {
    name: 'Mary Vendor',
    email: 'vendor@gmail.com',
    phone: '+254700000002',
    password: 'Vendor123',
    role: 'vendor',
    bio: 'Fresh produce vendor at Wakulima Market with 10+ years experience',
    isVerified: true,
    rating: 4.7,
    totalRatings: 324,
    ecoPoints: 580,
    totalEcoPointsEarned: 650,
    ecoPointsUsed: 70,
    walletBalance: 15750,
    ...nairobiLocations[1],
    additionalData: {
      marketInfo: {
        marketName: 'Wakulima Market',
        stallNumber: 'A-24',
        operatingHours: {
          open: '06:00',
          close: '18:00'
        },
        specializations: ['organic vegetables', 'tropical fruits']
      },
      businessStats: {
        yearsInBusiness: 10,
        totalSales: 2850000,
        activeProducts: 45,
        completedOrders: 1250
      },
      certifications: ['Organic Produce Certificate', 'Food Safety Certificate']
    }
  },
  {
    name: 'Peter Rider',
    email: 'rider@gmail.com',
    phone: '+254700000003',
    password: 'Rider123',
    role: 'rider',
    bio: 'Reliable delivery rider covering Nairobi and surrounding areas',
    isVerified: true,
    rating: 4.9,
    totalRatings: 567,
    ecoPoints: 320,
    totalEcoPointsEarned: 400,
    ecoPointsUsed: 80,
    walletBalance: 8900,
    ...nairobiLocations[2],
    additionalData: {
      riderInfo: {
        vehicleType: 'motorcycle',
        licenseNumber: 'KCA 123D',
        vehicleRegistration: 'KBA 456X',
        maxCapacity: '50kg',
        workingAreas: ['CBD', 'Westlands', 'Kasarani', 'Eastlands']
      },
      performanceStats: {
        totalDeliveries: 1450,
        onTimeDeliveryRate: 94.5,
        averageRating: 4.9,
        monthlyEarnings: 35000,
        completionRate: 98.2
      },
      availability: {
        isActive: true,
        currentStatus: 'available',
        workingHours: {
          start: '07:00',
          end: '20:00'
        }
      }
    }
  },
  {
    name: 'Grace Connector',
    email: 'connector@gmail.com',
    phone: '+254700000004',
    password: 'Connector123',
    role: 'connector',
    bio: 'Community connector helping bridge gaps between vendors and customers',
    isVerified: true,
    rating: 4.6,
    totalRatings: 128,
    ecoPoints: 410,
    totalEcoPointsEarned: 500,
    ecoPointsUsed: 90,
    walletBalance: 5200,
    ...nairobiLocations[3],
    additionalData: {
      connectorInfo: {
        specialization: 'vendor-customer relations',
        languagesSpoken: ['English', 'Swahili', 'Kikuyu'],
        coverageArea: 'Nairobi County',
        experienceYears: 3
      },
      performanceStats: {
        casesResolved: 245,
        resolutionRate: 92.5,
        averageResolutionTime: '2.5 hours',
        customerSatisfaction: 95.8
      },
      trainingCompleted: [
        'Customer Service Excellence',
        'Conflict Resolution',
        'Digital Literacy Training',
        'Food Safety Awareness'
      ]
    }
  },
  {
    name: 'Samuel Admin',
    email: 'admin@gmail.com',
    phone: '+254700000005',
    password: 'Admin123',
    role: 'admin',
    bio: 'System administrator overseeing the Fresh Marikiti platform',
    isVerified: true,
    rating: 5.0,
    totalRatings: 50,
    ecoPoints: 1000,
    totalEcoPointsEarned: 1200,
    ecoPointsUsed: 200,
    walletBalance: 0,
    ...nairobiLocations[4],
    additionalData: {
      adminInfo: {
        department: 'Platform Operations',
        accessLevel: 'super_admin',
        employeeId: 'FM-ADMIN-001',
        joinDate: new Date('2023-06-01'),
        responsibilities: [
          'User Management',
          'System Configuration',
          'Analytics & Reporting',
          'Security Management'
        ]
      },
      systemAccess: {
        canManageUsers: true,
        canViewAnalytics: true,
        canConfigureSystem: true,
        canManagePayments: true,
        canAccessSupport: true
      }
    }
  },
  {
    name: 'Rose Vendor Admin',
    email: 'vendoradmin@gmail.com',
    phone: '+254700000006',
    password: 'VendorAdmin123',
    role: 'vendorAdmin',
    bio: 'Vendor administrator managing Wakulima Market operations',
    isVerified: true,
    rating: 4.8,
    totalRatings: 89,
    ecoPoints: 720,
    totalEcoPointsEarned: 850,
    ecoPointsUsed: 130,
    walletBalance: 3400,
    ...nairobiLocations[5],
    additionalData: {
      vendorAdminInfo: {
        marketName: 'Wakulima Market',
        position: 'Market Administrator',
        managedVendors: 85,
        employeeId: 'WM-VA-001',
        workingHours: {
          start: '06:00',
          end: '19:00'
        }
      },
      managementStats: {
        vendorsOnboarded: 45,
        disputesResolved: 67,
        trainingSessionsConducted: 23,
        marketUtilizationRate: 78.5
      },
      responsibilities: [
        'Vendor Onboarding',
        'Stall Management',
        'Training Coordination',
        'Performance Monitoring',
        'Dispute Resolution'
      ]
    }
  }
];

// Seed users function
const seedUsersData = async () => {
  try {
    console.log('🌱 Starting user seeding process...');
    
    // Check if users already exist
    const existingUsers = await User.find({});
    if (existingUsers.length > 0) {
      console.log(`⚠️  Found ${existingUsers.length} existing users in database`);
      console.log('📧 Existing user emails:');
      existingUsers.forEach(user => {
        console.log(`   - ${user.email} (${user.role})`);
      });
      
      // Ask to proceed (in a real scenario, you might want to skip or update)
      console.log('⏳ Proceeding with seeding (will skip existing emails)...\n');
    }
    
    const results = [];
    let createdCount = 0;
    let skippedCount = 0;
    let errorCount = 0;
    
    console.log('👥 Creating seed users:');
    console.log('=======================');
    
    for (const userData of seedUsers) {
      try {
        // Check if user with this email already exists
        const existingUser = await User.findOne({ email: userData.email });
        
        if (existingUser) {
          console.log(`⏭️  Skipped: ${userData.email} (${userData.role}) - User already exists`);
          skippedCount++;
          results.push({ 
            email: userData.email, 
            role: userData.role, 
            status: 'skipped', 
            reason: 'User already exists' 
          });
          continue;
        }
        
        // Create new user
        const newUser = new User(userData);
        const savedUser = await newUser.save();
        
        console.log(`✅ Created: ${savedUser.email} (${savedUser.role}) - ID: ${savedUser._id}`);
        createdCount++;
        results.push({ 
          email: savedUser.email, 
          role: savedUser.role, 
          status: 'created', 
          id: savedUser._id 
        });
        
      } catch (error) {
        console.error(`❌ Failed to create ${userData.email} (${userData.role}):`, error.message);
        errorCount++;
        results.push({ 
          email: userData.email, 
          role: userData.role, 
          status: 'failed', 
          error: error.message 
        });
      }
    }
    
    // Summary
    console.log('\n📊 User Seeding Summary:');
    console.log('========================');
    console.log(`✅ Users created: ${createdCount}`);
    console.log(`⏭️  Users skipped: ${skippedCount}`);
    console.log(`❌ Users failed: ${errorCount}`);
    console.log(`📈 Total processed: ${seedUsers.length}`);
    
    if (createdCount > 0) {
      console.log('\n🎉 Successfully created users:');
      results
        .filter(result => result.status === 'created')
        .forEach(result => {
          console.log(`   📧 ${result.email} (${result.role})`);
        });
    }
    
    if (errorCount > 0) {
      console.log('\n⚠️  Failed users:');
      results
        .filter(result => result.status === 'failed')
        .forEach(result => {
          console.log(`   ❌ ${result.email} (${result.role}): ${result.error}`);
        });
    }
    
    // Display login credentials
    if (createdCount > 0 || skippedCount > 0) {
      console.log('\n🔐 Login Credentials:');
      console.log('====================');
      seedUsers.forEach(user => {
        console.log(`📧 ${user.email}`);
        console.log(`🔑 Password: ${user.password}`);
        console.log(`👤 Role: ${user.role}`);
        console.log(`📱 Phone: ${user.phone}`);
        console.log('---');
      });
    }
    
    return results;
    
  } catch (error) {
    console.error('💥 Fatal error during user seeding:', error.message);
    throw error;
  }
};

// Verify seeded users
const verifySeededUsers = async () => {
  try {
    console.log('\n🔍 Verifying seeded users...');
    
    const allUsers = await User.find({}).select('name email role isVerified ecoPoints createdAt');
    
    if (allUsers.length === 0) {
      console.log('📭 No users found in database');
      return;
    }
    
    console.log(`📊 Total users in database: ${allUsers.length}`);
    
    // Group by role
    const usersByRole = allUsers.reduce((acc, user) => {
      if (!acc[user.role]) {
        acc[user.role] = [];
      }
      acc[user.role].push(user);
      return acc;
    }, {});
    
    console.log('\n👥 Users by Role:');
    console.log('================');
    
    Object.keys(usersByRole).forEach(role => {
      console.log(`\n🏷️  ${role.toUpperCase()} (${usersByRole[role].length} users):`);
      usersByRole[role].forEach(user => {
        const verifyStatus = user.isVerified ? '✅' : '⏳';
        console.log(`   ${verifyStatus} ${user.name} (${user.email}) - ${user.ecoPoints} eco points`);
      });
    });
    
  } catch (error) {
    console.error('❌ Error verifying users:', error.message);
  }
};

// Main execution
const main = async () => {
  try {
    // Connect to database
    await connectDB();
    
    console.log('🎯 Fresh Marikiti User Seeding Script');
    console.log('=====================================');
    console.log(`📅 Date: ${new Date().toISOString()}`);
    console.log(`🗄️  Database: ${process.env.MONGODB_URI || 'mongodb://localhost:27017/fresh_marikiti'}`);
    console.log(`👥 Users to seed: ${seedUsers.length}\n`);
    
    // Seed users
    await seedUsersData();
    
    // Verify seeded users
    await verifySeededUsers();
    
    console.log('\n🎉 User seeding completed successfully!');
    
  } catch (error) {
    console.error('🚨 Script failed:', error.message);
    process.exit(1);
  } finally {
    // Close database connection
    try {
      await mongoose.connection.close();
      console.log('\n🔌 Database connection closed');
    } catch (error) {
      console.error('Error closing database connection:', error.message);
    }
    
    console.log('👋 Script completed');
    process.exit(0);
  }
};

// Handle process termination
process.on('SIGINT', async () => {
  console.log('\n⚠️  Process interrupted by user');
  try {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  } catch (error) {
    console.error('Error closing database connection:', error.message);
  }
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n⚠️  Process terminated');
  try {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  } catch (error) {
    console.error('Error closing database connection:', error.message);
  }
  process.exit(0);
});

// Run the script
main(); 