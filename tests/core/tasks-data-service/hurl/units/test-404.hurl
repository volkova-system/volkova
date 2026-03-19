
GET http://localhost:4072/service/data/tasks/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/tasks/this/path/does/not/exists"
