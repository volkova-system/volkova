# Pop Action Test
# Tests removing an action via DELETE /pop/:reference

DELETE http://localhost:4071/service/data/actions/pop/test-action-001

HTTP 200
[Asserts]
jsonpath "$.reference" == "test-action-001"
