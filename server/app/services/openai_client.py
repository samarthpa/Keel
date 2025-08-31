"""
OpenAI Client Service

Service for interacting with OpenAI API for AI-powered features
like card recommendation explanations and merchant analysis.
"""

import openai
from typing import Dict, Any, Optional, List
from app.settings import settings


class OpenAIClient:
    """
    Client for OpenAI API integration.

    Handles AI-powered features like generating card recommendation
    explanations and analyzing merchant data.
    """

    def __init__(self):
        """
        Initialize the OpenAI client.
        """
        self.api_key = settings.openai_api_key
        self.client = openai.OpenAI(api_key=self.api_key)

    async def generate_card_explanation(
        self, card_name: str, merchant: str, category: str, score: float
    ) -> str:
        """
        Generate a personalized explanation for a card recommendation.

        Args:
            card_name: Name of the credit card
            merchant: Merchant name
            category: Merchant category
            score: Recommendation score

        Returns:
            str: Generated explanation for the recommendation

        Raises:
            Exception: If API request fails
        """
        try:
            prompt = f"""
            Generate a brief, friendly explanation for why {card_name} is recommended 
            for shopping at {merchant} (category: {category}). 
            
            The recommendation score is {score:.2f}/1.0.
            
            Keep it under 100 words and focus on the specific benefits for this merchant.
            """

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a helpful credit card recommendation assistant. Provide clear, concise explanations.",
                    },
                    {"role": "user", "content": prompt},
                ],
                max_tokens=150,
                temperature=0.7,
            )

            return response.choices[0].message.content.strip()

        except Exception:
            # Fallback to a generic explanation if API fails
            return f"{card_name} offers great rewards for {category} purchases like {merchant}."

    async def analyze_merchant_category(
        self, merchant_name: str, place_types: List[str]
    ) -> Dict[str, Any]:
        """
        Analyze merchant information to determine optimal category and MCC.

        Args:
            merchant_name: Name of the merchant
            place_types: List of Google Places types

        Returns:
            Dict[str, Any]: Analysis results including category and MCC

        Raises:
            Exception: If API request fails
        """
        try:
            prompt = f"""
            Analyze this merchant: {merchant_name}
            Google Places types: {', '.join(place_types)}
            
            Provide:
            1. Best merchant category (e.g., Dining, Retail, Gas, Travel)
            2. Most likely MCC code
            3. Confidence score (0-1)
            
            Format as JSON:
            {{
                "category": "string",
                "mcc": "string", 
                "confidence": float,
                "reasoning": "string"
            }}
            """

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a merchant classification expert. Respond with valid JSON only.",
                    },
                    {"role": "user", "content": prompt},
                ],
                max_tokens=200,
                temperature=0.3,
            )

            # Parse the JSON response
            import json

            result = json.loads(response.choices[0].message.content.strip())
            return result

        except Exception:
            # Fallback to basic classification
            return {
                "category": "General",
                "mcc": "5999",
                "confidence": 0.5,
                "reasoning": "Basic fallback classification",
            }

    async def enhance_card_recommendation(
        self,
        card_name: str,
        merchant: str,
        category: str,
        user_preferences: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Enhance a card recommendation with AI-generated insights.

        Args:
            card_name: Name of the credit card
            merchant: Merchant name
            category: Merchant category
            user_preferences: Optional user preferences

        Returns:
            Dict[str, Any]: Enhanced recommendation with AI insights

        Raises:
            Exception: If API request fails
        """
        try:
            preferences_text = ""
            if user_preferences:
                preferences_text = f"User preferences: {user_preferences}"

            prompt = f"""
            Enhance this credit card recommendation:
            Card: {card_name}
            Merchant: {merchant}
            Category: {category}
            {preferences_text}
            
            Provide:
            1. Personalized explanation
            2. Key benefits for this specific merchant
            3. Any warnings or considerations
            4. Alternative cards to consider
            
            Format as JSON:
            {{
                "explanation": "string",
                "benefits": ["string"],
                "considerations": ["string"],
                "alternatives": ["string"]
            }}
            """

            response = self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a credit card expert. Provide helpful, accurate advice.",
                    },
                    {"role": "user", "content": prompt},
                ],
                max_tokens=300,
                temperature=0.6,
            )

            import json

            result = json.loads(response.choices[0].message.content.strip())
            return result

        except Exception:
            # Fallback response
            return {
                "explanation": f"{card_name} is recommended for {merchant}.",
                "benefits": ["Good rewards for this category"],
                "considerations": ["Check your credit score requirements"],
                "alternatives": ["Consider other cards in your portfolio"],
            }

    async def test_connection(self) -> bool:
        """
        Test the OpenAI API connection.

        Returns:
            bool: True if connection is successful
        """
        try:
            self.client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": "Test"}],
                max_tokens=5,
            )
            return True
        except Exception:
            return False
