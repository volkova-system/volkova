
POST http://localhost:4071/service/data/actions/stop

HTTP 200
[Asserts]
jsonpath "$.operation.status" == "initiated"
jsonpath "$.operation.procedure" == "shutdown"
jsonpath "$.operation.service" == "actions-data-service"
jsonpath "$.operation.version" == "0.0.0"

