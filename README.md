# Telemetry Harbor Airport Weather Collector

Collect real-time weather data from airports worldwide and send it to Telemetry Harbor for visualization and analysis.

## Overview

This tool fetches temperature, pressure, and wind speed data from selected airports using aviation weather services and sends it to your Telemetry Harbor endpoint. It runs as a systemd service that automatically starts on boot.

## Features

- Collect weather data from multiple airports worldwide
- Extract temperature, pressure, and wind speed from aviation weather reports
- Send data to Telemetry Harbor in batch format
- Configurable sampling rate (1 minute to 1 hour)
- Interactive installation with sample airports from around the world
- Runs as a systemd service for reliability

## Requirements

- Linux system with systemd
- Root access
- curl
- Internet connection to access aviation weather API
- Telemetry Harbor account with API key

## Quick Start

1. Download the installation script:
   ```bash
   curl -sSL -o install.sh https://raw.githubusercontent.com/TelemetryHarbor/harbor-airport-weather/main/install.sh
   ```

2. Make it executable:
   ```bash
   chmod +x install.sh
   ```

3. Run the installation script as root:
   ```bash
   sudo ./install.sh
   ```

4. Follow the prompts to configure:
   - Telemetry Harbor API endpoint
   - API key
   - Airport codes and names
   - Sampling rate

## Usage

The collector runs automatically as a systemd service. You can manage it using standard systemd commands:


# Check status
```bash
sudo systemctl status harbor-airport
```
# View logs
```bash
sudo journalctl -u harbor-airport -f
```
# Stop the service
```bash
sudo systemctl stop harbor-airport
```
# Start the service
```bash
sudo systemctl start harbor-airport
```
# Restart the service
```bash
sudo systemctl restart harbor-airport
```

## Uninstallation

To uninstall the collector, run:

```bash
sudo ./install.sh --uninstall
```
## Data Format

The collector sends the following metrics for each airport:

- **Temperature**: Temperature in degrees Celsius
- **Pressure**: Atmospheric pressure in hectopascals (hPa)
- **WindSpeed**: Wind speed in knots

Each metric is sent as a separate cargo with the airport name as the ship_id.

## Sample Airports

The installation includes sample airports from around the world:

- KJFK: John F. Kennedy International Airport (New York, USA)
- EGLL: Heathrow Airport (London, UK)
- RJTT: Tokyo Haneda Airport (Tokyo, Japan)
- YSSY: Sydney Airport (Sydney, Australia)
- FACT: Cape Town International Airport (Cape Town, South Africa)
- SBGR: São Paulo–Guarulhos International Airport (São Paulo, Brazil)
- LTBA: Istanbul Atatürk Airport (Istanbul, Turkey)
- OMDB: Dubai International Airport (Dubai, UAE)
- VIDP: Indira Gandhi International Airport (Delhi, India)
- ZBAA: Beijing Capital International Airport (Beijing, China)

## Troubleshooting

If you encounter issues:

1. Check the logs: `sudo journalctl -u harbor-airport -f`
2. Verify your API endpoint and key are correct
3. Ensure the system has internet access
4. Check that the weather data is available for your selected airports

## License

[MIT License](LICENSE)
\`\`\`

Now, here's the documentation file for the website:
