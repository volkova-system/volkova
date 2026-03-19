
GET http://localhost:4071/service/data/tasks/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/tasks/this/path/does/not/exists"
