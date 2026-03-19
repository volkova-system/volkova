
POST http://localhost:4072/service/data/tasks/push
Content-Type: application/json
{
  "reference": "test-task-003",
  "name": "test-task",
  "description": "A test task for API testing",
  "actions": [
    {
      "reference": "test-action-003",
      "name": "click-link",
      "description": "Click the test link",
      "type": "click",
      "selector": "#test-link"
    }
  ]
}

GET http://localhost:4072/service/data/tasks/test-task-003

HTTP 200
[Asserts]
jsonpath "$.task.reference" == "test-task-003"
jsonpath "$.task.name" == "test-task"
jsonpath "$.task.actions" isCollection
jsonpath "$.task.actions[0].reference" == "test-action-003"
jsonpath "$.task.actions[0].type" == "click"
jsonpath "$.task.actions[0].selector" == "#test-link"
jsonpath "$.task.created_at" isString
jsonpath "$.task.updated_at" isString
