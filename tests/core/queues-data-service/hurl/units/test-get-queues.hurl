
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

POST http://localhost:4074/service/data/queues/push
Content-Type: application/json
{
  "reference": "test-queue-002",
  "name": "test-queue",
  "description": "A test queue for API testing",
  "job": {
    "reference": "test-job-002",
    "name": "test-job",
    "description": "A test job for API testing",
    "tasks": [
      {
        "reference": "test-task-002",
        "name": "click-control",
        "description": "A test task for API testing",
        "actions": [
          {
            "reference": "test-action-002",
            "name": "click-control",
            "description": "A test action for API testing",
            "type": "click",
            "selector": "#test-control"
          }
        ]
      }
    ]
  },
  "state": "pending",
  "index": 1
}

GET http://localhost:4074/service/data/queues

HTTP 200
[Asserts]
jsonpath "$.queues" isCollection
jsonpath "$.total" isInteger
jsonpath "$.page" isInteger
jsonpath "$.pages" isInteger
