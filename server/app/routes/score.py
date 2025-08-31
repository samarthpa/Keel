"""
Credit Card Scoring Routes

API endpoints for scoring and recommending credit cards based on
merchant information and user preferences.
"""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from app.services.scoring import ScoringService
from app.stores.redis_store import RedisStore


class ScoreRequest(BaseModel):
    """
    Request model for credit card scoring.
    """

    merchant: Optional[str] = None
    mcc: Optional[str] = None
    category: Optional[str] = None
    cards: Optional[List[str]] = None


router = APIRouter()


@router.post("/v1/score")
async def score_cards(
    request: ScoreRequest, redis_store: RedisStore = Depends()
) -> Dict[str, Any]:
    """
    Score and recommend credit cards for a given merchant.

    Args:
        request: ScoreRequest containing merchant and card information
        redis_store: Redis store dependency

    Returns:
        Dict[str, Any]: Top card recommendations from scoring service

    Raises:
        HTTPException: If scoring fails
    """
    try:
        # Initialize scoring service with Redis store
        scoring_service = ScoringService(redis_store)

        # Call the scoring service with the request parameters
        result = scoring_service.score(category=request.category, cards=request.cards)

        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
