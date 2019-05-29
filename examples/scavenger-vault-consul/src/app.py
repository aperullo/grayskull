from flask import Flask, request
import os
import requests
import json
import logging
import init_vault
app = Flask(__name__)

log = logging.getLogger('werkzeug')

vault_url = "http://vault:8200"

class Shared:
    client_token = None
    answer_file_path = None
    # The decoded message is TOPSECRET, every letter has had 3 added to its value (EX: a -> d)
    encoded_message = "WRSVHFUHW" 

#--------------------------------
# Everything below here is the part of the application that actually will find the key.

@app.route('/get-secret')
def get_secret():

    Shared.client_token = request.args.get("token")

    if Shared.client_token is None:
        return "There was no client token", 500
    
    secret_loc = "secret/scavenger"
    headers = {"X-Vault-Token": Shared.client_token}

    resp = requests.get("/".join([vault_url, "v1", secret_loc]), headers=headers)
    if resp.status_code == 200:
        Shared.answer_file_path = resp.json().get("data", {}).get("file_path", None)
        log.info("Secret was retrieved as: " + Shared.answer_file_path)
        return decode()
    else:
        return resp.text, resp.status_code        
    
@app.route('/decode')
def decode():
    
    if Shared.answer_file_path is None:
        return "There was no answer file path", 500
    elif not os.path.exists(Shared.answer_file_path):
        return "There was no file at answer path", 500

    with open(Shared.answer_file_path, "r") as answer_file:
        # represents how many letters the message has been shifted by
        shift = int(answer_file.read())
        # lambda function to subtract 3 from the encoded answer.
        decode = lambda l: chr(ord(l) - shift)     # ord is ascii value (a -> 97), chr is opposite.          
        # list comprehension to apply to each letter
        decoded = "".join([decode(l) for l in Shared.encoded_message])

        log.info("Message was decoded as: " + decoded)
        return decoded, 200

@app.route('/')
def hello():
    return 'Hello world!'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
