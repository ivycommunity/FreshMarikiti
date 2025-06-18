# Fresh Marikiti Configuration Guide

This guide helps you configure the Fresh Marikiti Flutter app to work with both Android emulator and physical devices.

## Quick Setup

### Option 1: Automatic Configuration (Recommended)
```bash
./scripts/switch_device_config.sh auto
```

This will auto-detect your local IP and let you choose between emulator and physical device.

### Option 2: Manual Configuration

#### For Android Emulator:
```bash
./scripts/switch_device_config.sh emulator
```

#### For Physical Device:
```bash
./scripts/switch_device_config.sh device 192.168.1.100
```
Replace `192.168.1.100` with your computer's actual IP address.

## Finding Your Computer's IP Address

### Linux/macOS:
```bash
# Method 1
hostname -I

# Method 2  
ip route get 1.1.1.1 | grep -oP 'src \K\S+'

# Method 3
ifconfig | grep 'inet ' | grep -v '127.0.0.1'
```

### Windows:
```cmd
ipconfig | findstr IPv4
```

## Configuration Details

### Current Configuration Status:
```bash
./scripts/switch_device_config.sh status
```

### Test Connection:
```bash
./scripts/switch_device_config.sh test
```

## Environment Variables

The app uses these key environment variables:

| Variable | Purpose | Emulator Value | Physical Device Example |
|----------|---------|----------------|------------------------|
| `API_BASE_URL` | Backend API endpoint | `http://10.0.2.2:5000/api` | `http://192.168.1.100:5000/api` |
| `WS_BASE_URL` | WebSocket endpoint | `ws://10.0.2.2:5000` | `ws://192.168.1.100:5000` |
| `API_TIMEOUT` | Request timeout | `30000` | `30000` |
| `MAX_RETRIES` | Retry attempts | `3` | `3` |
| `ENABLE_LOGGING` | Debug logging | `true` | `true` |

## Troubleshooting

### Common Issues:

1. **"Connection refused" error:**
   - Make sure the Fresh Marikiti backend is running
   - Check the IP address is correct
   - Verify firewall isn't blocking the connection

2. **Emulator can't connect:**
   - Use `10.0.2.2` instead of `localhost` or `127.0.0.1`
   - Make sure the backend is running on your host machine

3. **Physical device can't connect:**
   - Both device and computer must be on the same WiFi network
   - Use your computer's local IP address (not localhost)
   - Check if firewall is blocking port 5000

### Testing Backend Connection:

```bash
# Test if backend is accessible
curl http://10.0.2.2:5000/api/health  # For emulator
curl http://192.168.1.100:5000/api/health  # For physical device
```

## Development Workflow

1. **Start Backend Server:**
   ```bash
   cd fresh-marikiti-backend
   npm run dev
   ```

2. **Configure Flutter App:**
   ```bash
   cd fresh_marikiti
   ./scripts/switch_device_config.sh auto
   ```

3. **Run Flutter App:**
   ```bash
   flutter run
   ```

## Advanced Configuration

### Manual .env Configuration:

You can manually edit the `.env` file if needed:

```env
# For Android Emulator
API_BASE_URL=http://10.0.2.2:5000/api
WS_BASE_URL=ws://10.0.2.2:5000

# For Physical Device (replace with your IP)
# API_BASE_URL=http://192.168.1.100:5000/api
# WS_BASE_URL=ws://192.168.1.100:5000

APP_NAME=Fresh Marikiti
APP_VERSION=1.0.0
ENVIRONMENT=development
DEBUG_MODE=true
API_TIMEOUT=30000
MAX_RETRIES=3
ENABLE_LOGGING=true
```

### Dynamic Configuration:

The `AuthService` automatically detects the platform and uses appropriate URLs:
- Android Emulator: `10.0.2.2:5000`
- iOS Simulator: `localhost:5000`
- Fallback: Uses `.env` configuration

## Production Configuration

For production builds, update these variables:

```env
ENVIRONMENT=production
DEBUG_MODE=false
ENABLE_LOGGING=false
API_BASE_URL=https://your-production-api.com/api
WS_BASE_URL=wss://your-production-api.com
```

## Need Help?

If you encounter issues:

1. Check the configuration status: `./scripts/switch_device_config.sh status`
2. Test the connection: `./scripts/switch_device_config.sh test`
3. Verify backend is running: `curl http://your-ip:5000/api/health`
4. Check Flutter logs for detailed error messages

---

**Note:** Always ensure your backend server is running before testing the Flutter app! 