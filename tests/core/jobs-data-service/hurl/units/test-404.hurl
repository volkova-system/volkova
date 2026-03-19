
GET http://localhost:4073/service/data/jobs/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/jobs/this/path/does/not/exists"
