
GET http://localhost:4076/service/data/runtimes/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "runtimes-data-service"
