
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

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-queue-001"
