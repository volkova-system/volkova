
GET http://localhost:4071/service/data/actions/health

HTTP 200
[Asserts]
jsonpath "$.status" == "healthy"
jsonpath "$.service" == "actions-data-service"
