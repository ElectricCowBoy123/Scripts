""" 
- Adds scripts into an 'In Policy' category if they are used in a policy 
- Determines what ID belongs to the 'In Policy' category before sending the request
- Ensures the code is present before sending the request 
"""

import requests # type: ignore
import json
import argparse
import os

headers = {
    'Accept': '*/*',
    'Content-Type': 'application/json'
}

def handle_mfa(token, mfacode, cookies, uri, requestbody=None):
    if requestbody != None:
        uri = uri + f"?token={token}&mfacode={mfacode}"
        print(uri)
        response = requests.put(uri, data=requestbody, cookies=cookies, headers=headers)
        return response
    else:
        print("Failed on first request!")
        exit(1)

def get_session_key(session_key_file_path):
    try:
        with open(session_key_file_path, 'r') as file:
            session_key = file.read().strip()
        return session_key
    except FileNotFoundError:
        print(f"Error: The file '{session_key_file_path}' was not found!")
        return None
    except IOError:
        print(f"Error: An I/O error occurred while reading the file '{session_key_file_path}'")
        return None

def add_category(script, category):
        cookies = {
            'sessionKey': get_session_key(os.path.abspath('./Deployment/active_sessionkey.txt'))
        }
        
        # Get information on the script before generating the request body
        response = requests.get(f"https://eu.ninjarmm.com/swb/s10/scripting/scripts/{script["id"]}", cookies=cookies)
        if response.status_code == 200:
            mainData = response.json()
        else:
            print(f"Request Failed with Status Code: {response.status_code}"
        )
        
        # Build the category ID list properly
        categories_ids = mainData.get("categoriesIds", None)
        if categories_ids is not None:
            categories_ids.append(category)
            categories_ids = sorted(list(set(categories_ids)), reverse=False)
            mainData["categoriesIds"] = categories_ids

        # Ensure the code is present before sending the request
        code = mainData.get("code", "")
        if code is None:
            print("Unhandled Error Code is None!")
            return
        
        # Build the request body
        body = {
            "architecture": mainData.get("architecture", None),
            "categoriesIds": mainData.get("categoriesIds", None),
            "code": code,
            "description": mainData.get("description", ""),
            "language": mainData.get("language", None),
            "name": mainData.get("name", None),
            "operatingSystems": mainData.get("operatingSystems", []),
            "scriptParameters": mainData.get("scriptParameters", []),
            "useFirstParametersOptionAsDefault": mainData.get("useFirstParametersOptionAsDefault", False),
            "scriptVariables": mainData.get("scriptVariables", None),
            "defaultRunAs": mainData.get("defaultRunAs", None),
            "id": mainData.get("id", None)
        }

        # Remove unneccessary whitespace from the body
        body = json.dumps(body, separators=(',', ':'))
        
        # Send the request and handle MFA if required to add the category
        response = requests.put("https://eu.ninjarmm.com/swb/s10/scripting/scripts", data=body, cookies=cookies, headers=headers)  # Use json=data to send JSON data
        if response.status_code == 200:
            mainData = response.json()
            print("Added Category")
        elif response.status_code == 406:
            mainData = response.json()
            if mainData.get('resultCode') == "MFA_REQUIRED":
                print("MFA Required, please reinput MFA")
                while True:
                    mfacode = input("Please Enter your MFA token (Might have to wait for code to expire before re-entering):")
                    if mfacode.isdigit() and len(mfacode) == 6:
                        response = handle_mfa(mainData['loginToken'], mfacode, cookies, "https://eu.ninjarmm.com/swb/s10/scripting/scripts", body)
                        if response.status_code in (200, 201):
                            print("Added Category")
                            return
                    else:
                        print("Invalid MFA token. Please try again.")
        else:
            print(f"Request Failed with Status Code: {response.status_code}")

def main(session_key=None, script_input_json=None):
    if session_key is None:
        session_key_file_path = os.path.abspath('./Deployment/active_sessionkey.txt')
        session_key = get_session_key(session_key_file_path)
    
    # Load the script JSON data
    if script_input_json is None:
        script_input_json_path = os.path.abspath("./JSON/Ninja.json")
        with open(script_input_json_path, 'r') as file:
            script_input_json = json.load(file)  # Load the JSON data into a Python object

    # Load the policy JSON data
    policy_file_path = os.path.abspath("./JSON/Policy_Script_Report.json")
    with open(policy_file_path, 'r') as file:
        policy_content = file.read()

    # Load the categories JSON data
    category_file_path = os.path.abspath("./JSON/Categories.json")
    with open(category_file_path, 'r') as file:
        category_content = json.load(file)

    # Get the category ID for the "In Policy" category
    for category in category_content:
        if category["name"] == "In Policy":
            categoryId = category["id"]
            break
    
    # Iterate through the scripts and add them to the "In Policy" category if they are used in a policy
    for script in script_input_json:
        if script["language"] != "native":
            if(script["name"] in policy_content):
                    print(f"Name: '{script["name"]}' ID({script["id"]}) - Attempting to Add In Policy Category")
                    add_category(script, categoryId)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Iterates through all scripts, if a script is used in a policy it is added to the 'In Policy' category")
    parser.add_argument("--session_key", help="Session key cookie value to use for the request", type=str, required=False)
    parser.add_argument("--script_input_json", help="Full path to the input JSON file for the scripts", type=str, required=False)
    args = parser.parse_args()
    main(args.session_key, args.script_input_json)
