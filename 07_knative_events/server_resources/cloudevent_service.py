import requests
import logging

from flask import Flask, request, jsonify
from cloudevents.http import CloudEvent, from_http, to_structured

app = Flask(__name__)
logging.basicConfig(level=logging.DEBUG)

# CloudEvent Listener (Receives events)
@app.route("/", methods=["POST"])
def receive_cloudevent():
    event = from_http(request.headers, request.get_data())

    app.logger.info(f"Received CloudEvent:")
    app.logger.info(f"  Type: {event['type']}")
    app.logger.info(f"  Source: {event['source']}")
    app.logger.info(f"  Data: {event.data}")

    return jsonify({"message": "CloudEvent received"}), 200

@app.route("/trigger", methods=["POST"])
def send_cloudevent():
    source = request.args.get("source", "default.source")
    event_type = request.args.get("type", "default.type")
    broker_url = request.args.get("broker_url")

    attributes = {
        "source": source,
        "type": event_type,
    }
    data = {"message": "Hello, CloudEvents!"}

    event = CloudEvent(attributes, data)
    headers, body = to_structured(event)

    response = requests.post(broker_url, headers=headers, data=body)

    return jsonify({
        "message": "Event sent!",
        "source": source,
        "type": event_type,
        "response_status": response.status_code
    }), response.status_code

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
