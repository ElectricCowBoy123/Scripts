# Filter Ninja Script list
# Show list search for script by name
# Show results
# Enter an ID to edit
# Edit that script and push

import requests  # type: ignore
import json
import argparse
import os
import base64

scriptsUrl = "https://eu.ninjarmm.com/s10/scripting/scripts"

headers = {
    'Accept': '*/*',
    'Content-Type': 'application/json'  # Ensure the server knows you're sending JSON
}

# make this do post put and get
def handle_mfa(token, mfacode, cookies, uri, requestbody=None):
    if requestbody != None:
        uri = uri + f"?token={token}&mfacode={mfacode}"
        print(uri)
        response = requests.put(uri, json=requestbody, cookies=cookies, headers=headers)
        print("MFA Response:")
        print(response.text)
        print(response.status_code)
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

def get_script_parameters(script_params):
    try:
        with open(script_params, 'r') as file:
            param_data = json.load(file)
        return param_data
    except FileNotFoundError:
        print(f"Error: The file '{param_data}' was not found!")
        return None
    except IOError:
        print(f"Error: An I/O error occurred while reading the file '{param_data}'")
        return None

def main(code_file_path, session_key_file_path=None, script_id=None, name=None, operating_system=None, language=None, runas=None, description=None, script_params=None):
    name = None
    uid = None
    isActive = None
    language = None
    #code = None
    contentId = None
    description = None
    architecture = None
    categoriesIds = None
    scriptParameters = None
    operatingSystems = None
    scriptVariables = None
    defaultRunAs = None
    useFirstParametersOptionAsDefault = None
    _id = None

    with open(code_file_path, 'r', encoding='utf-8') as file:
        code = file.read()

    if session_key_file_path == None:
        session_key_file_path = os.path.abspath('./active_sessionkey.txt')
    
    if name == None:
        None
        # Get existing name of script

    """
    if language == None:
        # Get existing language of script
        # Check if language of file matches that of the script

    if extension is not None:
        print(f"'{extension}'")
    if str(extension) == ".ps1":
        language = "powershell"
    elif str(extension) == ".sh":
        language = "sh"
    else: 
        print(f"Unrecognised extension '{extension}'")
        exit(1)
    
    
    if operating_system == None and language == "powershell":
        operating_system = "Windows"
    
    if operating_system == None and language == "sh":
        operating_system = "Mac"
    """

    if runas == None:
        # Get existing runas
        None

    if description == None:
        # Get existing description
        None
    
    if script_params != None:
        # Get existing params
        None
        
    session_key = get_session_key(session_key_file_path)
    cookies = {
        'sessionKey': session_key
    }
    
    response = requests.get(scriptsUrl, cookies=cookies)
    if response.status_code == 200:
        print("Main Request was Successful!")
        mainData = response.json()
    else:
        print(f"Main Request Failed with Status Code: {response.status_code}")

    dict_items = {}
    confirmed = False
    while not confirmed:
        for item in mainData:
            print(f"{item['id']} : {item['name']}")
            dict_items[str(item['id'])] = str(item['name'])

        input_var = input("Please enter the ID of the script you'd like to edit: ")
        # validate input var TODO
        selection = dict_items.get(str(input_var))
        confirmation = input(f"You've selected '{selection}' would you like to edit this script? (Y/N): ")
        
        if confirmation.upper() == "Y":
            print(f"Editing '{selection}'...")
            confirmed = True
        elif confirmation.upper() == "N":
            print(f"Returning to Selection List...")
        else:
            print("Please enter a valid string Y/N!")

    # Construct new url
    update_url = scriptsUrl + "/" + input_var
    print(update_url)
    response = requests.get(update_url, cookies=cookies)
    if response.status_code in (200, 201):
        mainData = response.json()
    elif response.status_code == 401:
        print(f"Please provide a valid token. Status Code: {response.status_code}")
        exit(1)
    elif response.status_code == 406:
        mainData = response.json()
        if mainData.get('resultCode') == "MFA_REQUIRED":
            print("MFA Required, please reinput MFA")
            while True:
                mfacode = input("Please enter your MFA token: ")
                if mfacode.isdigit() and len(mfacode) == 6:
                    print("first mfa")
                    response = handle_mfa(mainData['loginToken'], mfacode, cookies, url)
                    if response.status_code in (200, 201):
                        print("Successfully retrieved script content after MFA!")
                        break
                else:
                    print("Invalid MFA token. Please try again.")
    elif response.status_code == 400:
        print(f"Status code '{response.status_code}' usually means that MFA is re-required due to a bad request in this session or bad session key!")
        exit(1)
    else:
        print(f"Failed to obtain script with Status Code: {response.status_code}")
        exit(1)

    # Backup script before updating
    print(f"Taking backup of script with ID: '{selection}'...")
    for item in mainData:
        encoded_content = str(mainData.get('code', ""))
        decoded_bytes = base64.b64decode(encoded_content)
        backup_content = decoded_bytes.decode('utf-8')
    
    base_name = os.path.basename(code_file_path)
    _, extension = os.path.splitext(code_file_path)
    name, _ = os.path.splitext(base_name)
    script_name = name + extension
    backup_path = os.path.abspath('./Backups') + "/" + script_name
    print(backup_path)
    with open(backup_path, 'w') as file:
        file.write(code)

    # Access values directly using keys
    name = str(mainData.get('name', ""))  # Default to empty string if not found
    language = str(mainData.get('language', ""))  # Default to empty string if not found
    if code == None:
        code = str(mainData.get('code', ""))  # Default to empty string if not found
    contentId = str(mainData.get('contentId', ""))  # Default to empty string if not found
    description = str(mainData.get('description', ""))  # Default to empty string if not found
    architecture = mainData.get('architecture', [])  # Default to empty string if not found
    categoriesIds = mainData.get('categoriesIds', [])  # Default to empty list if not found
    scriptParameters = mainData.get('scriptParameters', {})  # Default to empty dict if not found
    operatingSystems = mainData.get('operatingSystems', [])  # Default to empty list if not found
    scriptVariables = mainData.get('scriptVariables', None)  # Default to empty dict if not found
    defaultRunAs = str(mainData.get('defaultRunAs', ""))  # Default to empty string if not found
    useFirstParametersOptionAsDefault = mainData.get('useFirstParametersOptionAsDefault', False)  # Default to False if not found
    _id = int(mainData.get('id', 0))  # Default to 0 if not found

    

    base64_string = base64.b64encode(code.encode('utf-8')).decode('utf-8')
    print(base64_string)

    # craft request body:
    request_body = {
        "architecture": architecture,
        "categoriesIds": categoriesIds,
        "code": base64_string,
        "description": description,
        "language": language,
        "name": name,
        "operatingSystems": operatingSystems,
        "scriptParameters": scriptParameters,
        "useFirstParametersOptionAsDefault": False,
        "scriptVariables": scriptVariables,
        "defaultRunAs": defaultRunAs,
        "id": _id,
    }

    json_data = json.dumps(request_body)

    print(json_data)

    response = requests.put(scriptsUrl, json=json_data, cookies=cookies)
    if response.status_code in (200, 201):
        mainData = response.json()
    elif response.status_code == 401:
        print(f"Please provide a valid token. Status Code: {response.status_code}")
        exit(1)
    elif response.status_code == 406:
        mainData = response.json()
        print(mainData['loginToken'])
        if mainData.get('resultCode') == "MFA_REQUIRED":
            print("MFA Required, please reinput MFA")
            while True:
                mfacode = input("Please enter your MFA token: ")
                if mfacode.isdigit() and len(mfacode) == 6:
                    print("second mfa")
                    response = handle_mfa(mainData['loginToken'], mfacode, cookies, scriptsUrl, request_body)
                    if response.status_code in (200, 201):
                        print("Successful PUT request after MFA!")
                        break
                    else:
                        print(f"Invalid MFA re-request! Error: '{response.status_code}'")
                        exit(1)
                else:
                    print("Invalid MFA token. Please try again.")
    elif response.status_code == 400:
        print(f"Status code '{response.status_code}' usually means that MFA is re-required due to a bad request in this session or bad session key!")
        exit(1)
    else:
        print(f"Failed to PUT script with Status Code: {response.status_code}")
        exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Performs GET Request at /s10/scripting/scripts and at /s10/scripting/categories on 'eu.ninjarmm.com'. Stores Output in File. Requests the sessionKey")
    parser.add_argument("code_file_path", help="Code file to upload to NinjaRMM", type=str)
    parser.add_argument("--session_key_file_path", help="File path to a .txt file containing the session key cookie value to use for the request", type=str, required=False)
    parser.add_argument("--script_id", help="ID of the script to update, if you don't know it you can leave this blank", type=str, required=False)
    parser.add_argument("--name", help="Desired Name for the Script in NinjaRMM", type=str, required=False)
    parser.add_argument("--operating_system", help="OS the Script will be ran on. Valid values are: Windows, Linux, Mac", type=str, required=False)
    parser.add_argument("--language", help="The language the script is in. Valid values are: powershell, sh, batchfile", type=str, required=False)
    parser.add_argument("--runas", help="Run as value, valid values are: system, loggedonuser", type=str, required=False)
    parser.add_argument("--description", help="Description to include when uploading the script to NinjaRMM", type=str, required=False)
    parser.add_argument("--script_params", help="JSON file containing the params to apply to the script", type=str, required=False)
    args = parser.parse_args()
    main(args.code_file_path, args.session_key_file_path, args.name, args.operating_system, args.language, args.runas, args.description, args.script_params)