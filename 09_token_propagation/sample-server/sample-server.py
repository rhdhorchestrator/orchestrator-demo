import logging
from flask import Flask, request, Response
import http.client as http_client
import datetime

http_client.HTTPConnection.debuglevel = 1

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True

@app.route('/health', methods=['GET'])
def health_check():
    return Response("Healthy", status=200)

def printHeader(request, endpointName):
  print(f"================ Headers for {endpointName} ================")
  print(datetime.datetime.now())
  for key, value in request.headers.items():
    print(f"{key}: {value}")
  print("================ END ================")

@app.route('/<path:subpath>', methods=['GET'])
def get(subpath):
  printHeader(request, subpath)
  # Return the response from the target server
  return Response("", status=200, content_type="text/plain")


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)
