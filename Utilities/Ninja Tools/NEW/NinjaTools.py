import requests # type: ignore
import json
import os

def handle_mfa(token, mfacode, cookies, uri, requestbody=None):
    if requestbody != None:
        uri = uri + f"?token={token}&mfacode={mfacode}"
        print(uri)
        response = requests.put(uri, data=requestbody, cookies=cookies, headers=headers)
        return response
    else:
        print("Failed on first request!")
        exit(1)

def filter_items(categoryData, mainData):
    categoryDict = {category['id']: category['name'] for category in categoryData}
    for item in mainData:
        new_categories = []
        if 'scriptVariables' in item:
            script_variable_names = [var['name'] for var in item['scriptVariables']]
            if item['name'] not in script_variable_names:
                for catId in item['categoriesIds']:
                    if catId in categoryDict:
                        new_categories.append(categoryDict[catId])
        elif 'scriptVariables' not in item:
            for catId in item['categoriesIds']:
                    if catId in categoryDict:
                        new_categories.append(categoryDict[catId])
        item['categoriesIds'] = new_categories
    return mainData

def handle_ninja_mfa(url, request_body, cookies, headers, token, mfacode):
    if url is None or request_body is None or token is None or mfacode is None or cookies is None or headers is None:  
        raise ValueError("Please Provide The Correct Number of Parameters") 

    if request_body != None:
        url = url + f"?token={token}&mfacode={mfacode}"
        print(url)
        response = requests.post(url, json=request_body, cookies=cookies, headers=headers)
        print("MFA Response:")
        print(response.text)
        print(response.status_code)
        return response
    else:
        print("Failed on first request!")
        exit(1)

def get_ninja_session_key(session_key_file_path):
    if session_key_file_path is None:
        raise ValueError("Session Key File Path Parameter Must be Provided for Get Session Key.")

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
    
def get_all_ninja_devices(session_key_file_path):
    if session_key_file_path is None:
        session_key_file_path = os.path.abspath('./active_sessionkey.txt')

    session_key = get_ninja_session_key()

    cookies = {
        'sessionKey': session_key
    }

    request_body = {
        "searchCriteria": [
            {
                "type": "all-devices",
                "customFields": "{}"
            }
        ],
        "columns": []
    }

    advance_page = True
    
    ninja_device_set = set()
    runCount = 0
    
    page_size = '150'
    index = '150'
    device_count = 602 # hardcoded value need to sort this TODO

    while advance_page:
        runCount = runCount + 1
        if runCount > 1:
            index = str(int(index) + 150)
            nextURLSub = f'&index={index}'
            baseURL = f"https://eu.ninjarmm.com/s10/search/runner?pageSize={page_size}{nextURLSub}&sortProperty=name&sortDirection=asc"
        else:
            baseURL = f"https://eu.ninjarmm.com/s10/search/runner?pageSize={page_size}&sortProperty=name&sortDirection=asc"

        if int(index) + int(page_size) >= device_count:
            advance_page = False
            return ninja_device_set

        response = requests.post(baseURL, json=request_body, cookies=cookies, headers=headers)
        if response.status_code in (200, 201):
            mainData = response.json()
            
        elif response.status_code == 401:
            print(f"\nPlease provide a valid NinjaRMM token. Status Code: {response.status_code}")
            exit(1)
        elif response.status_code == 406:
            mainData = response.json()
            if mainData.get('resultCode') == "MFA_REQUIRED":
                print("MFA Required, please reinput MFA")
                while True:
                    mfacode = input("Please enter your MFA token: ")
                    if mfacode.isdigit() and len(mfacode) == 6:
                        response = handle_ninja_mfa()
                        if response.status_code in (200, 201):
                            mainData = response.json()
                            print("Successfully Performed Request after MFA!")
                            break
                    else:
                        print("Invalid MFA token. Please try again.")
        else:
            print(f"Failed to obtain current devices with Status Code: {response.status_code}")
            exit(1)


        if 'items' in mainData:
            for item in mainData['items']:
                ninja_device = item['name'].strip()
                ninja_device_set.add(ninja_device)

def check_in_ninja(device_set):
    if device_set is None:
        raise ValueError("Please supply a value for device_set!")
    
    ninja_device_set = get_all_ninja_devices()

    result_set = ninja_device_set & device_set # Devices in Ninja and ScreenConnect

    return result_set

def get_session_key(session_key_file_path):
    if session_key_file_path is None:
        raise ValueError("Please Provide The Correct Number of Parameters") 
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
    
# filter the all policies json
def helper_filter_policies(policies_json_file_path):
    with open(policies_json_file_path, 'r') as outfile:
        polcies_json = json.load(outfile)
    policies = {}
    for policy in polcies_json:
        policies[policy['id']] = policy['name'] 
    return policies

def helper_filter_policy(policy_json_file_path):
    try:
        with open(policy_json_file_path, 'r') as file:
            policies_json = json.load(file)
    except FileNotFoundError:
        print(f"Error: The file '{policy_json_file_path}' was not found!")
        return None
    actionset_schedules = policies_json['policy']['content']['actionsetSchedules']

    # TODO Need to do this for different schedules not just actionsetSchedules
    scriptsInUse = {}
    #scriptsInUse = []

    for schedule_key, schedule in actionset_schedules.items():
        for key, value in schedule.items():
            #if(key == 'actionsetScheduleName'):
                #print(f"{key}: {value}")
            if(key == 'scripts'):
                for script in value:
                    script_id = script.get('scriptId')
                    script_name = script.get('scriptName')
                    scriptsInUse[script_id] = script_name
                    #scriptsInUse.append(f"{script_id}: {script_name}")
                    #print(f"Script ID: {script_id}, Script Name: {script_name}")
                # loop here scripts is an array inside it i want to the scriptid and scriptname
                #print(f"  {key}: {value}")
    return scriptsInUse

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
            'sessionKey': get_session_key(os.path.abspath('./active_sessionkey.txt'))
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

def generate_policies_json():
    output_policies_file = os.path.abspath("./JSON/Policies.json")
    policiesResponse = requests.get('https://eu.ninjarmm.com/swb/s10/policy/list?nodeClassGroup=RMM', cookies=cookies)
    if policiesResponse.status_code == 200:
        print("Policies Request was Successful!")
        policiesData = policiesResponse.json()
        with open(output_policies_file, 'w') as policies_outfile:
            json.dump(policiesData, policies_outfile, indent=4)
    else:
        print(f"Policies Request Failed with Status Code: {policiesResponse.status_code}")

    totalScriptsinUse = {}
    policies = helper_filter_policies(os.path.abspath(f"./JSON/Policies.json"))
    for policyId, policyName in policies.items():
        policyUrl = f'https://eu.ninjarmm.com/swb/s10/policy/{policyId}'
        output_file = os.path.abspath(f"./JSON/Policies/{policyId}.json")

        response = requests.get(policyUrl, cookies=cookies)
        if response.status_code == 200:
            mainData = response.json()
            with open(output_file, 'w') as outfile:
                json.dump(mainData, outfile, indent=4)
        else:
            print(f"Main Request Failed with Status Code: {response.status_code}")
            continue  # Skip to the next policy if the request fails

        scriptsInUse = helper_filter_policy(output_file)

        print(f"Grabbing Policy: '{policyName}'")

        # Initialize the dictionary for the current policy if it doesn't exist
        if policyName not in totalScriptsinUse:
            totalScriptsinUse[policyName] = {}

        # Loop through the scripts in use and populate the totalScriptsinUse dictionary
        for scriptId, scriptName in scriptsInUse.items():
            totalScriptsinUse[policyName][str(scriptId)] = scriptName  # Use scriptId as a string

    output_path = os.path.abspath('./JSON/Policy_Script_Report.json')
    with open(output_path, 'w') as json_file:
        json.dump(totalScriptsinUse, json_file, indent=4)

def generate_categories_json():
    output_categories_file = os.path.abspath("./JSON/Categories.json")

    categoriesResponse = requests.get('https://eu.ninjarmm.com/swb/s10/scripting/categories', cookies=cookies)
    if categoriesResponse.status_code == 200:
        print("Categories Request was Successful!")
        categoriesData = categoriesResponse.json()
        with open(output_categories_file, 'w') as categories_outfile:
            json.dump(categoriesData, categories_outfile, indent=4)
    else:
        print(f"Categories Request Failed with Status Code: {categoriesResponse.status_code}")

def generate_main_json():
    output_file = os.path.abspath("./JSON/Ninja.json")

    response = requests.get('https://eu.ninjarmm.com/swb/s10/scripting/scripts', cookies=cookies)
    if response.status_code == 200:
        print("Main Request was Successful!")
        mainData = response.json()
    else:
        print(f"Main Request Failed with Status Code: {response.status_code}")

    categories_file_path = os.path.abspath("./JSON/Categories.json")
    with open(categories_file_path, 'r') as file:
        categoriesData = json.load(file)
    
    if response.status_code == 200:
        mainData = filter_items(categoriesData, mainData)
        with open(output_file, 'w') as outfile:
            json.dump(mainData, outfile, indent=4)

session_key_file_path = os.path.abspath('./active_sessionkey.txt')
session_key = get_session_key(session_key_file_path)
cookies = {
    'sessionKey': session_key
}

headers = {
    'Accept': '*/*',
    'Content-Type': 'application/json'
}