
GET http://localhost:4075/service/data/sessions/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "sessions-data-service"
