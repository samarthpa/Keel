"""
Event Processing Routes

API endpoints for processing location events and visits.
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from typing import Dict, Any, Optional, List
from app.services.places_client import PlacesClient
from app.services.openai_client import OpenAIClient
from app.stores.redis_store import RedisStore
from app.settings import settings


class VisitEvent(BaseModel):
    """
    Model for visit events from mobile app.
    """

    # This model accepts arbitrary JSON, so we don't define specific fields
    pass


class VisitResponse(BaseModel):
    """
    Response model for visit event processing.
    """

    status: str  # "accepted" or "duplicate"


class MockVisitRequest(BaseModel):
    """
    Request model for simulating a visit to a location.
    """
    lat: float
    lon: float
    user_id: Optional[str] = None
    user_cards: Optional[List[str]] = None  # List of user's active cards


class MockVisitResponse(BaseModel):
    """
    Response model for mock visit simulation.
    """
    merchant: str
    category: Optional[str] = None
    mcc: Optional[str] = None
    confidence: float
    top_card: Optional[str] = None
    reason: Optional[str] = None
    request_id: str


router = APIRouter()


@router.post("/v1/events/visit", response_model=VisitResponse)
async def process_visit_event(
    request: Request, event_body: Dict[str, Any], redis_store: RedisStore = Depends()
) -> VisitResponse:
    """
    Process visit events from the mobile app with idempotency support.

    Args:
        request: FastAPI request object to access headers
        event_body: Arbitrary JSON event body
        redis_store: Redis store for idempotency handling

    Returns:
        VisitResponse: Processing status (accepted or duplicate)

    Raises:
        HTTPException: If event processing fails
    """
    try:
        # Read Idempotency-Key header (kebab-case)
        idempotency_key = request.headers.get("Idempotency-Key")

        if not idempotency_key:
            raise HTTPException(
                status_code=400,
                detail={
                    "error": {
                        "code": "MISSING_IDEMPOTENCY_KEY",
                        "message": "Idempotency-Key header is required",
                        "retryable": False,
                    }
                },
            )

        # Use Redis store to set idempotency key
        # If key already exists, this will return False (duplicate)
        is_new = await redis_store.set_idempotency(idempotency_key)

        if is_new:
            # Process the event (first time)
            # TODO: Implement actual event processing logic here
            # For now, we just acknowledge receipt
            return VisitResponse(status="accepted")
        else:
            # Event already processed (duplicate)
            return VisitResponse(status="duplicate")

    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "error": {
                    "code": "EVENT_PROCESSING_ERROR",
                    "message": f"Failed to process event: {str(e)}",
                    "retryable": True,
                }
            },
        )


@router.post("/v1/mock/visit", response_model=MockVisitResponse)
async def mock_visit(
    request: MockVisitRequest,
    places_client: PlacesClient = Depends(),
    redis_store: RedisStore = Depends()
) -> MockVisitResponse:
    """
    Simulate a visit to a real location using Google Places API.
    
    This endpoint:
    1. Uses Google Places API to find nearby businesses
    2. Resolves merchant information (name, category, MCC)
    3. Scores credit cards for the merchant
    4. Returns recommendations
    
    Args:
        request: MockVisitRequest with coordinates
        places_client: Places API client dependency
        redis_store: Redis store dependency
        
    Returns:
        MockVisitResponse: Complete visit simulation with recommendations
        
    Raises:
        HTTPException: If visit simulation fails
    """
    try:
        # Step 1: Find nearby places using Google Places API
        nearby_places = await places_client.nearby(request.lat, request.lon)
        print(nearby_places)
        if not nearby_places:
            raise HTTPException(
                status_code=404,
                detail={
                    "error": {
                        "code": "NO_MERCHANTS_FOUND",
                        "message": "No merchants found at the specified location",
                        "retryable": False,
                    }
                }
            )
        
        # Step 2: Get the top place (closest to coordinates)
        top_place = nearby_places[0]
        merchant_name = top_place.get("name", "Unknown Merchant")
        
        # Step 3: Map place types to MCC and category
        place_types = top_place.get("types", [])
        mcc, category = places_client.map_types_to_mcc_category(place_types)
        
        # Step 4: Calculate confidence
        confidence = 0.8 if mcc else settings.min_confidence
        
        # Step 5: Generate a request ID for tracking
        import uuid
        request_id = str(uuid.uuid4())
        
        # Step 6: Use GPT to analyze location metadata and recommend optimal card
        top_card = None
        reason = None
        
        try:
            openai_client = OpenAIClient()
            
            # Prepare location metadata for GPT analysis
            location_metadata = {
                "merchant_name": merchant_name,
                "category": category,
                "mcc": mcc,
                "place_types": place_types,
                "user_cards": request.user_cards or [],
                "coordinates": {"lat": request.lat, "lon": request.lon}
            }
            
            print(location_metadata)
            
            # Get GPT recommendation based on location metadata
            gpt_response = await openai_client.analyze_location_and_recommend_card(location_metadata)
            print(gpt_response)
            
            if gpt_response and "recommended_card" in gpt_response:
                top_card = gpt_response["recommended_card"]
                reason = gpt_response.get("explanation", f"Optimal card for {merchant_name}")
            else:
                # Fallback if GPT doesn't return expected format
                top_card = "No specific recommendation"
                reason = f"Unable to determine optimal card for {merchant_name}"
                
        except Exception as e:
            # Fallback if GPT fails
            print(f"GPT analysis failed: {e}")
            top_card = "No specific recommendation"
            reason = f"Unable to analyze location for optimal card recommendation"
        
        return MockVisitResponse(
            merchant=merchant_name,
            category=category,
            mcc=mcc,
            confidence=confidence,
            top_card=top_card,
            reason=reason,
            request_id=request_id
        )
        
    except HTTPException:
        # Re-raise HTTP exceptions
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "error": {
                    "code": "VISIT_SIMULATION_FAILED",
                    "message": f"Failed to simulate visit: {str(e)}",
                    "retryable": True,
                }
            }
        )


@router.get("/analytics")
async def get_event_analytics() -> Dict[str, Any]:
    """
    Get analytics on processed events.

    Returns:
        Dict[str, Any]: Event analytics data
    """
    try:
        # TODO: Implement analytics retrieval
        return {
            "total_events": 1000,
            "events_today": 50,
            "top_merchants": [
                {"merchant": "Starbucks", "visits": 25},
                {"merchant": "Target", "visits": 20},
                {"merchant": "Whole Foods", "visits": 15},
            ],
            "card_recommendations": {
                "total_given": 500,
                "most_recommended": "Amex Gold",
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
