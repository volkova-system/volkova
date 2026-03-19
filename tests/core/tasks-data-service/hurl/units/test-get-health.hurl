
GET http://localhost:4071/service/data/tasks/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "tasks-data-service"
