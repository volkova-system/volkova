
POST http://localhost:4074/service/data/queues/push
Content-Type: application/json
{
  "reference": "test-queue-001",
  "name": "test-queue",
  "description": "A test queue for API testing",
  "job": {
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
  },
  "state": "pending",
  "index": 0
}

DELETE http://localhost:4074/service/data/queues/pop/test-queue-001

HTTP 200
[Asserts]
jsonpath "$.queue.reference" == "test-queue-001"
jsonpath "$.queue.name" == "test-queue"
jsonpath "$.queue.job.reference" == "test-job-001"
jsonpath "$.queue.job.tasks" isCollection
jsonpath "$.queue.job.tasks[0].reference" == "test-task-001"
jsonpath "$.queue.job.tasks[0].actions[0].reference" == "test-action-001"
jsonpath "$.queue.job.tasks[0].actions[0].type" == "click"
jsonpath "$.queue.job.tasks[0].actions[0].selector" == "#test-button"
jsonpath "$.queue.state" == "pending"
jsonpath "$.queue.created_at" isString
jsonpath "$.queue.updated_at" isString
