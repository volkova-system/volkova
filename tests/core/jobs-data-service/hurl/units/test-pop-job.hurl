
POST http://localhost:4073/service/data/jobs/push
Content-Type: application/json
{
  "reference": "test-job-001",
  "name": "test-job",
  "description": "A test job for API testing",
  "tasks": [
    {
      "reference": "test-task-001",
      "name": "click-button",
      "description": "A test task for API testing",
      "actions": [
        {
          "reference": "test-action-001",
          "name": "click-button",
          "description": "A test action for API testing",
          "type": "click",
          "selector": "#test-button"
        }
      ]
    }
  ]
}

DELETE http://localhost:4073/service/data/jobs/pop/test-job-001

HTTP 200
[Asserts]
jsonpath "$.job.reference" == "test-job-001"
jsonpath "$.job.name" == "test-job"
jsonpath "$.job.tasks" isCollection
jsonpath "$.job.tasks[0].reference" == "test-task-001"
jsonpath "$.job.tasks[0].actions[0].reference" == "test-action-001"
jsonpath "$.job.tasks[0].actions[0].type" == "click"
jsonpath "$.job.tasks[0].actions[0].selector" == "#test-button"
jsonpath "$.job.created_at" isString
jsonpath "$.job.updated_at" isString
