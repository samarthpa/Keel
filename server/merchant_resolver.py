import os, json, requests, boto3

def _get_secret_json(name: str) -> dict:
    sm = boto3.client("secretsmanager")
    val = sm.get_secret_value(SecretId=name)["SecretString"]
    return json.loads(val)

def _resp(code: int, body: dict) -> dict:
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }

def handler(event, context):
    # Query params (Lambda proxy)
    qs = (event.get("queryStringParameters") or {})
    lat = qs.get("lat"); lon = qs.get("lon")
    if not lat or not lon:
        return _resp(400, {"error":{"code":"BAD_REQUEST","message":"lat/lon required"}})

    secret_name = os.environ.get("GOOGLE_SECRET_NAME", "google/places/api_key")
    try:
        api_key = _get_secret_json(secret_name)["key"]
    except Exception as e:
        return _resp(500, {"error":{"code":"SECRET_MISSING","message":str(e)}})

    try:
        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        params = {"location": f"{lat},{lon}", "radius": 100, "key": api_key}
        r = requests.get(url, params=params, timeout=1.5)
        if r.status_code != 200:
            return _resp(502, {"error":{"code":"PLACES_UPSTREAM","message":f"HTTP {r.status_code}"}})
        data = r.json()
    except Exception as e:
        return _resp(502, {"error":{"code":"PLACES_ERROR","message":str(e)}})

    results = data.get("results") or []
    if not results:
        return _resp(404, {"error":{"code":"NO_CANDIDATE","message":"No nearby places"}})

    top = results[0]
    name = top.get("name", "Unknown")
    types = top.get("types", [])

    mapping = {
        "restaurant": ("5812","dining"),
        "cafe": ("5814","dining"),
        "coffee_shop": ("5814","dining"),
        "grocery_or_supermarket": ("5411","grocery"),
        "gas_station": ("5541","gas"),
        "department_store": ("5311","department_store"),
        "supermarket": ("5411","grocery"),
        "bakery": ("5814","dining"),
    }
    mcc, category = None, None
    for t in types:
        if t in mapping:
            mcc, category = mapping[t]
            break

    confidence = 0.8 if mcc else 0.6
    return _resp(200, {
        "merchant": name,
        "mcc": mcc,
        "category": category,
        "confidence": confidence
    })
