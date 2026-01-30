openapi: 3.0.1

info:
  title: Student Management API
  version: "1.0.0"

# 🌍 Global CORS configuration
x-amazon-apigateway-cors:
  allowOrigins:
    - "http://stu-ptl-dev-use-frontend.s3-website-us-east-1.amazonaws.com/"
  allowMethods:
    - GET
    - POST
    - OPTIONS
  allowHeaders:
    - Content-Type

paths:
  /students:

    # 🔹 GET students
    get:
      responses:
        "200":
          description: OK
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: ${lambda_invoke_arn}

    # 🔹 CREATE student
    post:
      responses:
        "201":
          description: Created
      x-amazon-apigateway-integration:
        type: aws_proxy
        httpMethod: POST
        uri: ${lambda_invoke_arn}

    # 🔹 CORS preflight
    options:
      summary: CORS support
      responses:
        "200":
          description: CORS OK
          headers:
            Access-Control-Allow-Origin:
              schema:
                type: string
            Access-Control-Allow-Methods:
              schema:
                type: string
            Access-Control-Allow-Headers:
              schema:
                type: string
      x-amazon-apigateway-integration:
        type: mock
        requestTemplates:
          application/json: |
            {
              "statusCode": 200
            }
        responses:
          default:
            statusCode: "200"
            responseParameters:
              method.response.header.Access-Control-Allow-Origin: "'*'"
              method.response.header.Access-Control-Allow-Methods: "'GET,POST,OPTIONS'"
              method.response.header.Access-Control-Allow-Headers: "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"