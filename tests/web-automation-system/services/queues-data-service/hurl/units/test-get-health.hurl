
GET http://localhost:4074/service/data/queues/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "queues-data-service"
