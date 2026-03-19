
POST http://localhost:4071/service/data/tasks/push
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

DELETE http://localhost:4071/service/data/tasks/pop/test-task-001

HTTP 200
[Asserts]
jsonpath "$.task.reference" == "test-task-001"
jsonpath "$.task.name" == "test-task"
jsonpath "$.task.actions" isCollection
jsonpath "$.task.actions[0].reference" == "test-action-001"
jsonpath "$.task.actions[0].type" == "click"
jsonpath "$.task.actions[0].selector" == "#test-button"
jsonpath "$.task.created_at" isString
jsonpath "$.task.updated_at" isString
