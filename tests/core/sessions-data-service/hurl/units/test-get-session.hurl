
POST http://localhost:4075/service/data/sessions/push
Content-Type: application/json
{
  "reference": "test-session-003",
  "storage_state": {
    "cookies": [],
    "origins": []
  }
}

GET http://localhost:4075/service/data/sessions/test-session-003

HTTP 200
[Asserts]
jsonpath "$.session.reference" == "test-session-003"
jsonpath "$.session.storage_state" exists
jsonpath "$.session.created_at" isString
jsonpath "$.session.updated_at" isString
