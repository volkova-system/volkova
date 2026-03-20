
GET http://localhost:4073/service/data/jobs/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "jobs-data-service"
