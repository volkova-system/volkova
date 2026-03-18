
POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-001",
  "name": "test-action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-button"
}

POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-002",
  "name": "test-action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-control"
}

GET http://localhost:4071/service/data/actions

HTTP 200
[Asserts]
jsonpath "$.actions" isCollection
jsonpath "$.total" isInteger
jsonpath "$.page" isInteger
jsonpath "$.pages" isInteger
