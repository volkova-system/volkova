
POST http://localhost:4072/service/data/tasks/push
Content-Type: application/json
{
  "reference": "test-task-001",
  "name": "test-task",
  "description": "A test task for API testing",
  "actions": [
    {
      "reference": "test-action-001",
      "name": "click-button",
      "description": "Click the test button",
      "type": "click",
      "selector": "#test-button"
    }
  ]
}

POST http://localhost:4072/service/data/tasks/push
Content-Type: application/json
{
  "reference": "test-task-002",
  "name": "test-task",
  "description": "A test task for API testing",
  "actions": [
    {
      "reference": "test-action-002",
      "name": "click-control",
      "description": "Click the test control",
      "type": "click",
      "selector": "#test-control"
    }
  ]
}

GET http://localhost:4072/service/data/tasks

HTTP 200
[Asserts]
jsonpath "$.tasks" isCollection
jsonpath "$.total" isInteger
jsonpath "$.page" isInteger
jsonpath "$.pages" isInteger
