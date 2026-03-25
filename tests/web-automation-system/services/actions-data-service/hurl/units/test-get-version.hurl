
GET http://localhost:4071/service/data/actions/version

HTTP 200
[Asserts]
jsonpath "$.version.number" == "0.0.0"
jsonpath "$.version.service" == "actions-data-service"
