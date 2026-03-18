# Get Actions Test
# Tests retrieving all actions via GET /

GET http://localhost:4071/service/data/actions/

HTTP 200
[Asserts]
jsonpath "$.actions" isCollection
jsonpath "$.total" isInteger
jsonpath "$.page" isInteger
jsonpath "$.pages" isInteger
