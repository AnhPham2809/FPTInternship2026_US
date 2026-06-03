import json
import time   # wait time between reconnection
import requests # HTTP connect request to Wikimedia
import urllib3 # SSL warning suppression

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning) # Suppress SSL warnings

STREAM_URL = "https://stream.wikimedia.org/v2/stream/recentchange"

def connect_to_stream():
    headers = {
        "Accept": "text/event-stream",
        "User-Agent": "FPTInternship2026/1.0 (anhphamofficial2809@gmail.com) requests/2.34.2" # Identify yourself to Wikimedia
    }
    response = requests.get(STREAM_URL, headers=headers, stream=True, verify=False) # Opens HTTP to Wikimedia URL, used by STREAM_URL above.
    print(f"Status code: {response.status_code}") # Response Debug, ignore.
    return response 

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
                            print(json.dumps(data, indent=2)) # format data
                            print("---") # seperate line for clarity
                        except json.JSONDecodeError: # try block errors
                            continue
        except Exception as e:
            print(f"Connection error: {e}") # Error msg
            print("Reconnecting in 3 seconds.")
            time.sleep(3) # 3s cooldown

if __name__ == "__main__": # Prevent import -> main running
    main()