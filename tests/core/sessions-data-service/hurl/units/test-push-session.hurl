
POST http://localhost:4075/service/data/sessions/push
Content-Type: application/json
{
  "reference": "test-session-001",
  "storage_state": {
    "cookies": [],
    "origins": []
  }
}

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-session-001"
