# 500 Server Error Test
# Tests server error scenarios with invalid JSON payload

POST http://localhost:4071/service/data/actions/push
Content-Type: application/json
{
  "invalid": "json",
  "missing": "required_fields"
}

HTTP 500
[Asserts]
jsonpath "$.error" exists
