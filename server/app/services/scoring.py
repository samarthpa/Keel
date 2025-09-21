"""
Scoring Service

Service for scoring and recommending credit cards based on merchant
information and user preferences.
"""

import json
import os
from typing import Dict, Any, List, Optional
from app.stores.redis_store import RedisStore
from app.settings import settings


# Load rewards data from rewards.json at import time
def _load_rewards_data() -> Dict[str, Any]:
    """
    Load rewards configuration from rewards.json file.

    This function loads the rewards data at module import time to ensure
    the data is available for all scoring operations. The rewards.json
    file contains card information, category mappings, and scoring rules.

    Returns:
        Dict[str, Any]: Rewards configuration data

    Raises:
        FileNotFoundError: If rewards.json is not found
        json.JSONDecodeError: If rewards.json is malformed
    """
    try:
        # Get the path to rewards.json relative to the server directory
        current_dir = os.path.dirname(os.path.abspath(__file__))
        server_dir = os.path.dirname(os.path.dirname(current_dir))
        rewards_path = os.path.join(server_dir, "rewards.json")

        with open(rewards_path, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        raise FileNotFoundError(
            "rewards.json file not found. Please ensure it exists in the server directory."
        )
    except json.JSONDecodeError as e:
        raise json.JSONDecodeError(f"Invalid JSON in rewards.json: {e}")


# Load rewards data at import time
REWARDS_DATA = _load_rewards_data()


class CardRecommendation:
    """
    Model for credit card recommendation.
    """

    def __init__(self, card: str, score: float, reason: str, benefits: List[str]):
        self.card = card
        self.score = score
        self.reason = reason
        self.benefits = benefits


class ScoringService:
    """
    Service for credit card scoring and recommendations.

    Analyzes merchant information and user preferences to provide
    personalized credit card recommendations.

    Note: This service currently uses hardcoded rules-based scoring.
    Future versions will transition to machine learning-based scoring
    for more sophisticated and personalized recommendations.
    """

    def __init__(self, redis_store: RedisStore):
        """
        Initialize the scoring service.

        Args:
            redis_store: Redis store for caching and data access
        """
        self.redis_store = redis_store
        self.card_database = self._load_card_database()

    def score(
        self, category: Optional[str] = None, cards: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """
        Score credit cards based on merchant category using rewards.json data.

        This function implements a rules-based scoring system that can be
        easily extended and eventually replaced with machine learning models.
        The scoring algorithm considers category-specific multipliers and
        base rewards to calculate optimal card recommendations.

        Args:
            category: Merchant category (e.g., "dining", "grocery", "gas")
            cards: List of card names to score (if None, uses all available cards)

        Returns:
            Dict[str, Any]: Scoring results with top 3 cards and metadata

        Example:
            >>> score("dining", ["Amex Gold", "Chase Freedom"])
            {
                "top": [
                    {"card": "Amex Gold", "score": 0.95, "reason": "5x points on dining"},
                    {"card": "Chase Freedom", "score": 0.87, "reason": "3x points on dining"}
                ],
                "used_rules_version": "1.0"
            }

        Note: This function is designed to be easily replaced with ML-based
        scoring in the future. The input/output format will remain the same,
        but the scoring logic will be replaced with trained models.
        """
        # Normalize category to lowercase for consistent matching
        normalized_category = category.lower() if category else None
        
        # Map categories that don't exist in rewards.json to similar categories
        category_mapping = {
            'wellness': 'everything_else',  # Wellness services fall back to general rewards
            'fitness': 'everything_else',   # Fitness services fall back to general rewards
            'healthcare': 'everything_else', # Healthcare services fall back to general rewards
            'retail': 'everything_else',    # General retail falls back to general rewards
            'department store': 'everything_else', # Department stores fall back to general rewards
            'entertainment': 'everything_else', # Entertainment falls back to general rewards
            'financial': 'everything_else', # Financial services fall back to general rewards
            'automotive': 'everything_else', # Automotive falls back to general rewards
            'pet care': 'everything_else',  # Pet care falls back to general rewards
            'general': 'everything_else',   # General category falls back to general rewards
        }
        
        # Apply category mapping if needed
        if normalized_category in category_mapping:
            normalized_category = category_mapping[normalized_category]

        # Use provided cards or all available cards from rewards data
        if cards is None:
            cards = list(REWARDS_DATA.get("cards", {}).keys())

        # Score each card
        scored_cards = []
        for card_name in cards:
            card_data = REWARDS_DATA.get("cards", {}).get(card_name)
            if not card_data:
                continue

            # Calculate score based on category and card rewards
            score = self._calculate_score_from_rewards(card_data, normalized_category)

            # Generate reason for the score
            reason = self._generate_score_reason(card_data, normalized_category, score)

            scored_cards.append({"card": card_name, "score": score, "reason": reason})

        # Sort by score (highest first) and take top 3
        scored_cards.sort(key=lambda x: x["score"], reverse=True)
        top_cards = scored_cards[:3]

        return {
            "top": top_cards,
            "used_rules_version": getattr(settings, "REWARDS_VERSION", "1.0"),
        }

    def _calculate_score_from_rewards(
        self, card_data: Dict[str, Any], category: Optional[str]
    ) -> float:
        """
        Calculate card score based on rewards data and category.

        This method implements the core scoring algorithm using the rewards
        configuration. It considers base rewards and category-specific
        multipliers to determine the optimal card for a given merchant category.

        Args:
            card_data: Card information from rewards.json
            category: Normalized merchant category

        Returns:
            float: Calculated score (0.0 to 1.0)
        """
        rewards = card_data.get("rewards", {})

        # Start with base score (everything_else multiplier)
        base_score = rewards.get("everything_else", 1) / 5.0  # Normalize to 0-1 scale

        # If category is provided, apply category-specific multiplier
        if category and category in rewards:
            category_multiplier = rewards[category]
            # Normalize category multiplier to 0-1 scale (assuming max is 5x)
            category_score = category_multiplier / 5.0
            # Weight category score higher than base score
            final_score = (category_score * 0.8) + (base_score * 0.2)
        else:
            # No category match, use base score
            final_score = base_score

        # No annual fee penalty - user already has the card and has decided to pay the fee
        # Scoring is based purely on rewards value since the card is already in their wallet

        # Ensure score is between 0 and 1
        return max(0.0, min(1.0, final_score))

    def _generate_score_reason(
        self, card_data: Dict[str, Any], category: Optional[str], score: float
    ) -> str:
        """
        Generate a human-readable reason for the card score.

        Args:
            card_data: Card information from rewards.json
            category: Normalized merchant category
            score: Calculated score

        Returns:
            str: Human-readable reason for the score
        """
        card_data.get("name", "Unknown Card")
        rewards = card_data.get("rewards", {})

        if category and category in rewards:
            multiplier = rewards[category]
            return f"{multiplier}x points on {category} purchases"
        else:
            base_multiplier = rewards.get("everything_else", 1)
            return f"{base_multiplier}x points on all purchases"

    def score_cards(
        self,
        merchant: str,
        mcc: Optional[str] = None,
        category: Optional[str] = None,
        cards: List[str] = None,
        user_preferences: Optional[Dict[str, Any]] = None,
    ) -> List[CardRecommendation]:
        """
        Score and rank credit cards for a given merchant.

        Args:
            merchant: Merchant name
            mcc: Merchant Category Code
            category: Merchant category
            cards: List of cards to score
            user_preferences: User preferences and constraints

        Returns:
            List[CardRecommendation]: Ranked card recommendations
        """
        # TODO: Implement card scoring algorithm
        # This will analyze merchant/category and match with card benefits
        # to provide personalized recommendations

        if cards is None:
            cards = self._get_default_cards()

        recommendations = []

        for card in cards:
            score = self._calculate_card_score(
                card, merchant, mcc, category, user_preferences
            )

            if score > 0:
                recommendation = CardRecommendation(
                    card=card,
                    score=score,
                    reason=self._get_recommendation_reason(card, category),
                    benefits=self._get_card_benefits(card),
                )
                recommendations.append(recommendation)

        # Sort by score (highest first)
        recommendations.sort(key=lambda x: x.score, reverse=True)

        return recommendations

    def _calculate_card_score(
        self,
        card: str,
        merchant: str,
        mcc: Optional[str],
        category: Optional[str],
        user_preferences: Optional[Dict[str, Any]],
    ) -> float:
        """
        Calculate score for a specific card.

        Args:
            card: Card name
            merchant: Merchant name
            mcc: Merchant Category Code
            category: Merchant category
            user_preferences: User preferences

        Returns:
            float: Card score (0.0 to 1.0)
        """
        # TODO: Implement scoring algorithm
        # This will consider:
        # - Category match (e.g., dining card for restaurants)
        # - MCC code matching
        # - User preferences (annual fees, credit score, etc.)
        # - Card benefits and rewards rates

        base_score = 0.5

        # Category matching
        if category and self._category_matches_card(card, category):
            base_score += 0.3

        # MCC matching
        if mcc and self._mcc_matches_card(card, mcc):
            base_score += 0.2

        # User preference matching
        if user_preferences:
            base_score += self._calculate_preference_score(card, user_preferences)

        return min(1.0, max(0.0, base_score))

    def _category_matches_card(self, card: str, category: str) -> bool:
        """
        Check if card benefits match the merchant category.

        Args:
            card: Card name
            category: Merchant category

        Returns:
            bool: True if category matches card benefits
        """
        # TODO: Implement category matching logic
        # This will check if the card has benefits for the given category

        category_matches = {
            "Amex Gold": ["Dining", "Travel"],
            "Chase Freedom": ["Retail", "Dining"],
            "Citi Custom Cash": ["Dining", "Gas", "Travel"],
            "Chase Sapphire": ["Dining", "Travel"],
            "Amex Platinum": ["Travel", "Dining"],
        }

        return category in category_matches.get(card, [])

    def _mcc_matches_card(self, card: str, mcc: str) -> bool:
        """
        Check if card benefits match the MCC code.

        Args:
            card: Card name
            mcc: Merchant Category Code

        Returns:
            bool: True if MCC matches card benefits
        """
        # TODO: Implement MCC matching logic
        # This will check if the card has benefits for the given MCC

        mcc_matches = {
            "Amex Gold": ["5812", "5813", "5814"],  # Dining
            "Chase Freedom": ["5411", "5812"],  # Grocery, Dining
            "Citi Custom Cash": ["5541", "5812"],  # Gas, Dining
            "Chase Sapphire": ["5812", "7011"],  # Dining, Travel
            "Amex Platinum": ["7011", "5812"],  # Travel, Dining
        }

        return mcc in mcc_matches.get(card, [])

    def _calculate_preference_score(
        self, card: str, user_preferences: Dict[str, Any]
    ) -> float:
        """
        Calculate score based on user preferences.

        Args:
            card: Card name
            user_preferences: User preferences and constraints

        Returns:
            float: Preference score adjustment
        """
        # TODO: Implement preference scoring
        # This will consider:
        # - Annual fee tolerance
        # - Credit score requirements
        # - Preferred reward types (cashback vs points)
        # - Travel vs everyday spending preferences

        score_adjustment = 0.0

        # Annual fee preference
        if user_preferences.get("prefer_no_annual_fee", False):
            if self._has_annual_fee(card):
                score_adjustment -= 0.2

        # Credit score preference
        if user_preferences.get("credit_score"):
            if not self._meets_credit_requirements(
                card, user_preferences["credit_score"]
            ):
                score_adjustment -= 0.3

        return score_adjustment

    def _get_recommendation_reason(self, card: str, category: Optional[str]) -> str:
        """
        Get the reason for recommending a specific card.

        Args:
            card: Card name
            category: Merchant category

        Returns:
            str: Recommendation reason
        """
        # TODO: Implement reason generation
        # This will provide personalized reasons for recommendations

        reasons = {
            "Amex Gold": "5x points on dining and 3x on flights",
            "Chase Freedom": "5% cashback on rotating categories",
            "Citi Custom Cash": "5% cashback on top spending category",
            "Chase Sapphire": "3x points on dining and travel",
            "Amex Platinum": "5x points on flights and premium travel benefits",
        }

        return reasons.get(card, "Good rewards for this category")

    def _get_card_benefits(self, card: str) -> List[str]:
        """
        Get list of benefits for a specific card.

        Args:
            card: Card name

        Returns:
            List[str]: List of card benefits
        """
        # TODO: Implement benefit retrieval
        # This will return the key benefits of each card

        benefits = {
            "Amex Gold": [
                "5x points on dining",
                "3x points on flights",
                "$120 dining credit",
                "No foreign transaction fees",
            ],
            "Chase Freedom": [
                "5% cashback on rotating categories",
                "1% cashback on everything else",
                "No annual fee",
                "0% APR for 15 months",
            ],
            "Citi Custom Cash": [
                "5% cashback on top spending category",
                "1% cashback on everything else",
                "No annual fee",
                "0% APR for 15 months",
            ],
        }

        return benefits.get(card, ["Standard rewards"])

    def _get_default_cards(self) -> List[str]:
        """
        Get default list of cards to consider.

        Returns:
            List[str]: Default card list
        """
        return [
            "Amex Gold",
            "Chase Freedom",
            "Citi Custom Cash",
            "Chase Sapphire",
            "Amex Platinum",
        ]

    def _load_card_database(self) -> Dict[str, Any]:
        """
        Load card database from storage.

        Returns:
            Dict[str, Any]: Card database
        """
        # TODO: Implement card database loading
        # This will load card information from database or cache

        return {"cards": self._get_default_cards(), "last_updated": "2024-01-01"}

    def _has_annual_fee(self, card: str) -> bool:
        """
        Check if card has an annual fee.

        Args:
            card: Card name

        Returns:
            bool: True if card has annual fee
        """
        annual_fee_cards = ["Amex Gold", "Amex Platinum", "Chase Sapphire"]
        return card in annual_fee_cards

    def _meets_credit_requirements(self, card: str, credit_score: int) -> bool:
        """
        Check if user meets credit requirements for card.

        Args:
            card: Card name
            credit_score: User's credit score

        Returns:
            bool: True if user meets requirements
        """
        # TODO: Implement credit requirement checking
        # This will check if the user's credit score meets the card's requirements

        requirements = {
            "Amex Gold": 700,
            "Chase Freedom": 650,
            "Citi Custom Cash": 650,
            "Chase Sapphire": 720,
            "Amex Platinum": 750,
        }

        required_score = requirements.get(card, 650)
        return credit_score >= required_score
