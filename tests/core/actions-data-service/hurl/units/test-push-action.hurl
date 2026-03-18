
POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-001",
  "name": "Test Action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-button"
}

HTTP 200
[Asserts]
jsonpath "$.status" == "success"
jsonpath "$.message" == "action pushed"
