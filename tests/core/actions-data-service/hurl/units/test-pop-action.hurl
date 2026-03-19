
POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-001",
  "name": "test-action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-button"
}

DELETE http://localhost:4071/service/data/actions/pop/test-action-001

HTTP 200
[Asserts]
jsonpath "$.action.reference" == "test-action-001"
jsonpath "$.action.name" == "test-action"
jsonpath "$.action.type" == "click"
jsonpath "$.action.selector" == "#test-button"
jsonpath "$.action.created_at" isString
jsonpath "$.action.updated_at" isString
