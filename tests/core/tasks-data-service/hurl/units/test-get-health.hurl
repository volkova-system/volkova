
GET http://localhost:4072/service/data/tasks/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "tasks-data-service"
