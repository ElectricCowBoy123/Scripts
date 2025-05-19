import requests  # type: ignore
import json
import argparse
import os
import base64

url = 'https://eu.ninjarmm.com/s10/scripting/scripts'
categoriesUrl = 'https://eu.ninjarmm.com/s10/scripting/categories'

def handle_mfa(token, mfacode, cookies, requestbody, uri):
    uri = uri + f"?token={token}&mfacode={mfacode}"
    print(uri)
    response = requests.post(uri, json=requestbody, cookies=cookies)
    print(requestbody)
    return response

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

def main(code_file, session_key_file_path=None, name=None, operating_system=None, language=None, runas=None, description=None, script_params=None):
    params =  None
    
    if session_key_file_path == None:
        session_key_file_path = os.path.abspath('./active_sessionkey.txt')
    
    if name == None:
        code_path = os.path.abspath(code_file)
        base_name = os.path.basename(code_path)
        name, _ = os.path.splitext(base_name)

    if language == None:
        _, extension = os.path.splitext(code_file)

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

    if runas == None:
        runas = "system"

    if description == None:
        description = ""
    
    if script_params != None:
        params = get_script_parameters(script_params)
        
    session_key = get_session_key(session_key_file_path)
    cookies = {
        'sessionKey': session_key
    }

    response = requests.get(url, cookies=cookies)
    if response.status_code in (200, 201):
        mainData = response.json()
        for item in mainData:
            if item['name'] == name:
                print(f"A script with the name {item['name']} already exists with id {item['id']}!")
                exit(0)
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
                    response = handle_mfa(mainData['loginToken'], mfacode, cookies, data, url)
                    if response.status_code in (200, 201):
                        print("Successfully Uploaded after MFA!")
                        break
                else:
                    print("Invalid MFA token. Please try again.")
    else:
        print(f"Failed to obtain current scripts with Status Code: {response.status_code}")
        exit(1)
    
    categoriesResponse = requests.get(categoriesUrl, cookies=cookies)
    categories_data = categoriesResponse.json()
    categories = [int(cat['id']) for cat in categories_data]
    selected_categories = set()
    
    while True:
        for cat in categories_data:
            print(f"{cat['id']} : {cat['name']}")
        usr_input = input("Please select a category, type 'done' if you are finished adding categories: ")
        
        if usr_input.lower() == "done":
            break
        
        if usr_input.isdigit():
            usr_input = int(usr_input)
            if usr_input in categories and usr_input not in selected_categories:
                selected_categories.add(usr_input)
            elif usr_input in selected_categories:
                print("You have already entered this category, duplicates are not allowed")
            else:
                print("Invalid category ID!")
        else:
            print("Please enter a valid category ID!")

    with open(code_file, 'r', encoding='utf-8') as file:
        file_contents = file.read()
    
    base64_string = base64.b64encode(file_contents.encode('utf-8')).decode('utf-8')
    categories_x = list(selected_categories)
    print(categories_x)
    
    if params != None:
        data = {
            "architecture": ["64"],
            "categoriesIds": categories_x,
            "code": base64_string,
            "description": description,
            "language": language,
            "name": name,
            "operatingSystems": [operating_system],
            "scriptParameters": [],
            "useFirstParametersOptionAsDefault": False,
            "scriptVariables": [params],
            "defaultRunAs": runas
        }
    else:
        data = {
            "architecture": ["64"],
            "categoriesIds": categories_x,
            "code": base64_string,
            "description": description,
            "language": language,
            "name": name,
            "operatingSystems": [operating_system],
            "scriptParameters": [None],
            "useFirstParametersOptionAsDefault": False,
            "scriptVariables": None,
            "defaultRunAs": runas
        }
    
    print(data)
    response = requests.post(url, json=data, cookies=cookies)
    if response.status_code in (200, 201):
        response_json = response.json()
        print("Successfully Uploaded!")
        print(f"ID is: {response_json['id']}")
        print(f"Name is: {response_json['name']}")
    elif response.status_code == 406:
        response_json = response.json()
        if response_json.get('resultCode') == "MFA_REQUIRED":
            print("MFA Required, please reinput MFA")
            while True:
                mfacode = input("Please enter your MFA token: ")
                if mfacode.isdigit() and len(mfacode) == 6:
                    response = handle_mfa(response_json['loginToken'], mfacode, cookies, data, url)
                    if response.status_code in (200, 201):
                        print("Successfully Uploaded after MFA!")
                        break
                else:
                    print("Invalid MFA token. Please try again.")
        else:
            print(f"Check your request! Status Code: {response.status_code}")
            exit(1)
    else:
        print(f"POST Request Failed with Status Code: {response.status_code}")
        exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Performs GET Request at /s10/scripting/scripts and at /s10/scripting/categories on 'eu.ninjarmm.com'. Stores Output in File. Requests the sessionKey")
    parser.add_argument("code_file", help="Code file to upload to NinjaRMM", type=str)
    parser.add_argument("--session_key_file_path", help="File path to a .txt file containing the session key cookie value to use for the request", type=str required=False)
    parser.add_argument("--name", help="Desired Name for the Script in NinjaRMM", type=str, required=False)
    parser.add_argument("--operating_system", help="OS the Script will be ran on. Valid values are: Windows, Linux, Mac", type=str, required=False)
    parser.add_argument("--language", help="The language the script is in. Valid values are: powershell, sh, batchfile", type=str, required=False)
    parser.add_argument("--runas", help="Run as value, valid values are: system, loggedonuser", type=str, required=False)
    parser.add_argument("--description", help="Description to include when uploading the script to NinjaRMM", type=str, required=False)
    parser.add_argument("--script_params", help="JSON file containing the params to apply to the script", type=str, required=False)
    args = parser.parse_args()
    main(args.code_file, args.session_key_file_path, args.name, args.operating_system, args.language, args.runas, args.description, args.script_params)