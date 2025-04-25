#!/bin/bash

# Exit on any error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31mPlease run as root\e[0m"
  exit 1
fi

# Colors and formatting
BLUE="\e[34m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BOLD="\e[1m"
UNDERLINE="\e[4m"
RESET="\e[0m"

# Sample airports from around the world
SAMPLE_AIRPORTS=(
  "KJFK:John F. Kennedy International Airport (New York, USA)"
  "EGLL:Heathrow Airport (London, UK)"
  "RJTT:Tokyo Haneda Airport (Tokyo, Japan)"
  "YSSY:Sydney Airport (Sydney, Australia)"
  "FACT:Cape Town International Airport (Cape Town, South Africa)"
  "SBGR:São Paulo–Guarulhos International Airport (São Paulo, Brazil)"
  "LTBA:Istanbul Atatürk Airport (Istanbul, Turkey)"
  "OMDB:Dubai International Airport (Dubai, UAE)"
  "VIDP:Indira Gandhi International Airport (Delhi, India)"
  "ZBAA:Beijing Capital International Airport (Beijing, China)"
)

# Introduction
display_intro() {
  clear
  echo -e "${BLUE}${BOLD}======================================================${RESET}"
  echo -e "${BLUE}${BOLD}          TELEMETRY HARBOR AIRPORT WEATHER           ${RESET}"
  echo -e "${BLUE}${BOLD}======================================================${RESET}"
  echo ""
  echo -e "This script will set up a service that collects weather data"
  echo -e "from selected airports and sends it to your Telemetry Harbor endpoint."
  echo ""
  echo -e "${YELLOW}The Airport Weather Collector will:${RESET}"
  echo -e "  • Run as a systemd service that starts automatically on boot"
  echo -e "  • Collect temperature, pressure, and wind speed from your selected airports"
  echo -e "  • Send data to your Telemetry Harbor endpoint in batch format"
  echo -e "  • Each metric will be sent as a separate cargo with the airport name as the ship_id"
  echo ""
}

# Check if service is already installed
check_installation() {
  if [ -f "/etc/systemd/system/harbor-airport.service" ] || [ -f "/usr/local/bin/harbor-airport.sh" ]; then
    echo -e "${YELLOW}Airport Weather Collector is already installed on this system.${RESET}"
    echo ""
    echo -e "What would you like to do?"
    echo -e "  ${BOLD}1.${RESET} Reinstall Airport Weather Collector"
    echo -e "  ${BOLD}2.${RESET} Exit"
    
    read -p "Enter your choice (1-2): " REINSTALL_CHOICE
    
    if [ "$REINSTALL_CHOICE" = "1" ]; then
      uninstall "quiet"
      echo -e "${GREEN}Previous installation removed. Proceeding with new installation...${RESET}"
      echo ""
    else
      echo -e "${YELLOW}Installation cancelled.${RESET}"
      exit 0
    fi
  fi
}

# Uninstall function
uninstall() {
  if [ "$1" != "quiet" ]; then
    echo -e "${YELLOW}Uninstalling Airport Weather Collector...${RESET}"
  fi
  
  # Stop and disable the service
  systemctl stop harbor-airport.service 2>/dev/null || true
  systemctl disable harbor-airport.service 2>/dev/null || true
  
  # Remove service file
  rm -f /etc/systemd/system/harbor-airport.service
  
  # Remove script
  rm -f /usr/local/bin/harbor-airport.sh
  
  # Reload systemd
  systemctl daemon-reload
  
  if [ "$1" != "quiet" ]; then
    echo -e "${GREEN}Airport Weather Collector has been uninstalled.${RESET}"
    exit 0
  fi
}

# Check for uninstall argument
if [ "$1" = "--uninstall" ]; then
  uninstall
fi

# Main menu function
main_menu() {
  display_intro
  
  echo -e "${BLUE}${BOLD}What would you like to do?${RESET}"
  echo -e "  ${BOLD}1.${RESET} Install Airport Weather Collector"
  echo -e "  ${BOLD}2.${RESET} Uninstall Airport Weather Collector"
  echo -e "  ${BOLD}3.${RESET} Exit"
  echo ""
  
  read -p "Enter your choice (1-3): " MAIN_CHOICE
  
  case $MAIN_CHOICE in
    1)
      # Check if already installed
      check_installation
      install_collector
      ;;
    2)
      uninstall
      ;;
    3)
      echo -e "${YELLOW}Exiting...${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid choice. Exiting.${RESET}"
      exit 1
      ;;
  esac
}

# Install function
install_collector() {
  clear
  display_intro
  
  # API endpoint configuration
  echo -e "${BLUE}${BOLD}API Configuration:${RESET}"
  read -p "Enter telemetry batch API endpoint URL: " API_ENDPOINT
  read -p "Enter API key: " API_KEY
  
  # Airport configuration
  echo ""
  echo -e "${BLUE}${BOLD}Airport Configuration:${RESET}"
  echo -e "${YELLOW}Enter airport codes and names (ICAO code and full name).${RESET}"
  echo -e "Example: KJFK:John F. Kennedy International Airport"
  echo -e ""
  echo -e "${BLUE}${BOLD}Sample airports from around the world:${RESET}"
  for i in "${!SAMPLE_AIRPORTS[@]}"; do
    echo -e "  ${BOLD}$((i+1)).${RESET} ${SAMPLE_AIRPORTS[$i]}"
  done
  echo -e ""
  echo -e "Enter 'done' when finished adding airports."
  
  declare -a AIRPORT_CODES=()
  declare -a AIRPORT_NAMES=()
  
  while true; do
    read -p "Airport (or 'done'): " AIRPORT_INPUT
    
    if [ "$AIRPORT_INPUT" = "done" ]; then
      # If no airports added, ask again
      if [ ${#AIRPORT_CODES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No airports added. Please add at least one airport.${RESET}"
        continue
      else
        break
      fi
    fi
    
    # Check if input is a number referring to a sample airport
    if [[ "$AIRPORT_INPUT" =~ ^[0-9]+$ ]] && [ "$AIRPORT_INPUT" -ge 1 ] && [ "$AIRPORT_INPUT" -le "${#SAMPLE_AIRPORTS[@]}" ]; then
      # Get the sample airport
      AIRPORT_INPUT="${SAMPLE_AIRPORTS[$((AIRPORT_INPUT-1))]}"
    fi
    
    # Split input by colon
    IFS=':' read -r CODE NAME <<< "$AIRPORT_INPUT"
    
    # Validate input
    if [ -z "$CODE" ] || [ -z "$NAME" ]; then
      echo -e "${RED}Invalid format. Please use CODE:NAME format.${RESET}"
      continue
    fi
    
    # Add to arrays
    AIRPORT_CODES+=("$CODE")
    AIRPORT_NAMES+=("$NAME")
    
    echo -e "${GREEN}Added: $CODE - $NAME${RESET}"
  done
  
  # Sampling rate configuration
  echo ""
  echo -e "${BLUE}${BOLD}Select sampling rate:${RESET}"
  echo -e "  ${BOLD}1.${RESET} Every 1 minute"
  echo -e "  ${BOLD}2.${RESET} Every 5 minutes"
  echo -e "  ${BOLD}3.${RESET} Every 15 minutes"
  echo -e "  ${BOLD}4.${RESET} Every 30 minutes"
  echo -e "  ${BOLD}5.${RESET} Every 1 hour"
  read -p "Enter your choice (1-5): " RATE_CHOICE
  
  case $RATE_CHOICE in
    1) SAMPLING_RATE=60 ;;
    2) SAMPLING_RATE=300 ;;
    3) SAMPLING_RATE=900 ;;
    4) SAMPLING_RATE=1800 ;;
    5) SAMPLING_RATE=3600 ;;
    *) 
      echo -e "${YELLOW}Invalid choice. Defaulting to 5 minutes.${RESET}"
      SAMPLING_RATE=300
      ;;
  esac
  
  echo -e "${YELLOW}Creating weather collection script...${RESET}"
  
  # Create the weather collection script
cat > /usr/local/bin/harbor-airport.sh << 'EOF'
#!/bin/bash

# Configuration will be injected here
API_ENDPOINT="__API_ENDPOINT__"
API_KEY="__API_KEY__"
SAMPLING_RATE=__SAMPLING_RATE__

# Define airport codes with their official names
declare -A AIRPORT_NAMES
__AIRPORT_MAPPINGS__

# Array of airport codes
AIRPORT_CODES=(__AIRPORT_CODES__)

# Function to extract weather data and push to Telemetry Harbor
push_weather_data() {
  local api_url="$API_ENDPOINT"
  local api_key="$API_KEY"
  local metric_names=("Temperature" "Pressure" "WindSpeed")

  for code in "${AIRPORT_CODES[@]}"; do
    local name="${AIRPORT_NAMES[$code]}"
    
    # Fetch the weather data for the airport
    local raw=$(curl -s "https://aviationweather.gov/api/data/metar?ids=$code&format=raw")
    echo "[$(date)] Fetching data for $name ($code)..."

    # Parse weather values with improved patterns
    local datetime_utc=$(echo "$raw" | grep -oP '\d{6}Z' | head -1)
    local temp=$(echo "$raw" | grep -oP '\s\d{2}/\d{2}\s' | head -1 | tr -d ' ' | cut -d'/' -f1)
    local pressure=$(echo "$raw" | grep -oP 'Q\d{4}' | head -1 | cut -d'Q' -f2)
    local wind_speed=$(echo "$raw" | grep -oP '\d{2}KT' | head -1 | cut -d'K' -f1)

    # Set defaults if values are missing
    [ -z "$temp" ] && temp="00"
    [ -z "$pressure" ] && pressure="1000"
    [ -z "$wind_speed" ] && wind_speed="00"

    # Get current date in ISO format
    local now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

    # Prepare the metrics as an array of JSON objects - USE OFFICIAL AIRPORT NAME
    local data="[ \
      {\"time\": \"$now\", \"ship_id\": \"$name\", \"cargo_id\": \"Temperature\", \"value\": \"$temp\"}, \
      {\"time\": \"$now\", \"ship_id\": \"$name\", \"cargo_id\": \"Pressure\", \"value\": \"$pressure\"}, \
      {\"time\": \"$now\", \"ship_id\": \"$name\", \"cargo_id\": \"WindSpeed\", \"value\": \"$wind_speed\"} \
    ]"

    # Print the payload (for debugging purposes)
    echo "Payload to send:"
    echo "$data"

    # Send batch request to Telemetry Harbor
    response=$(curl -s -X POST "$api_url" -H "X-API-Key: $api_key" -H "Content-Type: application/json" -d "$data")

    # Check response from Telemetry Harbor
    if [[ $response == *"status_code"* && $response == *"500"* ]]; then
      echo "[$(date)] ERROR: Failed to send data for $name. Response: $response"
    else
      echo "[$(date)] Successfully sent data for $name"
    fi
  done

  # Sleep for the configured interval before sending the next batch
  echo "[$(date)] Done. Sleeping for $(($SAMPLING_RATE/60)) min..."
  sleep $SAMPLING_RATE
}

# Function to test API connectivity
test_api_connection() {
  echo "Testing API connectivity..."
  
  # Get first airport for test
  local code="${AIRPORT_CODES[0]}"
  local name="${AIRPORT_NAMES[$code]}"
  
  # Create test JSON payload
  local now=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
  local test_data="[{\"time\": \"$now\", \"ship_id\": \"$name\", \"cargo_id\": \"Test\", \"value\": \"1\"}]"
  
  # Send test request
  local response=$(curl -s -w "\n%{http_code}" -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "$test_data")
  
  # Extract HTTP status code
  local status_code=$(echo "$response" | tail -n1)
  local response_body=$(echo "$response" | head -n -1)
  
  if [ "$status_code" = "200" ]; then
    echo "API connection successful!"
    return 0
  else
    echo "API connection failed with status code: $status_code"
    echo "Response: $response_body"
    return 1
  fi
}

# Check for command line arguments
if [ "$1" = "test" ]; then
  test_api_connection
  exit $?
fi

# Main loop to push weather data at the configured interval
while true; do
  push_weather_data
done
EOF

  # Replace placeholders with actual values
  sed -i "s|__API_ENDPOINT__|$API_ENDPOINT|g" /usr/local/bin/harbor-airport.sh
  sed -i "s|__API_KEY__|$API_KEY|g" /usr/local/bin/harbor-airport.sh
  sed -i "s|__SAMPLING_RATE__|$SAMPLING_RATE|g" /usr/local/bin/harbor-airport.sh
  
  # Create airport mappings
  AIRPORT_MAPPINGS=""
  for i in "${!AIRPORT_CODES[@]}"; do
    AIRPORT_MAPPINGS+="AIRPORT_NAMES[\"${AIRPORT_CODES[$i]}\"]=\"${AIRPORT_NAMES[$i]}\"\n"
  done
  
  # Replace airport mappings placeholder
  sed -i "s|__AIRPORT_MAPPINGS__|$AIRPORT_MAPPINGS|g" /usr/local/bin/harbor-airport.sh
  
  # Create airport codes array
  AIRPORT_CODES_STR=$(printf "\"%s\" " "${AIRPORT_CODES[@]}")
  sed -i "s|__AIRPORT_CODES__|$AIRPORT_CODES_STR|g" /usr/local/bin/harbor-airport.sh
  
  # Make the script executable
  chmod +x /usr/local/bin/harbor-airport.sh
  
  # Create systemd service file
  cat > /etc/systemd/system/harbor-airport.service << EOF
[Unit]
Description=Telemetry Harbor Airport Weather Collector
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/harbor-airport.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  # Test API connectivity
  echo -e "${YELLOW}Testing API connectivity...${RESET}"
  /usr/local/bin/harbor-airport.sh test
  
  # Check the return code from the test function
  TEST_RESULT=$?
  if [ $TEST_RESULT -ne 0 ]; then
    echo -e "${RED}API connectivity test failed. Please check your API endpoint and key.${RESET}"
    echo -e "${YELLOW}The service will not be started.${RESET}"
    exit 1
  fi
  
  # Enable and start the service
  systemctl daemon-reload
  systemctl enable harbor-airport.service
  systemctl start harbor-airport.service
  
  echo ""
  echo -e "${GREEN}${BOLD}=== Installation Complete ===${RESET}"
  echo -e "${GREEN}Airport Weather Collector has been installed and started.${RESET}"
  echo -e "${YELLOW}Monitoring the following airports:${RESET}"
  for i in "${!AIRPORT_CODES[@]}"; do
    echo -e "  - ${AIRPORT_CODES[$i]}: ${AIRPORT_NAMES[$i]}"
  done
  echo -e "${YELLOW}Sampling rate:${RESET} Every $(($SAMPLING_RATE/60)) minutes"
  echo ""
  echo -e "${BLUE}To check service status:${RESET} systemctl status harbor-airport"
  echo -e "${BLUE}To view logs:${RESET} journalctl -u harbor-airport -f"
  echo -e "${BLUE}To manage the service:${RESET} Run this script again and select from the menu"
}

# Run the main menu
main_menu
