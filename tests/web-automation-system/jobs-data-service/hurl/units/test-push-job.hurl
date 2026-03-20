
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

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-job-001"
