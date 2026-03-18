
GET http://localhost:4071/service/data/actions/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/actions/this/path/does/not/exists"
