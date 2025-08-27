# Keel - Location-Based Credit Card Recommendations

Keel is an iOS app that provides personalized credit card recommendations based on your location. When you visit merchants, the app analyzes your location, resolves the merchant information, and suggests the best credit card to use for maximum rewards.

## Features

- **Location-Based Recommendations**: Get card suggestions when you arrive at merchants
- **Confidence Scoring**: Smart algorithm that considers dwell time, visit history, and time of day
- **Real-Time Notifications**: Instant alerts with card recommendations
- **Visit History**: Track your location visits and recommendations in Core Data
- **Google Places Integration**: Accurate merchant resolution using Google Places API

## Prerequisites

### iOS App Setup

1. **Location Permissions**: The app requires both "When In Use" and "Always" location permissions
2. **Background Modes**: Enable "Location Updates" in Xcode Signing & Capabilities
3. **iOS Deployment Target**: iOS 17.0 or later

### Server Requirements

- Python 3.8+
- Google Places API key
- FastAPI and dependencies (see server/requirements.txt)

## Quick Start

### 1. Server Setup

```bash
cd server
pip install -r requirements.txt
cp .env.example .env
# Edit .env and add your Google Places API key
uvicorn main:app --reload --port 8000
```

The server will be available at `http://127.0.0.1:8000`

### 2. Environment Variables

Create a `.env` file in the `server` directory with:

```bash
GOOGLE_PLACES_API_KEY=your_google_places_api_key_here
```

**Getting a Google Places API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the Places API
3. Create credentials (API key)
4. Add the key to your `.env` file

### 3. iOS Configuration

Update the API endpoint in `ApiClient.swift`:

```swift
struct ApiConfig {
    static var baseURL = URL(string: "http://127.0.0.1:8000")! // For simulator
    // For physical device, use your computer's LAN IP:
    // static var baseURL = URL(string: "http://192.168.1.100:8000")!
}
```

### 4. Running the App

1. Open `Keel.xcodeproj` in Xcode
2. Build and run on device or simulator
3. Grant location permissions when prompted
4. Tap "Request Permissions" to start location monitoring

## Basic Workflow

1. **Start the server** (see Server Setup above)
2. **Run the app** on your device or simulator
3. **Walk around** or use the provided GPX files for testing
4. **See notifications** when you arrive at merchants
5. **Check the app** for visit history and card recommendations

## Testing with GPX Files

Use the provided GPX files in the `gpx/` folder to simulate location visits:

- **home_to_cafe.gpx**: Journey to Starbucks (dining merchant)
- **cafe_to_grocery.gpx**: Journey to Whole Foods (grocery merchant)

See `gpx/README.md` for detailed testing instructions.

## Project Structure

```
Keel/
├── Keel/                    # iOS app source code
│   ├── Keel/               # Main app files
│   ├── KeelTests/          # Unit tests
│   └── Visits.xcdatamodeld # Core Data model
├── server/                 # FastAPI backend
│   ├── main.py            # API endpoints
│   ├── rewards.json       # Card reward structures
│   └── requirements.txt   # Python dependencies
├── gpx/                   # Location testing files
└── README.md             # This file
```

## API Endpoints

- `GET /health` - Health check
- `GET /merchant/resolve?lat={lat}&lon={lon}` - Resolve merchant from coordinates
- `POST /score` - Score credit cards for a merchant

## Card Recommendations

The app currently supports these cards with their reward structures:

- **Amex Gold**: 4x dining, 4x grocery, 1x base
- **Chase Freedom**: 5x rotating categories, 1x base  
- **Citi Custom Cash**: 5x dining, 5x gas, 1x base

## Confidence Scoring

The app uses a confidence scoring algorithm that considers:

- **Prior Visits**: More visits to a location increase confidence
- **Dwell Time**: Longer stays increase confidence
- **Distance**: Closer proximity increases confidence
- **Time of Day**: Meal times get bonus points for dining categories

Only visits with confidence ≥ 0.6 trigger merchant resolution and card recommendations.

## Troubleshooting

### Common Issues

1. **No visits detected**: Check location permissions and background modes
2. **API errors**: Verify server is running and Google Places API key is valid
3. **No recommendations**: Check confidence scores and dwell time
4. **Network errors**: Ensure device can reach the server (check IP address)

### Debug Tips

- Check the console for error messages
- Verify location permissions in Settings
- Test with GPX files in the simulator
- Check server logs for API call details

## Development

### Running Tests

```bash
# iOS tests
# Run in Xcode: Product > Test

# Server tests (if added)
cd server
python -m pytest
```

### Adding New Cards

1. Update `server/rewards.json` with new card reward structure
2. Add card to the cards array in `LocationManager.swift`
3. Test with different merchant categories

## License

This project is for educational and development purposes.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request
