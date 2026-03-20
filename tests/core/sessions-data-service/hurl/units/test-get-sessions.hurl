
POST http://localhost:4075/service/data/sessions/push
Content-Type: application/json
{
  "reference": "test-session-001",
  "storage_state": {
    "cookies": [],
    "origins": []
  }
}

POST http://localhost:4075/service/data/sessions/push
Content-Type: application/json
{
  "reference": "test-session-002",
  "storage_state": {
    "cookies": [],
    "origins": []
  }
}

GET http://localhost:4075/service/data/sessions

HTTP 200
[Asserts]
jsonpath "$.sessions" isCollection
jsonpath "$.total" isInteger
jsonpath "$.page" isInteger
jsonpath "$.pages" isInteger
