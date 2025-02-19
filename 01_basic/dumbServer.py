from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Print headers in console
        print("Headers:")
        for header, value in self.headers.items():
            print(f"{header}: {value}")
        
        # Print received content in console
        content_length = int(self.headers.get('Content-Length', 0))
        if content_length:
            content = self.rfile.read(content_length)
            print("\nContent:")
            print(content.decode())
        else:
            print("\nNo content received.")
        
        # Send response status code
        response_data = {
          "files": [
            {
              "algorithm": "sha256",
              "checkSum": "436bb0ecdf0da094cb87f62243a3344a93266effc3c63adfb91d9f107de8ef8e",
              "content": "# The following determine where Terraform's state file is stored.\n\n#\nterraform {\n  backend \"gcs\" {\n    bucket = \"bkt-tfstate-iac-team-s\" # the backend is stored in a bucket typically in the common project\n    prefix = \"terraform/iac-team/sandbox/go-kcloutie\"\n  }\n}\n# ",
              "encoding": "text",
              "labels": {
                "debugOutput": "tfbackend - ",
                "fromTemplate": "tfbackend"
              },
              "length": 267,
              "object": "terraform { backend \"gcs\" { bucket = \"bkt-tfstate-iac-team-s\"",
              "path": "envs/backend.tf"
            },
            {
              "algorithm": "sha256",
              "checkSum": "436bb0ecdf0da094cb87f62243a3344a93266effc3c63adfb91d9f107de8ef8e",
              "content": "# The following determine where Terraform's state file is stored.\n\n#\nterraform {\n  backend \"gcs\" {\n    bucket = \"bkt-tfstate-iac-team-s\" # the backend is stored in a bucket typically in the common project\n    prefix = \"terraform/iac-team/sandbox/go-kcloutie\"\n  }\n}\n# ",
              "encoding": "text",
              "labels": {
                "debugOutput": "tfbackend - ",
                "fromTemplate": "tfbackend"
              },
              "length": 267,
              "object": "terraform { backend \"gcs\" { bucket = \"bkt-tfstate-iac-team-s\"",
              "path": "TESTbackend.tf"
            },
            {
              "algorithm": "sha256",
              "checkSum": "cb7f854a5192079175cec3a0ba69e9667978d6dd839cbfed07125e26b693dbaa",
              "content": " #",
              "encoding": "text",
              "labels": {
                "debugOutput": "app-config-template - ",
                "fromTemplate": "app-config-template"
              },
              "length": 2,
              "path": "modules/serverless-api-deploy/applicationConfig.tftpl"
            }
          ]
        }
        
        # Convert to JSON string
        response_json = json.dumps(response_data, indent=2)
        
        # Send response status code
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        
        # Send response to client
        self.wfile.write(response_json.encode())
        

if __name__ == "__main__":
    server_address = ("", 8282)
    httpd = HTTPServer(server_address, RequestHandler)
    print("Server running on port 8282...")
    httpd.serve_forever()