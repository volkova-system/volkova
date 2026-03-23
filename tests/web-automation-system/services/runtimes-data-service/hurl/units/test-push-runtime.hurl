
POST http://localhost:4076/service/data/runtimes/push
Content-Type: application/json
{
  "reference": "test-runtime-001",
  "state": "idle",
  "session": {
    "reference": "test-session-001",
    "storage_state": {}
  },
  "queue": {
    "reference": "test-queue-001",
    "name": "test-queue",
    "description": "A test queue for API testing",
    "state": "idle",
    "index": 0
  },
  "job": {
    "reference": "test-job-001",
    "name": "test-job",
    "description": "A test job for API testing",
    "schedule": "0 * * * *"
  },
  "task": {
    "reference": "test-task-001",
    "name": "test-task",
    "description": "A test task for API testing"
  },
  "action": {
    "reference": "test-action-001",
    "name": "test-action",
    "description": "A test action for API testing",
    "type": "click",
    "selector": "#test-button"
  }
}

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-runtime-001"
