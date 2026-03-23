
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

DELETE http://localhost:4076/service/data/runtimes/pop/test-runtime-001

HTTP 200
[Asserts]
jsonpath "$.runtime.reference" == "test-runtime-001"
jsonpath "$.runtime.state" == "idle"
jsonpath "$.runtime.session.reference" == "test-session-001"
jsonpath "$.runtime.queue.reference" == "test-queue-001"
jsonpath "$.runtime.queue.name" == "test-queue"
jsonpath "$.runtime.job.reference" == "test-job-001"
jsonpath "$.runtime.job.name" == "test-job"
jsonpath "$.runtime.task.reference" == "test-task-001"
jsonpath "$.runtime.task.name" == "test-task"
jsonpath "$.runtime.action.reference" == "test-action-001"
jsonpath "$.runtime.action.type" == "click"
jsonpath "$.runtime.created_at" isString
jsonpath "$.runtime.updated_at" isString
