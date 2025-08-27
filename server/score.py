import json

REWARDS = {
    "Amex Gold": {"base":1.0,"categories":{"dining":4.0,"grocery":4.0}},
    "Chase Freedom": {"base":1.0,"categories":{"rotating":5.0}},
    "Citi Custom Cash": {"base":1.0,"categories":{"dining":5.0,"gas":5.0}}
}

def _resp(code: int, body: dict) -> dict:
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }

def handler(event, context):
    try:
        body = json.loads(event.get("body") or "{}")
        merchant = body.get("merchant")
        category = (body.get("category") or "").lower() or None
        cards = body.get("cards") or list(REWARDS.keys())
    except Exception:
        return _resp(400, {"error":{"code":"BAD_JSON","message":"Invalid JSON"}})

    out = []
    for card in cards:
        rules = REWARDS.get(card, {"base":1.0,"categories":{}})
        score = rules["categories"].get(category, rules["base"]) if category else rules["base"]
        reason = (f"{int(score)}x {category}" if category and score>rules["base"] else f"{rules['base']}x base")
        out.append({"card": card, "score": float(score), "reason": reason})

    out.sort(key=lambda x: x["score"], reverse=True)
    return _resp(200, {"top": out[:3]})
