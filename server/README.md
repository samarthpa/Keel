# Keel API Server

The Keel API Server is a FastAPI-based backend service that provides location-based merchant resolution and intelligent credit card recommendations. The API uses versioned endpoints (v1) and integrates with Google Places API for merchant identification and OpenAI for enhanced recommendations. The service includes Redis-based caching for idempotency and performance, with comprehensive health monitoring and structured logging.

## Quick Setup

### Prerequisites
- Python 3.9+
- Redis (for caching and idempotency)
- Google Places API key
- OpenAI API key (optional)

### Setup Steps

1. **Create virtual environment:**
```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

2. **Install dependencies:**
```bash
pip install -r requirements.txt
```

3. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your API keys and settings
```

4. **Start Redis:**
```bash
make up  # Starts Redis container
```

5. **Run the API:**
```bash
make dev  # Starts server on http://localhost:8000
```

## API Endpoints

### Health Check
**GET** `/health`

```json
{
  "ok": true,
  "env": "development"
}
```

### Configuration
**GET** `/v1/config`

```json
{
  "rewards_version": "1.0",
  "model_version": "1.0", 
  "min_confidence": 0.5,
  "radius": 100
}
```

### Merchant Resolution
**GET** `/v1/merchant/resolve?lat=37.7749&lon=-122.4194`

```json
{
  "merchant": "Starbucks",
  "mcc": "5814",
  "category": "dining",
  "confidence": 0.8
}
```

**Error Response (404):**
```json
{
  "error": {
    "code": "NO_MERCHANTS_FOUND",
    "message": "No merchants found at the specified location",
    "retryable": false
  }
}
```

### Credit Card Scoring
**POST** `/v1/score`

**Request:**
```json
{
  "category": "dining",
  "cards": ["Amex Gold", "Chase Freedom"]
}
```

**Response:**
```json
{
  "top": [
    {
      "card": "Amex Gold",
      "score": 0.63,
      "reason": "4x points on dining purchases"
    },
    {
      "card": "Chase Freedom", 
      "score": 0.52,
      "reason": "3x points on dining purchases"
    }
  ],
  "used_rules_version": "1.0"
}
```

### Event Processing
**POST** `/v1/events/visit`

**Headers:**
```
Idempotency-Key: unique-event-id-123
Content-Type: application/json
```

**Request:**
```json
{
  "lat": 37.7749,
  "lon": -122.4194,
  "timestamp": "2024-01-15T10:30:00Z",
  "user_id": "user123"
}
```

**Response:**
```json
{
  "status": "accepted"
}
```

**Duplicate Response:**
```json
{
  "status": "duplicate"
}
```

## HTTPS for iOS Development

iOS App Transport Security (ATS) requires HTTPS connections. Use one of these methods:

### ngrok (Recommended for Development)
```bash
# Install ngrok
brew install ngrok  # macOS
# or download from https://ngrok.com/

# Start your API
make dev

# In another terminal, expose via HTTPS
ngrok http 8000
```

### Cloudflare Tunnel
```bash
# Install cloudflared
brew install cloudflared

# Create tunnel
cloudflared tunnel create keel-api

# Configure tunnel
cloudflared tunnel route dns keel-api your-domain.com

# Start tunnel
cloudflared tunnel run keel-api
```

### Usage in iOS App
Replace `http://localhost:8000` with your HTTPS URL:
```swift
let baseURL = "https://your-ngrok-url.ngrok.io"
// or
let baseURL = "https://your-domain.com"
```

## Verification Checklist

Before connecting your iOS app, verify:

- [ ] **Server Running**: `curl http://localhost:8000/health` returns `{"ok": true}`
- [ ] **Redis Up**: `docker ps` shows Redis container running
- [ ] **API Keys Loaded**: Check logs for "Google Places API configured" message
- [ ] **HTTPS Working**: ngrok/Cloudflare tunnel provides HTTPS URL
- [ ] **Endpoints Responding**: Test each endpoint with sample requests
- [ ] **CORS Enabled**: API accepts requests from your iOS app

### Quick Health Check
```bash
# Test all endpoints
curl http://localhost:8000/health
curl http://localhost:8000/v1/config
curl "http://localhost:8000/v1/merchant/resolve?lat=37.7749&lon=-122.4194"
curl -X POST http://localhost:8000/v1/score \
  -H "Content-Type: application/json" \
  -d '{"category": "dining"}'
```

## Development

### Code Quality
```bash
make fmt    # Format code with ruff and black
make lint   # Run linting checks
make test   # Run tests
```

### Docker Commands
```bash
make up     # Start Redis and other services
make down   # Stop all services
```

### Database
```bash
make migrate        # Run migrations
make db-setup       # Setup database
```

## Configuration

Key environment variables in `.env`:
- `GOOGLE_PLACES_API_KEY`: Required for merchant resolution
- `OPENAI_API_KEY`: Optional for enhanced recommendations
- `REDIS_URL`: Redis connection (default: redis://localhost:6379)
- `DATABASE_URL`: PostgreSQL connection (optional)

## Architecture

```
app/
├── main.py              # FastAPI application
├── settings.py          # Configuration management
├── middleware/          # Request ID middleware
├── routes/              # API endpoints
│   ├── health.py        # Health checks
│   ├── config.py        # Configuration
│   ├── resolve.py       # Merchant resolution
│   ├── score.py         # Credit card scoring
│   └── events.py        # Event processing
├── services/            # Business logic
│   ├── places_client.py # Google Places API
│   ├── scoring.py       # Credit card scoring
│   └── openai_client.py # OpenAI integration
├── stores/              # Data storage
│   └── redis_store.py   # Redis caching
└── utils/               # Utilities
    ├── logging.py       # Structured logging
    └── errors.py        # Error handling
```

## Troubleshooting

### Common Issues

1. **Redis Connection Failed**
   - Ensure Redis is running: `make up`
   - Check Redis logs: `docker logs keel-server-redis-1`

2. **API Keys Not Working**
   - Verify keys in `.env` file
   - Check API key quotas and billing

3. **iOS Network Errors**
   - Ensure HTTPS is configured
   - Check CORS settings in API
   - Verify network permissions in iOS app

4. **Scoring Not Working**
   - Check `rewards.json` file format
   - Verify category names match between resolution and scoring

### Logs
```bash
# View API logs
make dev  # Shows logs in terminal

# View Redis logs
docker logs keel-server-redis-1
```
