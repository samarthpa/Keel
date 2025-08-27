# uvicorn main:app --reload --port 8000

import os
import json
import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI()

# Load rewards data at startup
def load_rewards():
    try:
        with open("rewards.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print("Warning: rewards.json not found, using default rewards")
        return {}

REWARDS_DATA = load_rewards()

# Google Places API configuration
GOOGLE_PLACES_API_KEY = os.getenv("GOOGLE_PLACES_API_KEY")
GOOGLE_PLACES_BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

# MCC/Category mapping
PLACE_TYPE_TO_MCC = {
    "restaurant": ("5812", "dining"),
    "food": ("5812", "dining"),
    "cafe": ("5814", "dining"),
    "bakery": ("5814", "dining"),
    "grocery_or_supermarket": ("5411", "grocery"),
    "supermarket": ("5411", "grocery"),
    "gas_station": ("5541", "gas"),
    "pharmacy": ("5912", "pharmacy"),
    "hospital": ("8062", "healthcare"),
    "clothing_store": ("5651", "shopping"),
    "electronics_store": ("5732", "shopping"),
    "book_store": ("5942", "shopping"),
    "jewelry_store": ("5944", "shopping"),
    "shoe_store": ("5661", "shopping"),
    "furniture_store": ("5712", "shopping"),
    "home_goods_store": ("5719", "shopping"),
    "department_store": ("5311", "shopping"),
    "convenience_store": ("5411", "grocery"),
    "liquor_store": ("5921", "alcohol"),
    "bar": ("5813", "dining"),
    "night_club": ("5813", "dining"),
    "movie_theater": ("7832", "entertainment"),
    "gym": ("7991", "fitness"),
    "beauty_salon": ("7230", "beauty"),
    "car_repair": ("7538", "automotive"),
    "car_wash": ("7542", "automotive"),
    "bank": ("6011", "financial"),
    "atm": ("6011", "financial"),
    "post_office": ("5999", "services"),
    "laundry": ("7216", "services"),
    "hair_care": ("7230", "beauty"),
    "spa": ("7298", "beauty"),
}

# Request/Response models
class ScoreRequest(BaseModel):
    merchant: str
    mcc: Optional[str] = None
    category: Optional[str] = None
    cards: List[str]

class CardRec(BaseModel):
    card: str
    score: float
    reason: str

class ScoreResponse(BaseModel):
    top: List[CardRec]

@app.get("/health")
async def health():
    return {"ok": True}

@app.get("/merchant/resolve")
async def resolve_merchant(lat: float, lon: float):
    if not GOOGLE_PLACES_API_KEY:
        raise HTTPException(status_code=502, detail="Google Places API key not configured")
    
    try:
        # Google Places Nearby Search parameters
        params = {
            "location": f"{lat},{lon}",
            "radius": 100,  # 100m radius
            "rankby": "prominence",
            "type": "store|restaurant",
            "key": GOOGLE_PLACES_API_KEY
        }
        
        response = requests.get(GOOGLE_PLACES_BASE_URL, params=params)
        response.raise_for_status()
        
        data = response.json()
        
        if data.get("status") != "OK" or not data.get("results"):
            raise HTTPException(status_code=502, detail="No nearby places found")
        
        # Get the top result (most prominent)
        place = data["results"][0]
        place_name = place.get("name", "Unknown")
        place_types = place.get("types", [])
        
        # Find matching MCC/category from place types
        mcc = "5999"  # Default: Miscellaneous
        category = "other"
        
        for place_type in place_types:
            if place_type in PLACE_TYPE_TO_MCC:
                mcc, category = PLACE_TYPE_TO_MCC[place_type]
                break
        
        return {
            "merchant": place_name,
            "mcc": mcc,
            "category": category
        }
        
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Google Places API error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Merchant resolution error: {str(e)}")

@app.post("/score")
async def score_cards(request: ScoreRequest):
    card_scores = []
    
    for card in request.cards:
        # Get card rewards data
        card_rewards = REWARDS_DATA.get(card, {"base": 1.0, "categories": {}})
        
        # Calculate score based on merchant category
        if request.category and request.category in card_rewards.get("categories", {}):
            score = card_rewards["categories"][request.category]
            reason = f"{int(score)}x {request.category}"
        else:
            score = card_rewards.get("base", 1.0)
            reason = f"{int(score)}x base"
        
        card_scores.append(CardRec(
            card=card,
            score=score,
            reason=reason
        ))
    
    # Sort by score (highest first) and return top 3
    card_scores.sort(key=lambda x: x.score, reverse=True)
    top_3 = card_scores[:3]
    
    return ScoreResponse(top=top_3)
