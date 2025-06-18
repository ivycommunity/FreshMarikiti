const mongoose = require('mongoose');
const dotenv = require('dotenv');

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

// Clear all collections
const clearDatabase = async () => {
  try {
    console.log('🗑️  Starting database cleanup...');
    
    // Get all collections in the database
    const collections = await mongoose.connection.db.listCollections().toArray();
    
    if (collections.length === 0) {
      console.log('📭 Database is already empty - no collections found');
      return;
    }
    
    console.log(`📦 Found ${collections.length} collections to clear:`);
    collections.forEach(collection => {
      console.log(`   - ${collection.name}`);
    });
    
    // Clear each collection
    const clearPromises = collections.map(async (collection) => {
      const collectionName = collection.name;
      try {
        const result = await mongoose.connection.db.collection(collectionName).deleteMany({});
        console.log(`✅ Cleared collection '${collectionName}' - Deleted ${result.deletedCount} documents`);
        return { collection: collectionName, deleted: result.deletedCount, success: true };
      } catch (error) {
        console.error(`❌ Error clearing collection '${collectionName}':`, error.message);
        return { collection: collectionName, deleted: 0, success: false, error: error.message };
      }
    });
    
    const results = await Promise.all(clearPromises);
    
    // Summary
    console.log('\n📊 Database Cleanup Summary:');
    console.log('================================');
    
    let totalDeleted = 0;
    let successCount = 0;
    let errorCount = 0;
    
    results.forEach(result => {
      if (result.success) {
        totalDeleted += result.deleted;
        successCount++;
        console.log(`✅ ${result.collection}: ${result.deleted} documents deleted`);
      } else {
        errorCount++;
        console.log(`❌ ${result.collection}: Failed - ${result.error}`);
      }
    });
    
    console.log('================================');
    console.log(`📈 Total documents deleted: ${totalDeleted}`);
    console.log(`✅ Successful collections: ${successCount}`);
    console.log(`❌ Failed collections: ${errorCount}`);
    
    if (errorCount === 0) {
      console.log('🎉 Database cleared successfully!');
    } else {
      console.log('⚠️  Database cleared with some errors - check logs above');
    }
    
  } catch (error) {
    console.error('💥 Fatal error during database cleanup:', error.message);
    throw error;
  }
};

// Main execution
const main = async () => {
  try {
    // Connect to database
    await connectDB();
    
    // Confirm before clearing (safety check)
    console.log('⚠️  WARNING: This will DELETE ALL DATA in the database!');
    console.log(`🎯 Target Database: ${process.env.MONGODB_URI || 'mongodb://localhost:27017/fresh_marikiti'}`);
    console.log('⏳ Starting cleanup in 3 seconds...\n');
    
    // Wait 3 seconds to allow user to cancel if needed
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    // Clear the database
    await clearDatabase();
    
  } catch (error) {
    console.error('🚨 Script failed:', error.message);
    process.exit(1);
  } finally {
    // Close database connection
    try {
      await mongoose.connection.close();
      console.log('🔌 Database connection closed');
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