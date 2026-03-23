
POST http://localhost:4074/service/data/queues/push
Content-Type: application/json
{
  "reference": "test-queue-003",
  "name": "test-queue",
  "description": "A test queue for API testing",
  "job": {
    "reference": "test-job-003",
    "name": "test-job",
    "description": "A test job for API testing",
    "tasks": [
      {
        "reference": "test-task-003",
        "name": "click-link",
        "description": "A test task for API testing",
        "actions": [
          {
            "reference": "test-action-003",
            "name": "click-link",
            "description": "A test action for API testing",
            "type": "click",
            "selector": "#test-link"
          }
        ]
      }
    ]
  },
  "state": "pending",
  "index": 0
}

GET http://localhost:4074/service/data/queues/test-queue-003

HTTP 200
[Asserts]
jsonpath "$.queue.reference" == "test-queue-003"
jsonpath "$.queue.name" == "test-queue"
jsonpath "$.queue.job.reference" == "test-job-003"
jsonpath "$.queue.job.tasks" isCollection
jsonpath "$.queue.job.tasks[0].reference" == "test-task-003"
jsonpath "$.queue.job.tasks[0].actions[0].reference" == "test-action-003"
jsonpath "$.queue.job.tasks[0].actions[0].type" == "click"
jsonpath "$.queue.job.tasks[0].actions[0].selector" == "#test-link"
jsonpath "$.queue.state" == "pending"
jsonpath "$.queue.created_at" isString
jsonpath "$.queue.updated_at" isString
