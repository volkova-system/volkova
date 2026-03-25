
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

POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "reference": "test-action-003",
  "name": "test-action",
  "description": "A test action for API testing",
  "type": "click",
  "selector": "#test-control"
}

GET http://localhost:4071/service/data/actions

HTTP 200
[Asserts]
jsonpath "$.actions" isCollection
jsonpath "$.total" == 3
jsonpath "$.skip" == 0
jsonpath "$.limit" == 10
jsonpath "$.pages" == 1
jsonpath "$.page" == 1
