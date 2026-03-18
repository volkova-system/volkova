
POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-001",
  "name": "Test Action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-button"
}

DELETE http://localhost:4071/service/data/actions/pop/test-action-001

HTTP 200
[Asserts]
jsonpath "$.status" == "success"
jsonpath "$.message" == "action popped"
