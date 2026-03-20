
GET http://localhost:4076/service/data/runtimes/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/runtimes/this/path/does/not/exists"
