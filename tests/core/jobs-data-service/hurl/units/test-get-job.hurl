
POST http://localhost:4073/service/data/jobs/push
Content-Type: application/json
{
  "reference": "test-job-003",
  "name": "test-job",
  "description": "A test job for API testing",
  "tasks": [
    {
      "reference": "test-task-003",
      "name": "test-task",
      "description": "A test task",
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
  ]
}

GET http://localhost:4073/service/data/jobs/test-job-003

HTTP 200
[Asserts]
jsonpath "$.job.reference" == "test-job-003"
jsonpath "$.job.name" == "test-job"
jsonpath "$.job.tasks" isCollection
jsonpath "$.job.tasks[0].reference" == "test-task-003"
jsonpath "$.job.tasks[0].actions" isCollection
jsonpath "$.job.tasks[0].actions[0].reference" == "test-action-003"
jsonpath "$.job.tasks[0].actions[0].type" == "click"
jsonpath "$.job.tasks[0].actions[0].selector" == "#test-link"
jsonpath "$.job.created_at" isString
jsonpath "$.job.updated_at" isString
