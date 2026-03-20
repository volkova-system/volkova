
POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-003",
  "name": "test-action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-link"
}

GET http://localhost:4071/service/data/actions/test-action-003

HTTP 200
[Asserts]
jsonpath "$.action.reference" == "test-action-003"
jsonpath "$.action.name" == "test-action"
jsonpath "$.action.type" == "click"
jsonpath "$.action.selector" == "#test-link"
jsonpath "$.action.created_at" isString
jsonpath "$.action.updated_at" isString
