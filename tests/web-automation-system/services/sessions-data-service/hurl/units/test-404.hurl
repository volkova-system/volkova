
GET http://localhost:4075/service/data/sessions/this/path/does/not/exists

HTTP 404
[Asserts]
jsonpath "$.error" == "Not Found"
jsonpath "$.path" == "/service/data/sessions/this/path/does/not/exists"
