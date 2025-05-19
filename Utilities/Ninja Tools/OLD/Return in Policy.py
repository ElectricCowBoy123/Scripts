import requests # type: ignore
import json
import argparse
import os

# filter the all policies json
def filter_policies(policies_json_file_path):
    with open(policies_json_file_path, 'r') as outfile:
        polcies_json = json.load(outfile)
    policies = {}
    for policy in polcies_json:
        policies[policy['id']] = policy['name'] 
    return policies

def filter_policy(policy_json_file_path):
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

def main(session_key=None, output_file=None):

    if session_key == None:
        session_key_file_path = os.path.abspath('./Deployment/active_sessionkey.txt')
        session_key = get_session_key(session_key_file_path)

    if output_file == None:
        output_file = None
    
    cookies = {
        'sessionKey': session_key
    }

    totalScriptsinUse = {}
    policies = filter_policies(os.path.abspath(f"./JSON/Policies.json"))
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

        scriptsInUse = filter_policy(output_file)

        print(f"Checking Policy: '{policyName}'")

        # Initialize the dictionary for the current policy if it doesn't exist
        if policyName not in totalScriptsinUse:
            totalScriptsinUse[policyName] = {}

        # Loop through the scripts in use and populate the totalScriptsinUse dictionary
        for scriptId, scriptName in scriptsInUse.items():
            totalScriptsinUse[policyName][str(scriptId)] = scriptName  # Use scriptId as a string
    

    # print object representing scripts in use
    output_path = os.path.abspath('./JSON/Policy_Script_Report.json')
    with open(output_path, 'w') as json_file:
        json.dump(totalScriptsinUse, json_file, indent=4)
    #print(f"Scripts In Use for {policyId}: {scriptsInUse}\n")
    #print(f"Policies: {policies}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Performs GET Request at /swb/s10/policy/ on 'eu.ninjarmm.com'. Stores Output in File. Requests the sessionKey")
    parser.add_argument("--session_key", help="Session key cookie value to use for the request", type=str, required=False)
    parser.add_argument("--output_file", help="Full path to the output JSON file for the main request", type=str, required=False)
    args = parser.parse_args()
    main(args.session_key, args.output_file)
