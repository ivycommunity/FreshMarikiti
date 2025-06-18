#!/bin/bash

# Fresh Marikiti Device Configuration Switcher
# This script helps switch between emulator and physical device configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_ENV_FILE="$PROJECT_DIR/.env"
BACKEND_ENV_FILE="$(dirname "$PROJECT_DIR")/fresh-marikiti-backend/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Fresh Marikiti Device Config Switcher${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [emulator|device] [ip_address]"
    echo ""
    echo "Commands:"
    echo "  emulator    - Configure for Android emulator (10.0.2.2)"
    echo "  device      - Configure for physical device (requires IP)"
    echo "  auto        - Auto-detect and configure"
    echo "  status      - Show current configuration"
    echo "  test        - Test connection to configured backend"
    echo ""
    echo "Examples:"
    echo "  $0 emulator"
    echo "  $0 device 192.168.1.100"
    echo "  $0 auto"
    echo "  $0 status"
}

get_local_ip() {
    # Try different methods to get local IP
    local ip=""
    
    # Method 1: Use hostname -I (Linux)
    if command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' | head -1)
    fi
    
    # Method 2: Use ip command (Linux)
    if [[ -z "$ip" ]] && command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    fi
    
    # Method 3: Use ifconfig (macOS/Linux)
    if [[ -z "$ip" ]] && command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1)
    fi
    
    echo "$ip"
}

# Function to safely update or add environment variable
update_env_var() {
    local env_file="$1"
    local key="$2"
    local value="$3"
    
    if [[ ! -f "$env_file" ]]; then
        echo -e "${YELLOW}Creating new $env_file${NC}"
        touch "$env_file"
    fi
    
    # Check if key exists
    if grep -q "^$key=" "$env_file"; then
        # Update existing key
        sed -i "s|^$key=.*|$key=$value|" "$env_file"
    else
        # Add new key
        echo "$key=$value" >> "$env_file"
    fi
}

configure_frontend_emulator() {
    echo -e "${YELLOW}Configuring frontend for emulator...${NC}"
    
    update_env_var "$FRONTEND_ENV_FILE" "DEVICE_TYPE" "emulator"
    update_env_var "$FRONTEND_ENV_FILE" "API_BASE_URL" "http://10.0.2.2:5000/api"
    update_env_var "$FRONTEND_ENV_FILE" "WS_BASE_URL" "ws://10.0.2.2:5000"
    
    # Remove DEVICE_IP for emulator
    if grep -q "^DEVICE_IP=" "$FRONTEND_ENV_FILE"; then
        sed -i '/^DEVICE_IP=/d' "$FRONTEND_ENV_FILE"
    fi
    
    echo -e "${GREEN}✓ Frontend configured for emulator${NC}"
}

configure_frontend_device() {
    local ip="$1"
    
    echo -e "${YELLOW}Configuring frontend for physical device ($ip)...${NC}"
    
    update_env_var "$FRONTEND_ENV_FILE" "DEVICE_TYPE" "physical"
    update_env_var "$FRONTEND_ENV_FILE" "API_BASE_URL" "http://$ip:5000/api"
    update_env_var "$FRONTEND_ENV_FILE" "WS_BASE_URL" "ws://$ip:5000"
    update_env_var "$FRONTEND_ENV_FILE" "DEVICE_IP" "$ip"
    
    echo -e "${GREEN}✓ Frontend configured for physical device${NC}"
}

configure_backend_emulator() {
    echo -e "${YELLOW}Configuring backend for emulator...${NC}"
    
    # Update M-Pesa callback URLs to use localhost
    update_env_var "$BACKEND_ENV_FILE" "MPESA_CALLBACK_URL" "http://localhost:5000/api/payments/mpesa/callback"
    update_env_var "$BACKEND_ENV_FILE" "MPESA_TIMEOUT_URL" "http://localhost:5000/api/payments/mpesa/timeout"
    update_env_var "$BACKEND_ENV_FILE" "MPESA_RESULT_URL" "http://localhost:5000/api/payments/mpesa/result"
    
    # Ensure server is accessible
    update_env_var "$BACKEND_ENV_FILE" "HOST" "0.0.0.0"
    update_env_var "$BACKEND_ENV_FILE" "CORS_ORIGIN" "*"
    
    echo -e "${GREEN}✓ Backend configured for emulator${NC}"
}

configure_backend_device() {
    local ip="$1"
    
    echo -e "${YELLOW}Configuring backend for physical device ($ip)...${NC}"
    
    # Update M-Pesa callback URLs to use device IP
    update_env_var "$BACKEND_ENV_FILE" "MPESA_CALLBACK_URL" "http://$ip:5000/api/payments/mpesa/callback"
    update_env_var "$BACKEND_ENV_FILE" "MPESA_TIMEOUT_URL" "http://$ip:5000/api/payments/mpesa/timeout"
    update_env_var "$BACKEND_ENV_FILE" "MPESA_RESULT_URL" "http://$ip:5000/api/payments/mpesa/result"
    
    # Ensure server is accessible from network
    update_env_var "$BACKEND_ENV_FILE" "HOST" "0.0.0.0"
    update_env_var "$BACKEND_ENV_FILE" "CORS_ORIGIN" "*"
    
    echo -e "${GREEN}✓ Backend configured for physical device${NC}"
}

configure_emulator() {
    echo -e "${BLUE}=== Configuring for Android Emulator ===${NC}"
    
    configure_frontend_emulator
    configure_backend_emulator
    
    echo ""
    echo -e "${GREEN}✓ Complete configuration for Android Emulator (10.0.2.2:5000)${NC}"
    echo -e "${BLUE}Note: Make sure your backend server is running on localhost:5000${NC}"
}

configure_device() {
    local ip="$1"
    
    if [[ -z "$ip" ]]; then
        echo -e "${RED}✗ IP address required for physical device configuration${NC}"
        echo "Please provide your computer's IP address:"
        echo "Example: $0 device 192.168.1.100"
        return 1
    fi
    
    # Validate IP format
    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}✗ Invalid IP address format: $ip${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Configuring for Physical Device ($ip) ===${NC}"
    
    configure_frontend_device "$ip"
    configure_backend_device "$ip"
    
    echo ""
    echo -e "${GREEN}✓ Complete configuration for Physical Device ($ip:5000)${NC}"
    echo -e "${BLUE}Note: Make sure your backend server is running and accessible from $ip:5000${NC}"
    echo -e "${BLUE}Also ensure your phone is connected to the same network${NC}"
}

auto_configure() {
    echo -e "${YELLOW}Auto-detecting configuration...${NC}"
    
    local local_ip=$(get_local_ip)
    
    if [[ -n "$local_ip" ]]; then
        echo -e "${BLUE}Detected local IP: $local_ip${NC}"
        echo "Choose configuration:"
        echo "1) Emulator (10.0.2.2) - for Android emulator"
        echo "2) Physical Device ($local_ip) - for real devices"
        echo -n "Enter choice (1 or 2): "
        read -r choice
        
        case $choice in
            1)
                configure_emulator
                ;;
            2)
                configure_device "$local_ip"
                ;;
            *)
                echo -e "${RED}✗ Invalid choice${NC}"
                return 1
                ;;
        esac
    else
        echo -e "${YELLOW}Could not detect local IP. Defaulting to emulator configuration.${NC}"
        configure_emulator
    fi
}

show_status() {
    echo -e "${YELLOW}Current Configuration:${NC}"
    echo ""
    
    # Frontend status
    echo -e "${BLUE}Frontend (.env):${NC}"
    if [[ -f "$FRONTEND_ENV_FILE" ]]; then
        local frontend_api_url=$(grep "^API_BASE_URL=" "$FRONTEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo "not set")
        local frontend_device_type=$(grep "^DEVICE_TYPE=" "$FRONTEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo "not set")
        local frontend_ws_url=$(grep "^WS_BASE_URL=" "$FRONTEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo "not set")
        
        echo "  Device Type: $frontend_device_type"
        echo "  API URL: $frontend_api_url"
        echo "  WebSocket URL: $frontend_ws_url"
        
        if [[ "$frontend_api_url" == *"10.0.2.2"* ]]; then
            echo -e "  ${GREEN}✓ Configured for Android Emulator${NC}"
        elif [[ "$frontend_api_url" == *"localhost"* ]]; then
            echo -e "  ${GREEN}✓ Configured for localhost${NC}"
        else
            echo -e "  ${GREEN}✓ Configured for Physical Device${NC}"
        fi
    else
        echo -e "  ${RED}✗ Frontend .env file not found${NC}"
    fi
    
    echo ""
    
    # Backend status
    echo -e "${BLUE}Backend (.env):${NC}"
    if [[ -f "$BACKEND_ENV_FILE" ]]; then
        local backend_host=$(grep "^HOST=" "$BACKEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo "not set")
        local backend_port=$(grep "^PORT=" "$BACKEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo "not set")
        local backend_cors=$(grep "^CORS_ORIGIN=" "$BACKEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2- || echo "not set")
        
        echo "  Host: $backend_host"
        echo "  Port: $backend_port"
        echo "  CORS Origin: $backend_cors"
        echo -e "  ${GREEN}✓ Backend configured${NC}"
    else
        echo -e "  ${RED}✗ Backend .env file not found${NC}"
    fi
}

test_connection() {
    if [[ ! -f "$FRONTEND_ENV_FILE" ]]; then
        echo -e "${RED}✗ No frontend .env file found${NC}"
        return 1
    fi
    
    local api_url=$(grep "^API_BASE_URL=" "$FRONTEND_ENV_FILE" 2>/dev/null | cut -d'=' -f2-)
    local base_url=$(echo "$api_url" | sed 's|/api$||')
    
    # Skip testing 10.0.2.2 from host system since it only works from inside emulator
    if [[ "$base_url" == *"10.0.2.2"* ]]; then
        echo -e "${BLUE}Skipping connection test for emulator endpoint (10.0.2.2)${NC}"
        echo -e "${YELLOW}Note: 10.0.2.2 only works from inside the Android emulator${NC}"
        echo -e "${GREEN}✓ Configuration complete - test from emulator app${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Testing connection to $base_url...${NC}"
    
    if command -v curl >/dev/null 2>&1; then
        echo "Attempting to connect..."
        if curl -s --connect-timeout 5 "$base_url/health" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Connection successful${NC}"
        elif curl -s --connect-timeout 5 "$base_url" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Server responding (health endpoint may not exist)${NC}"
        else
            echo -e "${RED}✗ Connection failed${NC}"
            echo "Make sure the Fresh Marikiti backend is running on $base_url"
            echo ""
            echo "To start the backend:"
            echo "  cd fresh-marikiti-backend"
            echo "  npm install"
            echo "  npm start"
        fi
    else
        echo -e "${YELLOW}curl not available - cannot test connection${NC}"
    fi
}

main() {
    print_header
    
    case "${1:-status}" in
        "emulator")
            configure_emulator
            test_connection
            ;;
        "device")
            configure_device "$2"
            test_connection
            ;;
        "auto")
            auto_configure
            test_connection
            ;;
        "status")
            show_status
            ;;
        "test")
            test_connection
            ;;
        "-h"|"--help"|"help")
            print_usage
            ;;
        *)
            echo -e "${RED}✗ Unknown command: $1${NC}"
            echo ""
            print_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 