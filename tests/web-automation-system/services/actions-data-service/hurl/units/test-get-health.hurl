
GET http://localhost:4071/service/data/actions/health

HTTP 200
[Asserts]
jsonpath "$.health.status" == "healthy"
jsonpath "$.health.service" == "actions-data-service"
jsonpath "$.health.version" == "0.0.0"
