"""
Places Client Service

Service for interacting with Google Places API to resolve merchant
information from coordinates.
"""

from typing import Dict, Any, Optional, List, Tuple
import httpx
import asyncio
from app.settings import settings


class PlacesClient:
    """
    Client for Google Places API integration.

    Handles merchant resolution from coordinates using Google Places API.
    """

    def __init__(self):
        """
        Initialize the Places client.
        """
        self.api_key = settings.google_places_api_key
        self.base_url = "https://maps.googleapis.com/maps/api/place"
        # Default settings - these should be moved to settings.py
        self.radius = getattr(settings, "places_radius", 100)
        self.timeout = getattr(settings, "places_timeout", 10)
        self.retries = getattr(settings, "places_retries", 3)

    async def nearby(self, lat: float, lon: float) -> List[Dict[str, Any]]:
        """
        Call Google Places Nearby Search API to find nearby businesses.

        Args:
            lat: Latitude coordinate
            lon: Longitude coordinate

        Returns:
            List[Dict[str, Any]]: List of nearby places from Google Places API

        Raises:
            Exception: If API request fails after retries
        """
        # Build the API URL for nearby search
        url = f"{self.base_url}/nearbysearch/json"
        params = {
            "location": f"{lat},{lon}",
            "radius": self.radius,
            "key": self.api_key,
            # Don't use type parameter to get broader results, we'll filter them
        }

        # Retry loop for API requests
        for attempt in range(self.retries):
            try:
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(url, params=params)
                    response.raise_for_status()

                    data = response.json()

                    if data.get("status") == "OK":
                        results = data.get("results", [])
                        # Filter out non-business results and prioritize actual businesses
                        filtered_results = self._filter_business_results(results)
                        return filtered_results
                    elif data.get("status") == "ZERO_RESULTS":
                        return []
                    else:
                        # API returned an error status
                        error_message = data.get("error_message", "Unknown API error")
                        raise Exception(
                            f"Google Places API error: {data.get('status')} - {error_message}"
                        )

            except httpx.TimeoutException:
                if attempt == self.retries - 1:
                    raise Exception(
                        f"Google Places API timeout after {self.retries} attempts"
                    )
                await asyncio.sleep(1 * (attempt + 1))  # Exponential backoff

            except httpx.HTTPStatusError as e:
                if attempt == self.retries - 1:
                    raise Exception(
                        f"Google Places API HTTP error: {e.response.status_code}"
                    )
                await asyncio.sleep(1 * (attempt + 1))

            except Exception as e:
                if attempt == self.retries - 1:
                    raise Exception(f"Google Places API error: {str(e)}")
                await asyncio.sleep(1 * (attempt + 1))

        return []

    def _filter_business_results(self, results: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Filter Google Places results to prioritize actual businesses over localities.
        
        Args:
            results: Raw results from Google Places API
            
        Returns:
            List[Dict[str, Any]]: Filtered results prioritizing businesses
        """
        # Types that indicate actual businesses/establishments
        business_types = {
            'store', 'restaurant', 'food', 'shopping_mall', 'supermarket', 'grocery_or_supermarket',
            'gas_station', 'pharmacy', 'bank', 'atm', 'hospital', 'clothing_store', 'electronics_store',
            'furniture_store', 'home_goods_store', 'jewelry_store', 'shoe_store', 'book_store',
            'bicycle_store', 'car_dealer', 'car_rental', 'car_repair', 'car_wash', 'laundry',
            'beauty_salon', 'hair_care', 'spa', 'gym', 'movie_theater', 'night_club', 'bar',
            'cafe', 'bakery', 'meal_takeaway', 'meal_delivery', 'liquor_store', 'convenience_store',
            'department_store', 'hardware_store', 'pet_store', 'travel_agency', 'real_estate_agency',
            'insurance_agency', 'accounting', 'lawyer', 'dentist', 'doctor', 'veterinary_care',
            'post_office', 'library', 'museum', 'art_gallery', 'tourist_attraction', 'amusement_park',
            'zoo', 'aquarium', 'stadium', 'university', 'school', 'church', 'mosque', 'synagogue',
            'hindu_temple', 'cemetery', 'funeral_home', 'embassy', 'city_hall', 'courthouse',
            'police', 'fire_station', 'hospital', 'pharmacy', 'dentist', 'doctor', 'veterinary_care'
        }
        
        # Types to exclude (non-business entities)
        exclude_types = {
            'locality', 'political', 'country', 'administrative_area_level_1', 
            'administrative_area_level_2', 'administrative_area_level_3',
            'administrative_area_level_4', 'administrative_area_level_5',
            'colloquial_area', 'sublocality', 'sublocality_level_1', 'sublocality_level_2',
            'sublocality_level_3', 'sublocality_level_4', 'sublocality_level_5',
            'neighborhood', 'premise', 'subpremise', 'postal_code', 'route', 'street_address',
            'intersection', 'street_number', 'airport', 'bus_station', 'subway_station',
            'train_station', 'transit_station', 'parking', 'park'
        }
        
        filtered_results = []
        
        for result in results:
            place_types = set(result.get('types', []))
            
            # Skip if it's clearly a non-business entity
            if place_types.intersection(exclude_types):
                continue
                
            # Prioritize results that have business-related types
            if place_types.intersection(business_types):
                filtered_results.append(result)
            # Also include results that don't have obvious non-business types
            # (in case Google adds new business types we haven't covered)
            elif not place_types.intersection(exclude_types):
                # Additional check: make sure it has a reasonable name
                name = result.get('name', '').strip()
                if name and len(name) > 2 and not name.lower() in ['san francisco', 'california', 'usa']:
                    filtered_results.append(result)
        
        # Sort by business relevance (more business types = higher priority)
        def business_score(result):
            place_types = set(result.get('types', []))
            return len(place_types.intersection(business_types))
        
        filtered_results.sort(key=business_score, reverse=True)
        
        return filtered_results

    def map_types_to_mcc_category(
        self, types: List[str]
    ) -> Tuple[Optional[str], Optional[str]]:
        """
        Map Google Places types to MCC codes and categories.

        This function maps common Google Places types to standard MCC codes
        and merchant categories used in credit card processing.

        Args:
            types: List of Google Places types from the API

        Returns:
            Tuple[Optional[str], Optional[str]]: (mcc_code, category)

        Example:
            >>> map_types_to_mcc_category(["restaurant", "food"])
            ("5812", "Dining")

        Note: To extend mappings, add new entries to the mcc_mapping and
        category_mapping dictionaries below. The function will automatically
        use the first matching type found in the list.
        """
        # MCC code mapping for common Google Places types
        # Reference: https://www.mastercard.com/us/support/merchant-category-codes.html
        mcc_mapping = {
            # Dining and Food
            "restaurant": "5812",  # Eating Places and Restaurants
            "cafe": "5812",  # Eating Places and Restaurants
            "coffee_shop": "5812",  # Eating Places and Restaurants
            "bakery": "5812",  # Eating Places and Restaurants
            "food": "5812",  # Eating Places and Restaurants
            "meal_takeaway": "5812",  # Eating Places and Restaurants
            "meal_delivery": "5812",  # Eating Places and Restaurants
            # Grocery and Retail
            "grocery_or_supermarket": "5411",  # Grocery Stores, Supermarkets
            "supermarket": "5411",  # Grocery Stores, Supermarkets
            "convenience_store": "5411",  # Grocery Stores, Supermarkets
            "department_store": "5311",  # Department Stores
            "clothing_store": "5651",  # Family Clothing Stores
            "shoe_store": "5661",  # Shoe Stores
            "jewelry_store": "5944",  # Jewelry Stores, Watches, Precious Stones, and Precious Metals
            "electronics_store": "5732",  # Electronics Stores
            # Gas and Transportation
            "gas_station": "5541",  # Service Stations (with or without ancillary services)
            "car_rental": "7512",  # Automobile Rental Agency
            "car_dealer": "5511",  # Automobile and Truck Dealers (New and Used) Sales, Service, Repairs, Parts and Leasing
            # Travel and Lodging
            "lodging": "7011",  # Hotels, Motels, Resorts
            "hotel": "7011",  # Hotels, Motels, Resorts
            "travel_agency": "4722",  # Travel Agencies, Tour Operators
            # Entertainment and Recreation
            "movie_theater": "7832",  # Motion Picture Theaters
            "amusement_park": "7996",  # Amusement Parks, Circuses, Carnivals, and Fortune Tellers
            "gym": "7997",  # Health Clubs, Membership Sports and Recreation Clubs
            "spa": "7298",  # Health and Beauty Spas
            # Services
            "bank": "6011",  # Automated Cash Disbursements
            "atm": "6011",  # Automated Cash Disbursements
            "pharmacy": "5912",  # Drug Stores and Pharmacies
            "hospital": "8062",  # Hospitals
            "dentist": "8021",  # Offices and Clinics of Dentists
            "doctor": "8011",  # Offices and Clinics of Medical Doctors
            "veterinary_care": "0742",  # Veterinary Services
            # General Retail
            "store": "5999",  # Miscellaneous and Specialty Retail Stores
            "establishment": "5999",  # Miscellaneous and Specialty Retail Stores
            "point_of_interest": "5999",  # Miscellaneous and Specialty Retail Stores
        }

        # Category mapping for business types
        # These categories align with credit card reward categories
        category_mapping = {
            # Dining and Food
            "restaurant": "Dining",
            "cafe": "Dining",
            "coffee_shop": "Dining",
            "bakery": "Dining",
            "food": "Dining",
            "meal_takeaway": "Dining",
            "meal_delivery": "Dining",
            # Grocery and Retail
            "grocery_or_supermarket": "Grocery",
            "supermarket": "Grocery",
            "convenience_store": "Grocery",
            "department_store": "Department Store",
            "clothing_store": "Retail",
            "shoe_store": "Retail",
            "jewelry_store": "Retail",
            "electronics_store": "Retail",
            # Gas and Transportation
            "gas_station": "Gas",
            "car_rental": "Travel",
            "car_dealer": "Automotive",
            # Travel and Lodging
            "lodging": "Travel",
            "hotel": "Travel",
            "travel_agency": "Travel",
            # Entertainment and Recreation
            "movie_theater": "Entertainment",
            "amusement_park": "Entertainment",
            "gym": "Fitness",
            "spa": "Wellness",
            # Services
            "bank": "Financial",
            "atm": "Financial",
            "pharmacy": "Healthcare",
            "hospital": "Healthcare",
            "dentist": "Healthcare",
            "doctor": "Healthcare",
            "veterinary_care": "Pet Care",
            # General Retail
            "store": "Retail",
            "establishment": "General",
            "point_of_interest": "General",
        }

        # Find the first matching type in the provided list
        for place_type in types:
            if place_type in mcc_mapping:
                mcc_code = mcc_mapping[place_type]
                category = category_mapping.get(place_type, "General")
                return mcc_code, category

        # No match found
        return None, None

    async def find_nearby_places(
        self,
        lat: float,
        lon: float,
        radius: int = 100,
        types: Optional[List[str]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Find nearby places using Google Places API.

        Args:
            lat: Latitude coordinate
            lon: Longitude coordinate
            radius: Search radius in meters
            types: List of place types to search for

        Returns:
            List[Dict[str, Any]]: List of nearby places

        Raises:
            Exception: If API request fails
        """
        # Use the new nearby() function
        return await self.nearby(lat, lon)

    async def get_place_details(self, place_id: str) -> Dict[str, Any]:
        """
        Get detailed information about a specific place.

        Args:
            place_id: Google Places place ID

        Returns:
            Dict[str, Any]: Detailed place information

        Raises:
            Exception: If API request fails
        """
        # TODO: Implement place details retrieval
        # This will fetch detailed information about a specific place
        # including business hours, contact info, etc.

        return {
            "name": "Sample Store",
            "formatted_address": "123 Sample St, City, State",
            "formatted_phone_number": "+1-555-123-4567",
            "website": "https://samplestore.com",
            "opening_hours": {"open_now": True, "periods": []},
            "types": ["store", "establishment"],
        }

    async def resolve_merchant(
        self, lat: float, lon: float, radius: int = 100
    ) -> Dict[str, Any]:
        """
        Resolve merchant information from coordinates.

        Args:
            lat: Latitude coordinate
            lon: Longitude coordinate
            radius: Search radius in meters

        Returns:
            Dict[str, Any]: Resolved merchant information

        Raises:
            Exception: If resolution fails
        """
        # TODO: Implement merchant resolution logic
        # This will find the most relevant nearby business
        # and return structured merchant information

        places = await self.find_nearby_places(lat, lon, radius)

        if not places:
            raise Exception("No places found at coordinates")

        # Select the most relevant place
        best_place = places[0]

        # Use the new mapping function
        mcc_code, category = self.map_types_to_mcc_category(best_place.get("types", []))

        return {
            "merchant": best_place.get("name", "Unknown"),
            "mcc": mcc_code,
            "category": category or "General",
            "confidence": 0.85,
        }

    def _get_mcc_from_types(self, types: List[str]) -> Optional[str]:
        """
        Map Google Places types to MCC codes.

        Args:
            types: List of Google Places types

        Returns:
            Optional[str]: MCC code if found
        """
        # Use the new mapping function
        mcc_code, _ = self.map_types_to_mcc_category(types)
        return mcc_code

    def _get_category_from_types(self, types: List[str]) -> str:
        """
        Map Google Places types to merchant categories.

        Args:
            types: List of Google Places types

        Returns:
            str: Merchant category
        """
        # Use the new mapping function
        _, category = self.map_types_to_mcc_category(types)
        return category or "General"
