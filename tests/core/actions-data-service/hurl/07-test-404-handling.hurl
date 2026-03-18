# 404 Not Found Test
# Tests that non-existent endpoints return 404

GET http://localhost:4071/service/data/actions/non-existent-endpoint

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/actions/non-existent-endpoint"
