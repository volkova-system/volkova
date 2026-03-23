
POST http://localhost:4075/service/data/sessions/push
Content-Type: application/json
{
  "reference": "test-session-001",
  "storage_state": {
    "cookies": [],
    "origins": []
  }
}

DELETE http://localhost:4075/service/data/sessions/pop/test-session-001

HTTP 200
[Asserts]
jsonpath "$.session.reference" == "test-session-001"
jsonpath "$.session.storage_state" exists
jsonpath "$.session.created_at" isString
jsonpath "$.session.updated_at" isString
