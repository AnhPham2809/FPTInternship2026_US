import json
import time   # wait time between reconnection
import requests # HTTP connect request to Wikimedia
import urllib3 # SSL warning suppression
from google.cloud import pubsub_v1

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning) # Suppress SSL warnings

STREAM_URL = "https://stream.wikimedia.org/v2/stream/recentchange"
PROJECT_ID = "fpt-internship-2026"
TOPIC_ID = "live-wikimedia-stream"

publisher = pubsub_v1.PublisherClient() # Create publisher object and links ADC Credentials
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID) # Builds GCP Topic path: projects/fpt-internship-2026/topics/live-wikimedia-stream

def connect_to_stream():
    headers = {
        "Accept": "text/event-stream",
        "User-Agent": "FPTInternship2026/1.0 (anhphamofficial2809@gmail.com) requests/2.34.2" # Identify yourself to Wikimedia
    }
    response = requests.get(STREAM_URL, headers=headers, stream=True, verify=False) # Opens HTTP to Wikimedia URL, used by STREAM_URL above.
    print(f"Status code: {response.status_code}") # Response Debug, ignore.
    return response 

def publish_callback(future, data):
    if future.exception(): # Check if publish failed
        print(f"Failed to publish message: {future.exception()}") # Log the error
    # If no exception, message was published 

def main():
    print("I'm currently connecting to Wikimedia stream!") # debug purpose ignore
    while True:
        try:
            response = connect_to_stream() # Calls connect_to_stream to open the SSE Connection.
            print("I'm connected! Looking for events! \n")
            for line in response.iter_lines(): # Read stream line by line
                if line: # Skip empty lines/heartbeats
                    decoded = line.decode("utf-8") # byte -> string conversion
                    if decoded.startswith("data:"): 
                        raw = decoded[5:].strip() 
                        try:
                            data = json.loads(raw) # Parse string into Python dictionary
                            message_bytes = json.dumps(data).encode("utf-8") # Serialize dict to JSON bytes, Pub/Sub only accepts bytes
                            future = publisher.publish(topic_path, message_bytes) # Publish message to GCP Pub/Sub topic asynchronously
                            future.add_done_callback(lambda f: publish_callback(f, data)) # Callback Confirmation
                            print(f"Sent to Pub/Sub: {data.get('title', 'unknown')}") # Print article title 
                        except json.JSONDecodeError: 
                            continue
                        except Exception as e: 
                            print(f"Failed to publish message: {e}") # Log the error
                            continue # Skip failed message 
        except Exception as e:
            print(f"Connection error: {e}") # Error msg
            print("Reconnecting in 3 seconds.")
            time.sleep(3) # 3s cooldown

if __name__ == "__main__": # Prevent import -> main running
    main()