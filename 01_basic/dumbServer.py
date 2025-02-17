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
              "checkSum": "5c467cb299d939d28ce7c92b25eca14f4b6e7e1d2c5d67aebd2ce64e6aba3157",
              "content": "resource \"google_service_account_iam_member\" \"pd303-wif-binding-iac-team\" {\n  service_account_id = \"projects/ford-8edaae30b2e9557b50272c08/serviceAccounts/sa-pipeline@ford-8edaae30b2e9557b50272c08.iam.gserviceaccount.com\"\n  role               = \"roles/iam.workloadIdentityUser\"\n  member             = \"principal://iam.googleapis.com/projects/448146263476/locations/global/workloadIdentityPools/pd303-5g4zs/subject/system:serviceaccount:iac-team:pipeline\"\n}",
              "encoding": "text",
              "labels": {
                "debugOutput": "wif-terraform - ",
                "fromTemplate": "wif-terraform"
              },
              "length": 456,
              "object": "resource \"google_service_account_iam_member\" \"pd303-wif-binding-iac-team\" { service_account_id = \"projects/ford-8edaae30b2e9557b50272c08/serviceAccounts/sa-pipeline@ford-8edaae30b2e9557b50272c08.iam.gserviceaccount.com\" role               = \"roles/iam.workloadIdentityUser\" member             = \"principal://iam.googleapis.com/projects/448146263476/locations/global/workloadIdentityPools/pd303-5g4zs/subject/system:serviceaccount:iac-team:pipeline\" }",
              "path": "/modules/.google-creds-sandbox.tf"
            },
            {
              "algorithm": "sha256",
              "checkSum": "b609fd2847a3ea1fa37e551c03dca6f368ab3cbf1bce3def0444f5732544fdfa",
              "content": "# This is a comment.\n# Each line is a file pattern followed by one or more owners.\n\n# These owners will be the default owners for everything in\n# the repo. Unless a later match takes precedence,\n# @kcloutie and @abaker9 will be requested for\n# review when someone opens a pull request.\n*       @abaker9 @kcloutie @jvandal3\n\n# Order is important; the last matching pattern takes the most\n# precedence. When someone opens a pull request that only\n# modifies JS files, only @js-owner and not the global\n# owner(s) will be requested for a review.\n# *.js    @js-owner\n\n# You can also use email addresses if you prefer. They'll be\n# used to look up users just like we do for commit author\n# emails.\n# *.go docs@example.com\n\n# In this example, @doctocat owns any files in the build/logs\n# directory at the root of the repository and any of its\n# subdirectories.\n# /build/logs/ @doctocat\n\n# The `docs/*` pattern will match files like\n# `docs/getting-started.md` but not further nested files like\n# `docs/build-app/troubleshooting.md`.\n# docs/*  docs@example.com\n\n# In this example, @octocat owns any file in an apps directory\n# anywhere in your repository.\n# apps/ @octocat\n\n# In this example, @doctocat owns any file in the `/docs`\n# directory in the root of your repository.\n# /docs/ @doctocat",
              "encoding": "text",
              "labels": {
                "debugOutput": "github - ",
                "fromTemplate": "github",
                "skipIfExists": "true"
              },
              "length": 1287,
              "path": ".github/CODEOWNERS"
            },
            {
              "algorithm": "sha256",
              "checkSum": "82f511e46aff1b77fddae8e602aa7958aabd35cb33d4be0134d748ec1347b5b0",
              "content": "---\nname: Bug report\nabout: Create a report to help us improve\ntitle: ''\nlabels: ''\nassignees: ''\n\n---\n\n**Describe the bug**\nA clear and concise description of what the bug is.\n\n**To Reproduce**\nSteps to reproduce the behavior:\n1. Go to '...'\n2. Click on '....'\n3. Scroll down to '....'\n4. See error\n\n**Expected behavior**\nA clear and concise description of what you expected to happen.\n\n**Screenshots**\nIf applicable, add screenshots to help explain your problem.\n\n**Desktop (please complete the following information):**\n - OS: [e.g. iOS]\n - Browser [e.g. chrome, safari]\n - Version [e.g. 22]\n\n**Additional context**\nAdd any other context about the problem here.\n",
              "encoding": "text",
              "labels": {
                "debugOutput": "github - ",
                "fromTemplate": "github",
                "skipIfExists": "true"
              },
              "length": 665,
              "path": "bug_report.md"
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