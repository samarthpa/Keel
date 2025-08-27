# AWS SAM Deploy (Card Optimizer MVP)

## Prereqs
- AWS CLI configured (`aws configure`)
- SAM CLI installed (`brew install aws/tap/aws-sam-cli`)
- Python 3.11 available

## One-time: create Google Places secret
Replace YOUR_KEY:
```bash
aws secretsmanager create-secret \
  --name google/places/api_key \
  --secret-string '{"key":"YOUR_KEY"}'
```

## Build & Deploy
```bash
cd infra
sam build
sam deploy --guided
# Accept defaults; note the API URL output
```

## Smoke test
Replace <api> and <region> from your deploy output:
```bash
curl "https://<api>.execute-api.<region>.amazonaws.com/prod/merchant/resolve?lat=40.741&lon=-73.989"

curl -X POST "https://<api>.execute-api.<region>.amazonaws.com/prod/score" \
  -H "Content-Type: application/json" \
  -d '{"merchant":"Starbucks","category":"dining","cards":["Amex Gold","Chase Freedom","Citi Custom Cash"]}'
```

## iOS config
In your Swift code set:
```swift
struct ApiConfig {
    static var baseURL = URL(string: "https://<api>.execute-api.<region>.amazonaws.com/prod")!
}
```

## Notes
- This is a minimal MVP. Add retries/timeouts, caching, and better type/category mapping as you iterate.
- For dense areas, fuse confidence from dwell time, history priors, and distance before calling resolve.
