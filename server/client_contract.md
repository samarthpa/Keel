# Keel API Client Contract

## Base URLs

| Environment | Base URL |
|-------------|----------|
| Development | `http://localhost:8000` |
| Staging | `https://staging-api.keel.com` |
| Production | `https://api.keel.com` |

## Endpoints

### Merchant Resolution
**GET** `/v1/merchant/resolve`

**Query Parameters:**
- `lat` (float, required): Latitude coordinate
- `lon` (float, required): Longitude coordinate

**Response:**
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

**Request Body:**
```json
{
  "merchant": "Starbucks",        // optional
  "mcc": "5814",                  // optional
  "category": "dining",           // optional
  "cards": ["Amex Gold", "Chase Freedom"]  // optional
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

### Configuration
**GET** `/v1/config`

**Response:**
```json
{
  "rewards_version": "1.0",
  "model_version": "1.0",
  "min_confidence": 0.5,
  "radius": 100
}
```

### Event Processing
**POST** `/v1/events/visit`

**Headers:**
```
Idempotency-Key: unique-event-id-123
Content-Type: application/json
```

**Request Body:**
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

## Error Model

All error responses follow this structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "retryable": true
  }
}
```

**Common Error Codes:**
- `NO_MERCHANTS_FOUND`: No merchants at location (404)
- `INVALID_COORDINATES`: Invalid lat/lon values (400)
- `MISSING_IDEMPOTENCY_KEY`: Required header missing (400)
- `INTERNAL_ERROR`: Server error (502)
- `API_UNAVAILABLE`: External API failure (503)

## Timeouts & Retry Behavior

### Client Timeouts
- **Request Timeout**: 1.5 seconds
- **Connection Timeout**: 2.0 seconds

### Retry Strategy
- **Backoff**: Exponential backoff starting at 0.5s
- **Max Retries**: 3 attempts
- **Retryable Errors**: Only retry if `error.retryable: true`

### Implementation Example
```swift
// Retry with exponential backoff
func retryRequest<T>(_ request: () async throws -> T) async throws -> T {
    var delay: TimeInterval = 0.5
    
    for attempt in 1...3 {
        do {
            return try await request()
        } catch let error as APIError where error.retryable {
            if attempt == 3 { throw error }
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= 2
        } catch {
            throw error
        }
    }
    
    fatalError("Should not reach here")
}
```

## Fallback Behavior

### Merchant Resolution Fallback
If merchant resolution fails (404) or confidence is below `min_confidence`:

1. **Extract Category**: Use Google Places API directly to get category
2. **Category-Level Recommendation**: Call `/v1/score` with category only
3. **Display**: Show "Recommended for [category] purchases"

### Implementation Flow
```swift
func getRecommendations(lat: Double, lon: Double) async throws -> CardRecommendations {
    do {
        // Try merchant resolution first
        let merchant = try await resolveMerchant(lat: lat, lon: lon)
        
        if merchant.confidence >= minConfidence {
            // Use merchant-specific scoring
            return try await scoreCards(
                merchant: merchant.name,
                mcc: merchant.mcc,
                category: merchant.category
            )
        }
    } catch {
        // Fall back to category-level recommendation
    }
    
    // Fallback: category-only scoring
    let category = await getCategoryFromGooglePlaces(lat: lat, lon: lon)
    return try await scoreCards(category: category)
}
```

## Request Headers

### Required Headers
```
Content-Type: application/json
User-Agent: Keel-iOS/1.0.0
```

### Optional Headers
```
Idempotency-Key: unique-event-id-123  // Required for /v1/events/visit
X-Request-ID: trace-id-123            // For debugging
```

## Response Headers

### Standard Headers
```
Content-Type: application/json
X-Request-ID: trace-id-123
```

### Rate Limiting
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## Data Types

### Coordinates
- **Latitude**: -90.0 to 90.0
- **Longitude**: -180.0 to 180.0
- **Precision**: 6 decimal places

### Confidence Scores
- **Range**: 0.0 to 1.0
- **Threshold**: Use `min_confidence` from config

### Card Scores
- **Range**: 0.0 to 1.0
- **Sorting**: Descending (highest first)

## Versioning

- **API Version**: v1 (in URL path)
- **Rules Version**: Returned in scoring responses
- **Backward Compatibility**: v1 endpoints will maintain compatibility
- **Deprecation**: 6-month notice for breaking changes

## Security

### HTTPS Required
- **Development**: HTTP allowed for localhost
- **Staging/Production**: HTTPS required
- **Certificate**: Valid SSL certificate required

### API Keys
- **Client**: No API key required
- **Server**: Internal API keys for external services

## Monitoring

### Health Checks
- **Endpoint**: `GET /health`
- **Frequency**: Every 30 seconds
- **Timeout**: 1 second

### Metrics
- **Response Times**: Track p95, p99
- **Error Rates**: Monitor 4xx, 5xx responses
- **Success Rates**: Track successful resolutions
