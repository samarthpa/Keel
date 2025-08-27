# Keel Server

FastAPI server for merchant resolution and card scoring.

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env and add your Google Places API key
```

3. Get a Google Places API key:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the Places API
   - Create credentials (API key)
   - Add the key to your `.env` file

4. Run the server:
```bash
uvicorn main:app --reload --port 8000
```

The server will be available at `http://127.0.0.1:8000`

## API Endpoints

- `GET /health` - Health check
- `GET /merchant/resolve?lat={lat}&lon={lon}` - Resolve merchant from coordinates
- `POST /score` - Score credit cards for a merchant

## Environment Variables

- `GOOGLE_PLACES_API_KEY` - Your Google Places API key (required)
