
GET http://localhost:4074/service/data/queues/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/queues/this/path/does/not/exists"
