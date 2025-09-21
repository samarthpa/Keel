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

    async def analyze_location_and_recommend_card(self, location_metadata: dict) -> dict:
        """
        Strict, auditable optimizer:
          1) Canonicalize category from MCC/place types.
          2) Build numeric multipliers table from rewards.json (everything_else = base).
          3) Ask LLM for JSON with the winner & brief explanation (temperature 0).
          4) Validate: if not argmax, correct to deterministic best.
          5) Deterministic fallback if LLM fails.

        Expects location_metadata to include:
          - merchant_name (str)
          - category (str|None)              # optional; we'll canonicalize anyway
          - mcc (str|None)
          - place_types (list[str]|None)
          - coordinates (dict|None)
          - user_cards (list[str])           # names matching rewards["cards"].keys()
          - user_rotating_active (list[str]) # lowercased categories active for "rotating" (e.g., ["dining"]); optional
        """
        import os, json, math, uuid
        print("Analyzing location and recommending card", location_metadata)
        # ---------- Helpers ----------
        def load_rewards() -> dict:
            # rewards.json at repo root per your structure
            current_dir = os.path.dirname(os.path.abspath(__file__))
            server_dir = os.path.dirname(os.path.dirname(current_dir))
            rewards_path = os.path.join(server_dir, "rewards.json")
            with open(rewards_path, "r") as f:
                return json.load(f)

        def lc(s):
            return s.lower().strip() if isinstance(s, str) else s

        def normalize_card_name(card_name: str) -> str:
            """
            Normalize card names to match rewards.json keys.
            Maps common variations to the exact names in rewards.json.
            """
            if not card_name:
                return card_name
                
            # Card name mappings to normalize iOS app names to rewards.json names
            card_mappings = {
                "amex gold card": "Amex Gold",
                "amex gold": "Amex Gold",
                "american express gold card": "Amex Gold",
                "american express gold": "Amex Gold",
                "chase sapphire preferred": "Chase Sapphire Preferred",
                "chase sapphire reserve": "Chase Sapphire Reserve",
                "chase freedom": "Chase Freedom",
                "chase freedom unlimited": "Chase Freedom Unlimited",
                "chase freedom flex": "Chase Freedom",
                "citi double cash": "Citi Double Cash",
                "citi custom cash": "Citi Custom Cash",
                "discover it cash back": "Discover it Cash Back",
                "discover it miles": "Discover it Miles",
                "capital one venture": "Capital One Venture",
                "capital one venture x": "Capital One Venture X",
                "amex platinum": "Amex Platinum",
                "amex blue cash preferred": "Amex Blue Cash Preferred",
                "amex blue cash everyday": "Amex Blue Cash Everyday",
                "wells fargo active cash": "Wells Fargo Active Cash",
                "bank of america customized cash": "Bank of America Customized Cash",
                "us bank cash+": "US Bank Cash+",
                "citi premier": "Citi Premier",
                "amex green": "Amex Green",
                "chase ink business preferred": "Chase Ink Business Preferred"
            }
            
            normalized = card_mappings.get(card_name.lower().strip(), card_name)
            return normalized

        def canonicalize_category(category: str | None, mcc: str | None, place_types: list[str] | None) -> str | None:
            """
            Map MCC + Google place types + provided category into our canonical keys
            that exist in rewards.rewards (dining/grocery/gas/travel/flights/hotels/transit/etc.).
            """
            # MCC signals (string keys in your file)
            mcc = (mcc or "").strip()
            types = [t.lower() for t in (place_types or [])]
            # Primary MCC mappings:
            mcc_map = {
                "5812": "dining", "5813": "dining", "5814": "dining",
                "5411": "grocery",
                "5541": "gas", "5542": "gas",
                "7011": "hotels",
                "4511": "flights",
                "4111": "transit", "4121": "transit",
                "5912": "drugstores",
                "4900": "utilities"
            }
            if mcc in mcc_map:
                return mcc_map[mcc]

            # Place type fallbacks:
            type_map = {
                "restaurant": "dining",
                "cafe": "dining",
                "coffee_shop": "dining",
                "grocery_or_supermarket": "grocery",
                "supermarket": "grocery",
                "gas_station": "gas",
                "lodging": "hotels",
                "airport": "flights",
                "train_station": "transit",
                "subway_station": "transit",
                "bus_station": "transit",
            }
            for t in types:
                if t in type_map:
                    return type_map[t]

            # Provided category hints:
            cat_alias = {
                "restaurants": "dining",
                "restaurant": "dining",
                "coffee": "dining",
                "cafe": "dining",
                "groceries": "grocery",
                "supermarket": "grocery",
                "fuel": "gas",
                "gas": "gas",
                "drugstore": "drugstores",
                "pharmacy": "drugstores",
                "utility": "utilities",
                "travel": "travel",
                "flights": "flights",
                "hotels": "hotels",
                "transit": "transit",
                "online_shopping": "online_shopping"
            }
            if category:
                return cat_alias.get(category.lower().strip(), category.lower().strip())

            # As a last resort, return None (will use base multipliers)
            return None

        def build_rows(user_cards: list[str], rewards: dict, canonical_category: str | None, rotating_active: set[str]) -> list[dict]:
            """
            For each user card, compute:
              - base_multiplier           := rewards['everything_else'] (default 1.0)
              - category_multiplier       := rewards.get(canonical_category, 0.0)
              - rotating_multiplier       := rewards.get('rotating', 0.0) if canonical_category in rotating_active
              - effective_multiplier      := max(category_multiplier, rotating_multiplier_if_active, base_multiplier)
            Returns list of rows: {card, category_multiplier, rotating_multiplier, base_multiplier, effective_multiplier}
            """
            cards_dict = rewards.get("cards", {})
            rows = []
            cc = lc(canonical_category) if canonical_category else None

            for card in user_cards:
                # Normalize card name to match rewards.json
                normalized_card = normalize_card_name(card)
                card_entry = cards_dict.get(normalized_card, {})
                rw = card_entry.get("rewards", {}) or {}
                base = float(rw.get("everything_else", 1.0) or 1.0)

                cat_mult = 0.0
                if cc:
                    # support specific travel subcats if present
                    cat_mult = float(rw.get(cc, 0.0) or 0.0)

                    # if the generic 'travel' key exists and cc is a travel subcat without explicit match, consider it
                    if cat_mult == 0.0 and cc in {"flights", "hotels", "transit"}:
                        cat_mult = float(rw.get("travel", 0.0) or 0.0)

                rot_mult = 0.0
                if cc and cc in rotating_active:
                    rot_mult = float(rw.get("rotating", 0.0) or 0.0)

                eff = max(base, cat_mult, rot_mult)
                rows.append({
                    "card": normalized_card,  # Use normalized name for consistency
                    "category_multiplier": cat_mult,
                    "rotating_multiplier": rot_mult,
                    "base_multiplier": base,
                    "effective_multiplier": eff
                })
            return rows

        def deterministic_best(rows: list[dict]) -> dict | None:
            """
            Tie-breaks:
              1) highest effective_multiplier
              2) highest base_multiplier
              3) alphabetical by card name (A→Z)
            """
            if not rows:
                return None
            # Find max effective
            max_eff = max(r["effective_multiplier"] for r in rows)
            eff_tied = [r for r in rows if math.isclose(r["effective_multiplier"], max_eff, rel_tol=1e-9, abs_tol=1e-9)]
            if len(eff_tied) == 1:
                return eff_tied[0]
            # Tie-break by base
            max_base = max(r["base_multiplier"] for r in eff_tied)
            base_tied = [r for r in eff_tied if math.isclose(r["base_multiplier"], max_base, rel_tol=1e-9, abs_tol=1e-9)]
            if len(base_tied) == 1:
                return base_tied[0]
            # Tie-break alphabetically
            base_tied.sort(key=lambda x: x["card"])
            return base_tied[0]

        # ---------- Load + preprocess ----------
        try:
            rewards = load_rewards()
            user_cards = list(location_metadata.get("user_cards") or [])
            if not user_cards:
                raise ValueError("No user_cards provided")

            canonical_category = canonicalize_category(
                location_metadata.get("category"),
                location_metadata.get("mcc"),
                location_metadata.get("place_types"),
            )

            rotating_active = set(lc(c) for c in (location_metadata.get("user_rotating_active") or []))

            rows = build_rows(user_cards, rewards, canonical_category, rotating_active)
            best = deterministic_best(rows)

            # If you trust rules 100%, you can skip the LLM and just return 'best' here.
            # We'll still use the LLM to craft a short explanation, then validate.

            # ---------- Build tightly-scoped prompt ----------
            multipliers_table_json = json.dumps(rows, indent=2)
            user_rotating_active_json = json.dumps(sorted(list(rotating_active)))

            prompt = f"""
You are a credit card rewards optimizer. Choose the single best card by strict numeric comparison.

INPUT
Merchant: {location_metadata.get('merchant_name', 'Unknown')}
Canonical Category (one word, lowercased): {canonical_category}
MCC: {location_metadata.get('mcc', 'Unknown')}
Place Types: {location_metadata.get('place_types', [])}
Coordinates: {location_metadata.get('coordinates', {})}

CONSTRAINTS
- Use ONLY the numeric multipliers provided below.
- Treat "everything_else" as the base rate for a card.
- Ignore annual fees, sign-up bonuses, portals, or any cards not listed here.
- Only treat the category "rotating" as active IF AND ONLY IF it appears in user_rotating_active.

USER CONTEXT
user_rotating_active (lowercased categories that are currently 5x for the user): {user_rotating_active_json}

AVAILABLE CARDS — multipliers table for THIS transaction
Each row lists the card's:
- category_multiplier: the multiplier for {canonical_category} if present (or 0 if not)
- rotating_multiplier: the multiplier for "rotating" if present (or 0 if not)
- base_multiplier: the "everything_else" multiplier
- effective_multiplier: max(category_multiplier, rotating_multiplier_if_active, base_multiplier)

{multipliers_table_json}

DECISION RULES
1) Choose the card with the highest effective_multiplier.
2) Tie-break #1: higher base_multiplier wins.
3) Tie-break #2: alphabetical by card name (A→Z).

OUTPUT (JSON ONLY)
{{
  "recommended_card": "Exact card name from the table",
  "explanation": "Short: <card> wins with <effective_multiplier>x on <canonical_category>; note if rotating applied; mention tie-break if used."
}}

Return ONLY the JSON. No extra text.
""".strip()

            # ---------- Call the model ----------
            response = self.client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "Follow instructions exactly. Output JSON only."},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=250,
                temperature=0.0,
            )
            raw = (response.choices[0].message.content or "").strip()

            # ---------- Parse + validate ----------
            try:
                gpt = json.loads(raw)
            except Exception as pe:
                gpt = {}

            provided_names = [r["card"] for r in rows]
            chosen_name = gpt.get("recommended_card")

            # If model suggested out-of-set or failed to parse, fall back deterministically
            if chosen_name not in provided_names or not best:
                return {
                    "recommended_card": best["card"] if best else "No specific recommendation",
                    "explanation": (
                        f"{best['card']} wins with {best['effective_multiplier']}x on "
                        f"{(canonical_category or 'base')} (deterministic fallback)."
                        if best else "Unavailable."
                    )
                }

            # Check if the choice is actually the argmax under our rules
            chosen_row = next(r for r in rows if r["card"] == chosen_name)
            optimal = deterministic_best(rows)
            if optimal and chosen_row["card"] != optimal["card"]:
                return {
                    "recommended_card": optimal["card"],
                    "explanation": (
                        f"{optimal['card']} wins with {optimal['effective_multiplier']}x on "
                        f"{(canonical_category or 'base')} (corrected to argmax)."
                    )
                }

            # Accept model output; ensure explanation exists
            explanation = gpt.get("explanation") or (
                f"{chosen_row['card']} wins with {chosen_row['effective_multiplier']}x on {(canonical_category or 'base')}."
            )
            return {"recommended_card": chosen_row["card"], "explanation": explanation}

        except Exception as e:
            # Absolute fallback
            try:
                if best:
                    return {
                        "recommended_card": best["card"],
                        "explanation": (
                            f"{best['card']} wins with {best['effective_multiplier']}x on "
                            f"{(canonical_category or 'base')} (fallback)."
                        )
                    }
            except Exception:
                pass
            return {
                "recommended_card": "No specific recommendation",
                "explanation": f"Unable to compute optimal card: {e}"
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
