
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

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-task-001"
