# Telemetry Harbor Airport Weather Collector

Collect comprehensive real-time weather data from airports worldwide and send it to Telemetry Harbor for advanced visualization and analysis with Grafana dashboards.

## Overview

This tool fetches detailed weather telemetry from selected airports using aviation weather services and sends it to your Telemetry Harbor endpoint. It runs as a systemd service that automatically starts on boot and provides rich meteorological data for professional weather monitoring.

## Features

### 🌡️ Comprehensive Weather Data
- **Temperature**: Current temperature and "feels like" temperature (°F and °C)
- **Atmospheric Pressure**: Barometric pressure (hPa and inHg)
- **Wind Conditions**: Speed, gusts, and direction (mph, km/h, knots)
- **Humidity**: Relative humidity percentage
- **Visibility**: Atmospheric visibility (meters, km, miles)
- **UV Index**: Solar UV radiation levels
- **Air Quality**: PM2.5 and PM10 particulate matter (μg/m³)
- **Cloud Cover**: Cloud coverage percentage

### 🚀 Advanced Features
- **Multi-airport monitoring** with worldwide coverage
- **Configurable sampling rates** (1 minute to 1 hour)
- **Batch data transmission** for efficiency
- **Interactive installation** with curated airport samples
- **Systemd service integration** for reliability
- **Comprehensive error handling** and logging
- **Grafana dashboard ready** with pre-built visualizations

### 📊 Grafana Integration
- **Pre-built dashboard** with metric/imperial unit switching
- **Color-coded visualizations** with weather-appropriate thresholds
- **Real-time monitoring** with 30-second refresh
- **Multi-airport comparison** views
- **Historical trend analysis**
- **Weather alert capabilities**

## Requirements

- Linux system with systemd
- Root access for service installation
- curl and basic networking tools
- Internet connection for weather API access
- Telemetry Harbor account with API key

## Quick Start

### 1. Download and Install

```bash
# Download the installation script
curl -sSL -o install.sh https://raw.githubusercontent.com/TelemetryHarbor/harbor-airport-weather/main/install.sh

# Make it executable
chmod +x install.sh

# Run installation as root
sudo ./install.sh
```

### 2. Configuration

Follow the interactive prompts to configure:

- **Telemetry Harbor API endpoint**
- **OpenWeatherMapAPI authentication key**
- **Airport codes and display names**
- **Data sampling interval**

### 3. Grafana Dashboard Setup

```bash
# Import the pre-built dashboard
curl -sSL -o airport-weather-dashboard.json https://raw.githubusercontent.com/TelemetryHarbor/harbor-airport-weather/refs/heads/main/Airport_Weather_Dashboard.json

# Import into Grafana via UI or API
```

## Service Management

The collector runs as a systemd service with full lifecycle management:

```bash
# Check service status
sudo systemctl status harbor-airport

# View real-time logs
sudo journalctl -u harbor-airport -f

# Control service state
sudo systemctl start harbor-airport
sudo systemctl stop harbor-airport
sudo systemctl restart harbor-airport

# Enable/disable auto-start
sudo systemctl enable harbor-airport
sudo systemctl disable harbor-airport
```

## Data Schema

### Telemetry Metrics

Each airport sends the following cargo types:

| Cargo ID | Description | Units | Range |
|----------|-------------|-------|-------|
| `Temperature_Fahrenheit` | Current temperature | °F | -40 to 120 |
| `Feels_Like_F` | Apparent temperature | °F | -40 to 130 |
| `Humidity_Percent` | Relative humidity | % | 0 to 100 |
| `Pressure_hPa` | Barometric pressure | hPa | 950 to 1050 |
| `Wind_Speed_MPH` | Wind speed | mph | 0 to 200 |
| `Wind_Gust_MPH` | Wind gust speed | mph | 0 to 250 |
| `Wind_Direction_Degrees` | Wind direction | degrees | 0 to 360 |
| `UV_Index` | UV radiation level | index | 0 to 15 |
| `Visibility_Meters` | Atmospheric visibility | meters | 0 to 50000 |
| `Cloud_Cover_Percent` | Cloud coverage | % | 0 to 100 |
| `PM2_5_ugm3` | PM2.5 particles | μg/m³ | 0 to 500 |
| `PM10_ugm3` | PM10 particles | μg/m³ | 0 to 1000 |


## Sample Airports

The installation includes major airports from around the world:

### North America
- **KJFK**: John F. Kennedy International (New York, USA)
- **KLAX**: Los Angeles International (Los Angeles, USA)
- **CYYZ**: Toronto Pearson International (Toronto, Canada)

### Europe
- **EGLL**: Heathrow Airport (London, UK)
- **LFPG**: Charles de Gaulle Airport (Paris, France)
- **EDDF**: Frankfurt Airport (Frankfurt, Germany)

### Asia-Pacific
- **RJTT**: Tokyo Haneda Airport (Tokyo, Japan)
- **YSSY**: Sydney Airport (Sydney, Australia)
- **VHHH**: Hong Kong International Airport (Hong Kong)

### Middle East & Africa
- **OMDB**: Dubai International Airport (Dubai, UAE)
- **FACT**: Cape Town International Airport (Cape Town, South Africa)

### South America
- **SBGR**: São Paulo–Guarulhos International (São Paulo, Brazil)

## Grafana Dashboard Features

### 📊 Visualization Panels
- **Current Conditions Table**: Real-time weather summary
- **Temperature Trends**: Historical temperature and feels-like data
- **Atmospheric Pressure**: Barometric pressure monitoring
- **Wind Analysis**: Speed, gusts, and direction tracking
- **Air Quality Monitoring**: PM2.5 and PM10 levels
- **UV Index Tracking**: Solar radiation safety levels
- **Visibility Conditions**: Atmospheric clarity monitoring

### 🎛️ Interactive Controls
- **Airport Filter**: Multi-select airport monitoring
- **Time Range**: Flexible historical data viewing
- **Auto-refresh**: Real-time data updates

## Configuration Files

### Service Configuration
```bash
# Main service file
/etc/systemd/system/harbor-airport.service

# Configuration file
/etc/harbor-airport/config.conf

# Data collection script
/usr/local/bin/harbor-airport-collector.sh
```

### Log Files
```bash
# Service logs
sudo journalctl -u harbor-airport

# System logs
/var/log/harbor-airport/
```

## API Integration

### Weather Data Sources
- **Aviation Weather Center (AWC)**: Primary METAR data source
- **OpenWeatherMap API**: Enhanced meteorological data
- **AirNow API**: Air quality measurements
- **UV Index API**: Solar radiation data

## Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check service status
sudo systemctl status harbor-airport

# Check configuration
sudo cat /etc/harbor-airport/config.conf

# Verify permissions
sudo ls -la /usr/local/bin/harbor-airport-collector.sh
```

#### No Data in Dashboard
```bash
# Verify data collection
sudo journalctl -u harbor-airport -n 50

# Check database connectivity
psql -h localhost -U your_user -d your_database -c "SELECT COUNT(*) FROM cargo_data;"

# Test API endpoint
curl -X POST -H "Authorization: Bearer YOUR_API_KEY" YOUR_ENDPOINT/health
```

#### Weather Data Issues
```bash
# Test weather API access
curl "https://aviationweather.gov/adds/dataserver_current/httpparam?dataSource=metars&requestType=retrieve&format=xml&stationString=KJFK"

# Check internet connectivity
ping aviationweather.gov

# Verify airport codes
grep "AIRPORT_CODES" /etc/harbor-airport/config.conf
```


## Uninstallation

To completely remove the collector:

```bash
# Stop and disable service
sudo systemctl stop harbor-airport
sudo systemctl disable harbor-airport

# Remove service files
sudo rm /etc/systemd/system/harbor-airport.service
sudo rm -rf /etc/harbor-airport/
sudo rm /usr/local/bin/harbor-airport-collector.sh

# Reload systemd
sudo systemctl daemon-reload

# Optional: Remove logs
sudo rm -rf /var/log/harbor-airport/
```

## Contributing

We welcome contributions!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: [Wiki](https://github.com/TelemetryHarbor/harbor-airport-weather/wiki)
- **Issues**: [GitHub Issues](https://github.com/TelemetryHarbor/harbor-airport-weather/issues)
- **Discussions**: [GitHub Discussions](https://github.com/TelemetryHarbor/harbor-airport-weather/discussions)
- **Email**: support@telemetryharbor.com


