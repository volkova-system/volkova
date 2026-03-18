# Get Single Action Test
# Tests retrieving a specific action by reference via GET /:reference

GET http://localhost:4071/service/data/actions/test-action-001

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-action-001"
jsonpath "$.name" == "Test Action"
jsonpath "$.type" == "click"
jsonpath "$.created_at" isString
jsonpath "$.updated_at" isString
