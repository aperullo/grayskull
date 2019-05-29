import os
import requests
import json
import logging

log = logging.getLogger('werkzeug')

vault_url = "http://vault_vault_stk:8200"
role_name = "scavenger-read-role"

keys_path = "keys.txt"

class Shared:
    key = ""
    root_token = ""
    role_id = ""
    secret_id = ""

# This script is doing the initial vault set up for us, in place of an admin. This script also acts as a stand in for the intermediate service that the app would ask for credentials to retrieve a secret.

def unlock():
    # Check vault is not initialized
    if requests.get(vault_url + "/v1/sys/init").json()["initialized"] == False:
        log.info("Initializing Vault")

        # only 1 key to unlock
        data = {
            "secret_shares": 1,
            "secret_threshold": 1
        }

        # Tell Vault to initialize.
        init_resp = requests.post(vault_url + "/v1/sys/init", data=json.dumps(data), timeout=5)
        if not init_resp.status_code == 200:
            return init_resp, init_resp.status_code

        # We should have the keys nows, you shouldn't ever save these to a plaintext file.
        # We are doing this for for debugging purposes. In case this function gets called after vault is initialized.
        tries = 0
        exists = False

        # We really would like to ensure this file exists
        while not exists and tries < 5:

            with open(keys_path, "w") as key_file:
                key_file.write(init_resp.text)

            tries += 1
            exists = os.path.exists(keys_path)

        # This bug happens and there is no clear cause as to why.it may be related to permissions.
        # Will cause a fileNotFound error if unlock is called again.
        if not exists:
            raise FileNotFoundError("Couldn't make the keys.txt file. Please delete vault_files/data on the vault server, restart the vault server, and try again.")

        log.info("Created keys.txt")
        log.info("Keys are: " + init_resp.text)

        Shared.key = init_resp.json()["keys"][0]
        Shared.root_token = init_resp.json()["root_token"]

    # If vault was initialized already
    else:
        if not os.path.exists(keys_path):
            raise FileNotFoundError("Couldn't find keys.txt file, but vault is initialized. This means we are locked out. Please restart the vault server, and try again.")

        # read the keys out of the file
        with open(keys_path, "r") as key_file:
            contents = json.loads(key_file.read())
            Shared.key = contents.get("keys", "no key")
            Shared.root_token = contents.get("root_token", "no root token")

    #unseal the vault
    data = {"key": Shared.key}
    sealed = True
    tries = 0


    # This can occasionally take a few tries.
    while(sealed and tries < 5):
        requests.post(vault_url + "/v1/sys/unseal", data=json.dumps(data), timeout=5)

        sealed = requests.get(vault_url + "/v1/sys/seal-status").json().get("sealed", True)
        tries += 1

    return str(Shared.key) + " " + Shared.root_token


def secret():
        
    # make the secret
    headers = {"X-Vault-Token": Shared.root_token}
    data = {"file_path": "scavenger/answer/answer.txt"}
    resp = requests.post(vault_url + "/v1/secret/scavenger", headers=headers, data=json.dumps(data), timeout=5)
    if resp.status_code > 400: 
        return resp.text, resp.status_code
    
    # was the secret created? Read it back
    resp = requests.get(vault_url + "/v1/secret/scavenger", headers=headers)
    log.info("secret is set to: " + resp.text)
    return resp.text, resp.status_code


def policy():
    headers = {"X-Vault-Token": Shared.root_token}
    policy_name = "scavenger-read"

    # The data has to be passed as a JSON containing HCL.
    data = {"policy": "path \"secret/scavenger\" { capabilities = [\"read\"] }"}
    resp = requests.post(vault_url + "/v1/sys/policy/" + policy_name, headers=headers, data=json.dumps(data))
    if resp.status_code > 400:
        return resp.text, resp.status_code

    resp = requests.get(vault_url + "/v1/sys/policy/", headers=headers)
    log.info("policy is set to: " + resp.text)
    return resp.text, resp.status_code

def role():
    # set up app role
    headers = {"X-Vault-Token": Shared.root_token}
    approle = {"type": "approle"}
    resp = requests.post(vault_url + "/v1/sys/auth/approle", headers=headers, data=json.dumps(approle))
    if resp.status_code > 400:
        return resp.text, resp.status_code
    
    #create a role
    data = {"policies":"scavenger-read"}
    resp = requests.post(vault_url + "/v1/auth/approle/role/" + role_name, headers=headers, data=json.dumps(data))
    if resp.status_code > 400:
        return resp.text, resp.status_code

    #get the role-id
    addr = "/".join([vault_url, "v1/auth/approle/role", role_name, "role-id"])
    resp = requests.get(addr, headers=headers)
    if resp.status_code > 400:
        return resp.text, resp.status_code
    
    resp = resp.json()
    role_dict = resp.get("data", {})
    Shared.role_id = role_dict.get("role_id", "no role id")
    log.info("role_id is: " + Shared.role_id)

    return Shared.role_id, 200

def secret_id():
    # set up app role
    headers = {"X-Vault-Token": Shared.root_token}

    #get the secret-id
    addr = "/".join([vault_url, "v1/auth/approle/role", role_name, "secret-id"])
    resp = requests.post(addr, headers=headers)
    if resp.status_code > 400:
        return resp.text, resp.status_code

    log.info(resp.text)
    resp = resp.json()
    role_dict = resp.get("data", {})
    Shared.secret_id = role_dict.get("secret_id", "no secret id")
    log.info("secret_id is: " + Shared.secret_id)

    return Shared.secret_id, 200


def ask_for_creds():
    log.info("App asked for credentials")

    credentials = {
        "role_id": Shared.role_id,
        "secret_id": Shared.secret_id
    }

    log.info("Giving creds as: " + json.dumps(credentials))
    return credentials

# Initializes the vault    
def init():
    try:
        unlock()
        secret()
        policy()
        role()
        secret_id()
        return "role_id: " + Shared.role_id + " secret_id: " + Shared.secret_id
    except:
        raise

