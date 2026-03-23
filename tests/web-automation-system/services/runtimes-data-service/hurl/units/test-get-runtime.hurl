
POST http://localhost:4076/service/data/runtimes/push
Content-Type: application/json
{
  "reference": "test-runtime-003",
  "state": "doing",
  "session": {
    "reference": "test-session-003",
    "storage_state": {}
  },
  "queue": {
    "reference": "test-queue-003",
    "name": "test-queue",
    "description": "A test queue for API testing",
    "state": "idle",
    "index": 0
  },
  "job": {
    "reference": "test-job-003",
    "name": "test-job",
    "description": "A test job for API testing",
    "schedule": "0 * * * *"
  },
  "task": {
    "reference": "test-task-003",
    "name": "test-task",
    "description": "A test task for API testing"
  },
  "action": {
    "reference": "test-action-003",
    "name": "test-action",
    "description": "A test action for API testing",
    "type": "click",
    "selector": "#test-link"
  }
}

GET http://localhost:4076/service/data/runtimes/test-runtime-003

HTTP 200
[Asserts]
jsonpath "$.runtime.reference" == "test-runtime-003"
jsonpath "$.runtime.state" == "doing"
jsonpath "$.runtime.session.reference" == "test-session-003"
jsonpath "$.runtime.queue.reference" == "test-queue-003"
jsonpath "$.runtime.queue.name" == "test-queue"
jsonpath "$.runtime.job.reference" == "test-job-003"
jsonpath "$.runtime.job.name" == "test-job"
jsonpath "$.runtime.task.reference" == "test-task-003"
jsonpath "$.runtime.task.name" == "test-task"
jsonpath "$.runtime.action.reference" == "test-action-003"
jsonpath "$.runtime.action.type" == "click"
jsonpath "$.runtime.action.selector" == "#test-link"
jsonpath "$.runtime.created_at" isString
jsonpath "$.runtime.updated_at" isString
