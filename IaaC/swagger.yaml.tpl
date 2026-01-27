openapi: 3.0.1

info:
  title: Student Management API
  version: "1.0.0"

paths:
  /students:
    get:
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: ${lambda_invoke_arn}

      responses:
        "200":
          description: OK

    post:
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: ${lambda_invoke_arn}

      responses:
        "201":
          description: Created