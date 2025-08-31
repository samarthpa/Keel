"""
Merchant Resolution Routes

API endpoints for resolving merchant information from coordinates.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from app.services.places_client import PlacesClient
from app.settings import settings


class ResolveResponse(BaseModel):
    """
    Response model for merchant resolution.
    """

    merchant: str
    mcc: Optional[str] = None
    category: Optional[str] = None
    confidence: float


router = APIRouter()


@router.get("/v1/merchant/resolve", response_model=ResolveResponse)
async def resolve_merchant(
    lat: float, lon: float, places_client: PlacesClient = Depends()
) -> ResolveResponse:
    """
    Resolve merchant information from coordinates.

    Args:
        lat: Latitude coordinate
        lon: Longitude coordinate
        places_client: Places API client dependency

    Returns:
        ResolveResponse: Merchant information with confidence score

    Raises:
        HTTPException: If merchant resolution fails or no candidates found
    """
    try:
        # Call places client to find nearby places
        nearby_places = await places_client.nearby(lat, lon)

        if not nearby_places:
            # Return 404 with JSON error model if no candidates found
            raise HTTPException(
                status_code=404,
                detail={
                    "error": {
                        "code": "NO_MERCHANTS_FOUND",
                        "message": "No merchants found at the specified location",
                        "retryable": False,
                    }
                },
            )

        # Pick the top result (first in the list)
        top_place = nearby_places[0]

        # Map place types to MCC and category
        place_types = top_place.get("types", [])
        mcc, category = places_client.map_types_to_mcc_category(place_types)

        # Compute confidence: 0.8 if MCC found, else use settings.MIN_CONFIDENCE
        confidence = 0.8 if mcc else settings.min_confidence

        return ResolveResponse(
            merchant=top_place.get("name", "Unknown Merchant"),
            mcc=mcc,
            category=category,
            confidence=confidence,
        )
    except HTTPException:
        # Re-raise HTTP exceptions (like 404)
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
